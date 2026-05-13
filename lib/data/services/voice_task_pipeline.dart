import 'dart:io';

import '../../business_logic/voice_tag_resolver.dart';
import '../../business_logic/voice_task_duplicate_finder.dart';
import '../../business_logic/voice_task_due_parser.dart';
import '../../business_logic/voice_task_group_resolver.dart';
import '../../utils/calendar_day_key.dart';
import '../models/extracted_voice_task_dto.dart';
import '../models/group_model.dart';
import '../models/tag_model.dart';
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

  /// Fase 2 OpenRouter: atribui [tagName] por item para cada grupo com etiquetas.
  Future<List<ExtractedVoiceTaskDto>> enrichExtractedVoiceTasksWithTagAssignments({
    required List<ExtractedVoiceTaskDto> tasks,
    required List<GroupModel> groups,
    String? forcedGroupId,
    required Map<String, List<TagModel>> tagsByGroupId,
    String? transcript,
  }) async {
    if (tasks.isEmpty) return tasks;

    final byGroup = <String, List<int>>{};
    for (var i = 0; i < tasks.length; i++) {
      final gid = resolveGroupId(
        groupNameFromLlm: tasks[i].groupName,
        groups: groups,
        forcedGroupId: forcedGroupId,
      );
      if (gid != null && gid.isNotEmpty) {
        byGroup.putIfAbsent(gid, () => []).add(i);
      }
    }

    final out = List<ExtractedVoiceTaskDto>.from(tasks);
    for (final e in byGroup.entries) {
      final gid = e.key;
      final tags = tagsByGroupId[gid] ?? const <TagModel>[];
      if (tags.isEmpty) continue;

      final indices = e.value;
      final titles = indices.map((i) => tasks[i].title).toList();
      final assigned = await _openRouter.assignShoppingTags(
        itemTitles: titles,
        tags: tags,
        transcriptContext: transcript,
      );
      for (var j = 0; j < indices.length; j++) {
        final idx = indices[j];
        if (j < assigned.length && assigned[j] != null) {
          out[idx] = out[idx].copyWith(tagName: assigned[j]);
        }
      }
    }
    return out;
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

class VoicePersistResult {
  final int created;
  final int reopened;

  const VoicePersistResult({required this.created, required this.reopened});

  int get total => created + reopened;
}


void _replaceTaskInCache(Map<String, List<TaskModel>> cache, TaskModel updated) {
  final gid = updated.groupId?.trim();
  if (gid == null || gid.isEmpty) return;
  final list = cache[gid];
  if (list == null) return;
  final i = list.indexWhere((t) => t.id == updated.id);
  if (i >= 0) list[i] = updated;
}

List<String> _tagIdsForDto(
  String? groupId,
  String? tagName,
  Map<String, List<TagModel>> tagsByGroupId,
) {
  if (groupId == null || tagName == null) return [];
  final id = resolveTagIdByName(tagName, tagsByGroupId[groupId] ?? const []);
  return id != null ? [id] : [];
}

/// Grava tarefas com deduplicação por título no [groupId] e sincroniza lembretes.
Future<VoicePersistResult> persistExtractedVoiceTasksWithDedup({
  required List<ExtractedVoiceTaskDto> dtos,
  required List<GroupModel> groups,
  String? forcedGroupId,
  required FirebaseService firebase,
  required NotificationService notification,
  required Map<String, List<TaskModel>> existingTasksByGroupId,
  required Map<String, List<TagModel>> tagsByGroupId,
}) async {
  var created = 0;
  var reopened = 0;
  final cache = <String, List<TaskModel>>{
    for (final e in existingTasksByGroupId.entries)
      e.key: List<TaskModel>.from(e.value),
  };

  for (final dto in dtos) {
    final groupId = resolveGroupId(
      groupNameFromLlm: dto.groupName,
      groups: groups,
      forcedGroupId: forcedGroupId,
    );
    final tagIds = _tagIdsForDto(groupId, dto.tagName, tagsByGroupId);

    if (groupId != null && groupId.isNotEmpty) {
      final groupTasks = cache[groupId] ?? [];
      final dup = findDuplicateGroupTaskByTitle(groupTasks, dto.title);
      if (dup != null) {
        final newTagIds =
            tagIds.isNotEmpty ? tagIds : List<String>.from(dup.tagIds);
        final shouldClearOcc = dup.recurrence != null && dup.isCompleted;
        final updated = dup.copyWith(
          isCompleted: false,
          tagIds: newTagIds,
          completedOccurrenceDateKeys:
              shouldClearOcc ? <String>[] : dup.completedOccurrenceDateKeys,
        );
        await firebase.updateTask(updated);
        if (updated.reminderType == 'datetime') {
          await notification.syncTaskDatetimeReminders(updated);
        } else {
          await notification.cancelAllTaskReminderSlots(updated.id);
        }
        _replaceTaskInCache(cache, updated);
        reopened++;
        continue;
      }
    }

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
      tagIds: tagIds,
    );
    final id = await firebase.addTask(task);
    final persisted = task.copyWith(id: id);
    if (groupId != null && groupId.isNotEmpty) {
      cache.putIfAbsent(groupId, () => []).add(persisted);
    }
    if (due.reminderType == 'datetime') {
      await notification.syncTaskDatetimeReminders(persisted);
    } else {
      await notification.cancelAllTaskReminderSlots(id);
    }
    created++;
  }

  return VoicePersistResult(created: created, reopened: reopened);
}

/// Compatível com fluxos antigos: só cria (sem dedup nem tags em cache).
Future<int> persistExtractedVoiceTasks({
  required List<ExtractedVoiceTaskDto> dtos,
  required List<GroupModel> groups,
  String? forcedGroupId,
  required FirebaseService firebase,
  required NotificationService notification,
}) async {
  final emptyTags = <String, List<TagModel>>{};
  final existing = <String, List<TaskModel>>{};
  for (final dto in dtos) {
    final gid = resolveGroupId(
      groupNameFromLlm: dto.groupName,
      groups: groups,
      forcedGroupId: forcedGroupId,
    );
    if (gid != null && gid.isNotEmpty) {
      existing.putIfAbsent(gid, () => []);
    }
  }
  final r = await persistExtractedVoiceTasksWithDedup(
    dtos: dtos,
    groups: groups,
    forcedGroupId: forcedGroupId,
    firebase: firebase,
    notification: notification,
    existingTasksByGroupId: existing,
    tagsByGroupId: emptyTags,
  );
  return r.total;
}
