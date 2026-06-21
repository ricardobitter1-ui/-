import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../business_logic/voice_extraction_plan.dart';
import '../../business_logic/voice_recording_quality.dart';
import '../../business_logic/voice_task_group_resolver.dart';
import '../../data/local/voice_capture_prefs.dart';
import '../../data/models/group_model.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/providers/group_tags_cache_provider.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/voice_api_config.dart';
import '../../data/services/voice_task_pipeline.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import 'eximium/eximium.dart';
import 'voice_amplitude_waveform.dart';
import 'voice_extraction_preview_sheet.dart';

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
    backgroundColor: Colors.transparent,
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

class _VoiceTaskRecordingBodyState extends ConsumerState<_VoiceTaskRecordingBody>
    with SingleTickerProviderStateMixin {
  static const int _waveBarCount = 32;

  late final AnimationController _pulseController;

  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _starting = false;
  bool _processing = false;
  String _processingStage = '';
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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startRecording());
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _amplitudeSub?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  String _formatElapsed() {
    final start = _recordingStartedAt;
    if (start == null) return '00:00';
    final d = DateTime.now().difference(start);
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
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
      _processingStage = 'Carregando categorias…';
      _error = null;
    });

    final file = File(filePath);
    final pipeline = VoiceTaskPipeline();
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
      var tagsByGroupId = <String, List<TagModel>>{};
      final tagsByGroupName = <String, List<String>>{};
      final forcedGid = widget.forcedGroupId?.trim();
      final hasForcedGroup =
          forcedGid != null && forcedGid.isNotEmpty;
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
      if (mounted) {
        setState(() => _processingStage = 'Transcrevendo áudio…');
      }
      GroupModel? forcedGroup;
      String? forcedGroupName;
      if (hasForcedGroup) {
        for (final g in widget.groups) {
          if (g.id == forcedGid) {
            forcedGroup = g;
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
        forcedGroup: forcedGroup,
        contextGroup: widget.contextGroup,
        hasForcedGroup: hasForcedGroup,
        tagsByGroupName: tagsByGroupName,
      );
      if (mounted) {
        setState(() => _processingStage = 'Organizando tarefas…');
      }

      if (extraction.tasks.isEmpty) {
        setState(() {
          _processing = false;
          _processingStage = '';
          _error = 'Não foi possível extrair tarefas a partir do áudio.';
        });
        try {
          await file.delete();
        } catch (_) {}
        pipeline.dispose();
        return;
      }

      final distinctGids = <String>{};
      if (hasForcedGroup) {
        distinctGids.add(forcedGid);
      }
      for (final dto in extraction.tasks) {
        final gid = resolveGroupId(
          groupNameFromLlm: dto.groupName,
          groups: widget.groups,
          forcedGroupId: widget.forcedGroupId,
        );
        if (gid != null && gid.isNotEmpty) distinctGids.add(gid);
      }

      final tasksByGroupId = <String, List<TaskModel>>{};
      await Future.wait(
        distinctGids.map((gid) async {
          tasksByGroupId[gid] = await fs.fetchTasksByGroupOnce(gid);
        }),
      );

      var enriched = await pipeline.enrichExtractedVoiceTasksWithTagAssignments(
        tasks: extraction.tasks,
        groups: widget.groups,
        forcedGroupId: widget.forcedGroupId,
        tagsByGroupId: tagsByGroupId,
        transcript: extraction.transcript,
      );

      var plan = buildVoiceExtractionPlan(
        tasks: enriched,
        groups: widget.groups,
        forcedGroupId: widget.forcedGroupId,
        tagsByGroupId: tagsByGroupId,
      );

      final confirmBeforeSave = await loadVoiceConfirmBeforeSave();
      if (confirmBeforeSave && mounted) {
        setState(() => _processing = false);
        final preview = await showVoiceExtractionPreviewSheet(
          context: context,
          initialPlan: plan,
          groups: widget.groups,
          forcedGroupId: widget.forcedGroupId,
          tagsByGroupId: tagsByGroupId,
          transcript: extraction.transcript,
        );
        if (!mounted) {
          pipeline.dispose();
          return;
        }
        if (preview == null) {
          setState(() {
            _processing = false;
            _error = null;
          });
          pipeline.dispose();
          try {
            await file.delete();
          } catch (_) {}
          return;
        }
        plan = preview.plan;
        setState(() {
          _processing = true;
          _processingStage = 'Salvando tarefas…';
        });
      }

      if (mounted && _processing) {
        setState(() => _processingStage = 'Salvando tarefas…');
      }

      if (plan.tagsToCreate.isNotEmpty) {
        tagsByGroupId = await createPlannedVoiceTags(
          tagsToCreate: plan.tagsToCreate,
          firebase: fs,
          tagsByGroupId: tagsByGroupId,
        );
        for (final t in plan.tagsToCreate) {
          ref.read(groupTagsCacheProvider.notifier).invalidate(t.groupId);
        }
      }

      enriched = canonicalizeTaskTagNames(
        tasks: plan.tasks,
        groups: widget.groups,
        forcedGroupId: widget.forcedGroupId,
        tagsByGroupId: tagsByGroupId,
      );

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
    if (_processing) {
      return _processingStage.isNotEmpty
          ? _processingStage
          : 'Processando ditado…';
    }
    if (_starting) return 'Preparando o microfone…';
    if (_recording) {
      return 'Fale com calma. Toque no quadrado vermelho quando terminar.';
    }
    if (_error != null) return 'Ajuste a gravação e tente novamente.';
    return 'Iniciando gravação…';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canStop = _recording && !_processing;
    final canCancel = !_processing;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _recording ? _pulseController.value : 0.0;
        final borderColor = Color.lerp(
          ExColors.brandGreen.withValues(alpha: 0.35),
          ExColors.brandGreen,
          t,
        )!;
        return Container(
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ExRadius.xl),
            ),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: _recording
                ? [
                    BoxShadow(
                      color: ExColors.brandGreen.withValues(
                        alpha: 0.18 + 0.22 * t,
                      ),
                      blurRadius: 24 + 16 * t,
                    ),
                  ]
                : c.shadowFloat,
          ),
          child: child,
        );
      },
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: c.surface3,
                  borderRadius: BorderRadius.circular(ExRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: ExSpace.s5),
            Text(
              'Ditar tarefa',
              textAlign: TextAlign.center,
              style: ExText.h2(c.textPrimary),
            ),
            const SizedBox(height: ExSpace.s3),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: ExText.body(c.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: ExSpace.s3),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: ExText.body(c.errorText),
              ),
            ],
            const SizedBox(height: ExSpace.s6),
            if (_processing)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ExSpace.s8),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: ExColors.brandGreen,
                      ),
                      const SizedBox(height: ExSpace.s4),
                      Text(
                        'Processando ditado…',
                        style: ExText.body(c.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_recording)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ExSpace.s3,
                      vertical: ExSpace.s2,
                    ),
                    decoration: BoxDecoration(
                      color: ExColors.errorBg,
                      borderRadius: BorderRadius.circular(ExRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExDot(color: c.errorText, size: 8),
                        const SizedBox(width: ExSpace.s2),
                        Text(
                          'Gravando · ${_formatElapsed()}',
                          style: ExText.mono(size: 13, color: c.errorText),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: ExSpace.s6),
              VoiceAmplitudeWaveform(
                levels: _waveLevels,
                barCount: _waveBarCount,
                height: 80,
                activeColor:
                    _recording ? ExColors.brandGreen : c.textMuted,
              ),
              const SizedBox(height: ExSpace.s8),
              Center(
                child: _VoiceMicButton(
                  enabled: canStop,
                  onPressed: canStop ? _confirmRecording : null,
                ),
              ),
              const SizedBox(height: ExSpace.s6),
              Row(
                children: [
                  Expanded(
                    child: ExButton(
                      label: 'Cancelar',
                      variant: ExButtonVariant.secondary,
                      expand: true,
                      onPressed: canCancel ? _stopAndDiscard : null,
                    ),
                  ),
                  const SizedBox(width: ExSpace.s3),
                  Expanded(
                    child: ExButton(
                      label: 'Concluir',
                      variant: ExButtonVariant.primary,
                      expand: true,
                      onPressed: canStop ? _confirmRecording : null,
                    ),
                  ),
                ],
              ),
              if (_error != null && !_recording) ...[
                const SizedBox(height: ExSpace.s2),
                Center(
                  child: TextButton(
                    onPressed:
                        canCancel ? () => unawaited(_startRecording()) : null,
                    child: const Text('Tentar novamente'),
                  ),
                ),
              ],
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão circular grande verde com microfone (glow) — conclui o ditado.
class _VoiceMicButton extends StatelessWidget {
  const _VoiceMicButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
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
            color: enabled ? ExColors.brandGreen : c.surface3,
            boxShadow: enabled ? ExEffects.glowLg : null,
          ),
          child: Center(
            child: Icon(
              Icons.mic_rounded,
              size: 36,
              color: enabled ? ExColors.onBrandGreen : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
