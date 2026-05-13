import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../data/models/group_model.dart';
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
      setState(() {
        _error =
            'APIs não configuradas. Copie secrets.json.example para secrets.json, preencha as chaves e execute o app com:\nflutter run --dart-define-from-file=secrets.json';
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
      final extraction = await pipeline.transcribeAndExtract(
        audioFile: file,
        groups: widget.groups,
        contextGroupName: ctxName,
      );
      pipeline.dispose();
      if (extraction.tasks.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Não foi possível extrair tarefas a partir do áudio.';
        });
        try {
          await file.delete();
        } catch (_) {}
        return;
      }

      final fs = ref.read(firebaseServiceProvider);
      final ns = ref.read(notificationServiceProvider);
      final n = await persistExtractedVoiceTasks(
        dtos: extraction.tasks,
        groups: widget.groups,
        forcedGroupId: widget.forcedGroupId,
        firebase: fs,
        notification: ns,
      );
      try {
        await file.delete();
      } catch (_) {}
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final msg = n == 1 ? '1 tarefa criada.' : '$n tarefas criadas.';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
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
