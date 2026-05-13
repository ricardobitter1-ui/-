import 'dart:io';

import '../../business_logic/voice_task_due_parser.dart';
import '../../business_logic/voice_task_group_resolver.dart';
import '../../utils/calendar_day_key.dart';
import '../models/extracted_voice_task_dto.dart';
import '../models/group_model.dart';
import '../models/task_model.dart';
import 'firebase_service.dart';
import 'groq_transcription_service.dart';
import 'notification_service.dart';
import 'openrouter_voice_task_service.dart';

/// Orquestra Groq → OpenRouter e devolve DTOs (sem gravar).
class VoiceTaskPipeline {
  VoiceTaskPipeline({
    GroqTranscriptionService? groq,
    OpenRouterVoiceTaskService? openRouter,
  })  : _groq = groq ?? GroqTranscriptionService(),
        _openRouter = openRouter ?? OpenRouterVoiceTaskService();

  final GroqTranscriptionService _groq;
  final OpenRouterVoiceTaskService _openRouter;

  Future<VoiceTranscriptionExtractionResult> transcribeAndExtract({
    required File audioFile,
    required List<GroupModel> groups,
    DateTime? referenceDate,
    String? contextGroupName,
  }) async {
    final transcript = await _groq.transcribeFile(audioFile: audioFile);
    if (transcript.isEmpty) {
      throw StateError('Transcrição vazia');
    }
    final ref = referenceDate ?? DateTime.now();
    final dayKey = localCalendarDayKey(ref);
    final names = groups.map((g) => g.name).toList();
    final dtos = await _openRouter.extractTasks(
      transcript: transcript,
      groupNames: names,
      referenceDate: dayKey,
      contextGroupName: contextGroupName,
    );
    return VoiceTranscriptionExtractionResult(
      transcript: transcript,
      tasks: dtos,
    );
  }

  void dispose() {
    _groq.close();
    _openRouter.close();
  }
}

class VoiceTranscriptionExtractionResult {
  final String transcript;
  final List<ExtractedVoiceTaskDto> tasks;

  const VoiceTranscriptionExtractionResult({
    required this.transcript,
    required this.tasks,
  });
}

/// Grava [TaskModel] no Firestore e sincroniza lembretes.
Future<int> persistExtractedVoiceTasks({
  required List<ExtractedVoiceTaskDto> dtos,
  required List<GroupModel> groups,
  String? forcedGroupId,
  required FirebaseService firebase,
  required NotificationService notification,
}) async {
  var count = 0;
  for (final dto in dtos) {
    final groupId = resolveGroupId(
      groupNameFromLlm: dto.groupName,
      groups: groups,
      forcedGroupId: forcedGroupId,
    );
    final due = VoiceTaskDueParser.parse(dto.date, dto.time);
    final task = TaskModel(
      id: '',
      title: dto.title,
      description: dto.description.trim(),
      isCompleted: false,
      reminderType: due.reminderType,
      dueDate: due.dueDate,
      dueHasTime: due.dueHasTime,
      groupId: groupId,
    );
    final id = await firebase.addTask(task);
    final persisted = task.copyWith(id: id);
    if (due.reminderType == 'datetime') {
      await notification.syncTaskDatetimeReminders(persisted);
    } else {
      await notification.cancelAllTaskReminderSlots(id);
    }
    count++;
  }
  return count;
}
