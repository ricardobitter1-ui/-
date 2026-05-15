import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../business_logic/voice_recording_quality.dart';
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
import 'voice_amplitude_waveform.dart';

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
  static const int _waveBarCount = 32;

  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _starting = false;
  bool _processing = false;
  String? _error;
  String? _tempPath;
  StreamSubscription<Amplitude>? _amplitudeSub;
  List<double> _waveLevels =
      List<double>.filled(_waveBarCount, 0.08, growable: false);
  DateTime? _recordingStartedAt;
  double _peakDbfs = VoiceRecordingQuality.silenceDbfs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startRecording());
    });
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  void _listenAmplitude() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
      if (!mounted) return;
      _peakDbfs = VoiceRecordingQuality.trackPeakDbfs(_peakDbfs, amp.current);
      _peakDbfs = VoiceRecordingQuality.trackPeakDbfs(_peakDbfs, amp.max);
      final level = voiceAmplitudeLevel(amp.current);
      setState(() {
        final next = List<double>.from(_waveLevels)..removeAt(0)..add(level);
        _waveLevels = next;
      });
    });
  }

  void _stopAmplitudeListener() {
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    if (mounted) {
      setState(() {
        _waveLevels = List<double>.filled(_waveBarCount, 0.08, growable: false);
      });
    }
  }

  void _resetRecordingMetrics() {
    _recordingStartedAt = null;
    _peakDbfs = VoiceRecordingQuality.silenceDbfs;
  }

  Future<void> _discardInvalidRecording({
    required String? filePath,
    required VoiceRecordingQualityIssue issue,
  }) async {
    if (filePath != null) {
      try {
        final f = File(filePath);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
    _tempPath = null;
    _resetRecordingMetrics();
    if (!mounted) return;
    setState(() {
      _processing = false;
      _recording = false;
      _error = issue.userMessage;
    });
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
    if (_recording || _starting || _processing) return;
    setState(() {
      _error = null;
      _starting = true;
    });
    if (!VoiceApiConfig.isConfigured) {
      final hint = VoiceApiConfig.configurationHint();
      setState(() {
        _starting = false;
        _error =
            '${hint.isNotEmpty ? hint : 'APIs não configuradas.'}\nCopie secrets.json.example para secrets.json e execute:\nflutter run --dart-define-from-file=secrets.json';
      });
      return;
    }
    final ok = await _ensureMicPermission();
    if (!ok || !mounted) {
      setState(() => _starting = false);
      return;
    }

    final can = await _recorder.hasPermission();
    if (can != true) {
      setState(() {
        _starting = false;
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
      if (!mounted) return;
      _recordingStartedAt = DateTime.now();
      _peakDbfs = VoiceRecordingQuality.silenceDbfs;
      _listenAmplitude();
      setState(() {
        _recording = true;
        _starting = false;
      });
    } catch (e) {
      setState(() {
        _starting = false;
        _error = 'Não foi possível iniciar a gravação: $e';
      });
    }
  }

  Future<void> _stopAndDiscard() async {
    if (_processing) return;
    _stopAmplitudeListener();
    if (_recording) {
      await _recorder.cancel();
      _recording = false;
      _tempPath = null;
      if (mounted) setState(() {});
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmRecording() async {
    if (!_recording || _processing) return;
    _stopAmplitudeListener();
    final duration = _recordingStartedAt != null
        ? DateTime.now().difference(_recordingStartedAt!)
        : Duration.zero;
    final peakDbfs = _peakDbfs;

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

    final qualityIssue = VoiceRecordingQuality.validate(
      duration: duration,
      peakDbfs: peakDbfs,
    );
    if (qualityIssue != null) {
      await _discardInvalidRecording(
        filePath: filePath,
        issue: qualityIssue,
      );
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

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

  String get _statusText {
    if (_processing) return 'A transcrever e a criar tarefas…';
    if (_starting) return 'A preparar o microfone…';
    if (_recording) {
      return 'Fale com calma. Toque no quadrado vermelho quando terminar.';
    }
    if (_error != null) return 'Ajuste a gravação e tente novamente.';
    return 'A iniciar gravação…';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canStop = _recording && !_processing;
    final canCancel = !_processing;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ditar tarefa',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2B2D42),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 28),
          if (_processing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.brandPrimary),
                    SizedBox(height: 16),
                    Text('A transcrever e a criar tarefas…'),
                  ],
                ),
              ),
            )
          else ...[
            VoiceAmplitudeWaveform(
              levels: _waveLevels,
              barCount: _waveBarCount,
              height: 80,
              activeColor: _recording ? AppTheme.brandPrimary : Colors.grey.shade400,
            ),
            const SizedBox(height: 32),
            Center(
              child: _VoiceStopButton(
                enabled: canStop,
                onPressed: canStop ? _confirmRecording : null,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: canCancel ? _stopAndDiscard : null,
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: canCancel ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
            ),
            if (_error != null && !_recording) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: canCancel ? () => unawaited(_startRecording()) : null,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Botão circular de parar gravação (quadrado vermelho no centro).
class _VoiceStopButton extends StatelessWidget {
  const _VoiceStopButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? AppTheme.brandPrimary.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            border: Border.all(
              color: enabled
                  ? AppTheme.brandPrimary.withValues(alpha: 0.35)
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFE53935) : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
