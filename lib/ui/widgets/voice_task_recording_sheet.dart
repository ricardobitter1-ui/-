import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../business_logic/voice_task_group_resolver.dart';
import '../../debug/voice_perf_logger.dart';
import '../../data/models/group_model.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/providers/group_tags_cache_provider.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/voice_api_config.dart';
import '../../data/services/voice_task_pipeline.dart';
import '../theme/app_theme.dart';

Future<void> showVoiceTaskRecordingSheet({
  required BuildContext context,
  required List<GroupModel> groups,
  String? forcedGroupId,
  GroupModel? contextGroup,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _VoiceTaskRecordingBody(
      groups: groups,
      forcedGroupId: forcedGroupId,
      contextGroup: contextGroup,
    ),
  );
}

class _VoiceTaskRecordingBody extends ConsumerStatefulWidget {
  const _VoiceTaskRecordingBody({
    required this.groups,
    required this.forcedGroupId,
    required this.contextGroup,
  });

  final List<GroupModel> groups;
  final String? forcedGroupId;
  final GroupModel? contextGroup;

  @override
  ConsumerState<_VoiceTaskRecordingBody> createState() =>
      _VoiceTaskRecordingBodyState();
}

class _VoiceTaskRecordingBodyState extends ConsumerState<_VoiceTaskRecordingBody> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _processing = false;
  String? _error;
  String? _tempPath;

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Microfone'),
          content: const Text(
            'Para ditar tarefas, permita o acesso ao microfone nas definições do telemóvel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(ctx);
              },
              child: const Text('Abrir definições'),
            ),
          ],
        ),
      );
    }
    return false;
  }

  Future<void> _startRecording() async {
    setState(() {
      _error = null;
    });
    if (!VoiceApiConfig.isConfigured) {
      final hint = VoiceApiConfig.configurationHint();
      setState(() {
        _error =
            '${hint.isNotEmpty ? hint : 'APIs não configuradas.'}\nCopie secrets.json.example para secrets.json e execute:\nflutter run --dart-define-from-file=secrets.json';
      });
      return;
    }
    final ok = await _ensureMicPermission();
    if (!ok || !mounted) return;

    final can = await _recorder.hasPermission();
    if (can != true) {
      setState(() {
        _error = 'Sem permissão para gravar áudio.';
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_task_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _tempPath = path;
    try {
      await _recorder.start(const RecordConfig(), path: path);
      setState(() => _recording = true);
    } catch (e) {
      setState(() {
        _error = 'Não foi possível iniciar a gravação: $e';
      });
    }
  }

  Future<void> _stopAndDiscard() async {
    if (_recording) {
      await _recorder.cancel();
      _recording = false;
      _tempPath = null;
      if (mounted) setState(() {});
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmRecording() async {
    if (!_recording) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      setState(() {
        _processing = false;
        _recording = false;
        _error = 'Erro ao parar gravação: $e';
      });
      return;
    }
    _recording = false;
    final filePath = path ?? _tempPath;
    if (filePath == null || !File(filePath).existsSync()) {
      setState(() {
        _processing = false;
        _error = 'Ficheiro de áudio não encontrado.';
      });
      return;
    }

    final file = File(filePath);
    final pipeline = VoiceTaskPipeline();
    // #region agent log
    VoicePerfLogger.beginRun();
    final totalSw = Stopwatch()..start();
    final phasesMs = <String, int>{};
    // #endregion
    try {
      String? ctxName = widget.contextGroup?.name;
      if (ctxName == null || ctxName.isEmpty) {
        final fid = widget.forcedGroupId?.trim();
        if (fid != null && fid.isNotEmpty) {
          for (final g in widget.groups) {
            if (g.id == fid) {
              ctxName = g.name;
              break;
            }
          }
        }
      }
      final fs = ref.read(firebaseServiceProvider);
      final ns = ref.read(notificationServiceProvider);

      final tagsCache = ref.read(groupTagsCacheProvider.notifier);
      final tagsByGroupId = <String, List<TagModel>>{};
      final tagsByGroupName = <String, List<String>>{};
      final forcedGid = widget.forcedGroupId?.trim();
      final hasForcedGroup =
          forcedGid != null && forcedGid.isNotEmpty;
      // #region agent log
      var sw = Stopwatch()..start();
      // #endregion
      if (hasForcedGroup) {
        final tags = await tagsCache.fetchTags(forcedGid);
        tagsByGroupId[forcedGid] = tags;
        String? gName;
        for (final g in widget.groups) {
          if (g.id == forcedGid) {
            gName = g.name;
            break;
          }
        }
        if (gName != null && tags.isNotEmpty) {
          tagsByGroupName[gName] = tags.map((t) => t.name).toList();
        }
      } else {
        await Future.wait(
          widget.groups.map((g) async {
            final tags = await tagsCache.fetchTags(g.id);
            tagsByGroupId[g.id] = tags;
            if (tags.isNotEmpty) {
              tagsByGroupName[g.name] = tags.map((t) => t.name).toList();
            }
          }),
        );
      }
      // #region agent log
      sw.stop();
      phasesMs['firestore_prefetch_tags'] = sw.elapsedMilliseconds;
      await VoicePerfLogger.phase(
        'firestore_prefetch_tags',
        elapsedMs: sw.elapsedMilliseconds,
        hypothesisId: 'C',
        data: {'groupCount': widget.groups.length},
      );
      sw = Stopwatch()..start();
      // #endregion
      String? forcedGroupName;
      if (hasForcedGroup) {
        for (final g in widget.groups) {
          if (g.id == forcedGid) {
            forcedGroupName = g.name;
            break;
          }
        }
      }

      final extraction = await pipeline.transcribeAndExtract(
        audioFile: file,
        groups: widget.groups,
        contextGroupName: ctxName,
        forcedGroupName: forcedGroupName,
        hasForcedGroup: hasForcedGroup,
        tagsByGroupName: tagsByGroupName,
      );
      // #region agent log
      sw.stop();
      phasesMs['transcribe_and_extract'] = sw.elapsedMilliseconds;
      await VoicePerfLogger.phase(
        'transcribe_and_extract_total',
        elapsedMs: sw.elapsedMilliseconds,
        hypothesisId: 'A,B',
        data: {'taskCount': extraction.tasks.length},
      );
      // #endregion
      if (extraction.tasks.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Não foi possível extrair tarefas a partir do áudio.';
        });
        try {
          await file.delete();
        } catch (_) {}
        pipeline.dispose();
        return;
      }

      final distinctGids = <String>{};
      for (final dto in extraction.tasks) {
        final gid = resolveGroupId(
          groupNameFromLlm: dto.groupName,
          groups: widget.groups,
          forcedGroupId: widget.forcedGroupId,
        );
        if (gid != null && gid.isNotEmpty) distinctGids.add(gid);
      }

      final tasksByGroupId = <String, List<TaskModel>>{};
      // #region agent log
      sw = Stopwatch()..start();
      var firestoreFetchMs = 0;
      // #endregion
      await Future.wait(
        distinctGids.map((gid) async {
          // #region agent log
          final gidSw = Stopwatch()..start();
          // #endregion
          tasksByGroupId[gid] = await fs.fetchTasksByGroupOnce(gid);
          // #region agent log
          gidSw.stop();
          firestoreFetchMs += gidSw.elapsedMilliseconds;
          await VoicePerfLogger.phase(
            'firestore_fetch_tasks',
            elapsedMs: gidSw.elapsedMilliseconds,
            hypothesisId: 'C',
            data: {
              'groupId': gid,
              'tasksCount': tasksByGroupId[gid]?.length ?? 0,
            },
          );
          // #endregion
        }),
      );
      // #region agent log
      sw.stop();
      phasesMs['firestore_fetch_all'] = sw.elapsedMilliseconds;
      await VoicePerfLogger.phase(
        'firestore_fetch_all',
        elapsedMs: sw.elapsedMilliseconds,
        hypothesisId: 'C',
        data: {
          'distinctGroupCount': distinctGids.length,
          'sumPerGroupMs': firestoreFetchMs,
        },
      );
      sw = Stopwatch()..start();
      // #endregion

      final enriched = await pipeline.enrichExtractedVoiceTasksWithTagAssignments(
        tasks: extraction.tasks,
        groups: widget.groups,
        forcedGroupId: widget.forcedGroupId,
        tagsByGroupId: tagsByGroupId,
        transcript: extraction.transcript,
      );
      // #region agent log
      sw.stop();
      phasesMs['enrich_tags'] = sw.elapsedMilliseconds;
      await VoicePerfLogger.phase(
        'enrich_tags_total',
        elapsedMs: sw.elapsedMilliseconds,
        hypothesisId: 'D',
        data: {'taskCount': enriched.length},
      );
      sw = Stopwatch()..start();
      // #endregion

      final stats = await persistExtractedVoiceTasksWithDedup(
        dtos: enriched,
        groups: widget.groups,
        forcedGroupId: widget.forcedGroupId,
        firebase: fs,
        notification: ns,
        existingTasksByGroupId: tasksByGroupId,
        tagsByGroupId: tagsByGroupId,
        deferReminderSync: true,
      );
      // #region agent log
      sw.stop();
      phasesMs['persist_tasks'] = sw.elapsedMilliseconds;
      await VoicePerfLogger.phase(
        'persist_tasks',
        elapsedMs: sw.elapsedMilliseconds,
        hypothesisId: 'E',
        data: {
          'created': stats.created,
          'reopened': stats.reopened,
        },
      );
      totalSw.stop();
      phasesMs['total'] = totalSw.elapsedMilliseconds;
      await VoicePerfLogger.summary(phasesMs);
      // #endregion
      pipeline.dispose();
      try {
        await file.delete();
      } catch (_) {}
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final parts = <String>[];
      if (stats.created > 0) parts.add('${stats.created} nova(s)');
      if (stats.reopened > 0) parts.add('${stats.reopened} reaberta(s)');
      final msg =
          parts.isEmpty ? 'Nada a gravar.' : '${parts.join(', ')}.';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
      unawaited(
        runDeferredVoiceReminderSync(notification: ns, result: stats),
      );
    } catch (e) {
      pipeline.dispose();
      setState(() {
        _processing = false;
        _error = '$e';
      });
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ditar tarefa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B2D42),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _processing ? null : _stopAndDiscard,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _recording
                ? 'A gravar… Toque em Confirmar quando terminar.'
                : 'Toque em Gravar, fale com calma e depois em Confirmar.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          if (_processing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.brandPrimary),
                    SizedBox(height: 16),
                    Text('A transcrever e a criar tarefas…'),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _recording ? null : _startRecording,
                    icon: const Icon(Icons.mic_rounded),
                    label: const Text('Gravar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _recording ? _confirmRecording : null,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Confirmar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
