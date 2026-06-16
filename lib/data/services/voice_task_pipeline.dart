import 'dart:io';

import '../../business_logic/voice_intent_router.dart';
import '../../business_logic/voice_reminder_extract_postprocessor.dart';
import '../../business_logic/voice_shopping_list_context.dart';
import '../../business_logic/voice_reminder_heuristic_parser.dart';
import '../../business_logic/voice_tag_resolver.dart';
import '../../business_logic/voice_task_duplicate_finder.dart';
import '../../business_logic/voice_task_due_parser.dart';
import '../../business_logic/voice_task_group_resolver.dart';
import '../../business_logic/voice_task_title_sanitizer.dart';
import '../../debug/voice_perf_logger.dart';
import '../../utils/calendar_day_key.dart';
import '../models/extracted_voice_task_dto.dart';
import '../models/group_model.dart';
import '../models/tag_model.dart';
import '../models/task_model.dart';
import 'firebase_service.dart';
import 'groq_transcription_service.dart';
import 'notification_service.dart';
import 'openrouter_voice_task_service.dart';
import 'voice/voice_extract_request.dart';
import 'voice/voice_llm_client.dart';
import 'voice/voice_llm_client_factory.dart';

/// Orquestra STT (Groq) → extração (LLM configurável) → DTOs (sem gravar).
class VoiceTaskPipeline {
  VoiceTaskPipeline({
    GroqTranscriptionService? groq,
    VoiceLlmClient? llm,
    OpenRouterVoiceTaskService? openRouterTagFallback,
  })  : _groq = groq ?? GroqTranscriptionService(),
        _llm = llm ?? VoiceLlmClientFactory.create(),
        _openRouterTagFallback = openRouterTagFallback;

  final GroqTranscriptionService _groq;
  final VoiceLlmClient _llm;
  final OpenRouterVoiceTaskService? _openRouterTagFallback;

  Future<VoiceTranscriptionExtractionResult> transcribeAndExtract({
    required File audioFile,
    required List<GroupModel> groups,
    DateTime? referenceDate,
    String? contextGroupName,
    String? forcedGroupName,
    GroupModel? forcedGroup,
    GroupModel? contextGroup,
    bool hasForcedGroup = false,
    Map<String, List<String>> tagsByGroupName = const {},
  }) async {
    final audioBytes = await audioFile.length();
    var sw = Stopwatch()..start();
    final transcript = await _groq.transcribeFile(audioFile: audioFile);
    sw.stop();
    await VoicePerfLogger.phase(
      'groq_transcribe',
      elapsedMs: sw.elapsedMilliseconds,
      hypothesisId: 'A',
      data: {
        'audioBytes': audioBytes,
        'transcriptChars': transcript.length,
      },
    );

    if (transcript.isEmpty) {
      throw StateError('Transcrição vazia');
    }

    final tasks = await extractFromTranscript(
      transcript: transcript,
      groups: groups,
      referenceDate: referenceDate,
      contextGroupName: contextGroupName,
      forcedGroupName: forcedGroupName,
      forcedGroup: forcedGroup,
      contextGroup: contextGroup,
      hasForcedGroup: hasForcedGroup,
      tagsByGroupName: tagsByGroupName,
    );

    return VoiceTranscriptionExtractionResult(
      transcript: transcript,
      tasks: tasks,
    );
  }

  Future<List<ExtractedVoiceTaskDto>> extractFromTranscript({
    required String transcript,
    required List<GroupModel> groups,
    DateTime? referenceDate,
    String? contextGroupName,
    String? forcedGroupName,
    GroupModel? forcedGroup,
    GroupModel? contextGroup,
    bool hasForcedGroup = false,
    Map<String, List<String>> tagsByGroupName = const {},
  }) async {
    final ref = referenceDate ?? DateTime.now();
    final dayKey = localCalendarDayKey(ref);
    final referenceDateForPrompt =
        '$dayKey ${ref.hour.toString().padLeft(2, '0')}:${ref.minute.toString().padLeft(2, '0')}';
    final names = groups.map((g) => g.name).toList();

    final classification = VoiceIntentRouter.classify(
      transcript: transcript,
      hasForcedGroup: hasForcedGroup,
      contextGroupName: contextGroupName,
      forcedGroupName: forcedGroupName,
      forcedGroup: forcedGroup,
      contextGroup: contextGroup,
    );

    await VoicePerfLogger.phase(
      'voice_intent',
      elapsedMs: 0,
      hypothesisId: 'B',
      data: {
        'intent': classification.intentLabel,
        'mode': classification.mode.name,
        'provider': _llm.providerId,
        'model': _llm.modelId,
      },
    );

    if (classification.mode == VoiceExtractMode.reminder) {
      final heuristic = VoiceReminderHeuristicParser.parse(
        transcript: transcript,
        referenceDate: ref,
        forcedGroupName: forcedGroupName,
        groups: groups,
      );
      if (heuristic.confident && heuristic.task != null) {
        await VoicePerfLogger.phase(
          'reminder_heuristic',
          elapsedMs: 0,
          hypothesisId: 'B',
          data: {'intent': 'reminder_heuristic_ok'},
        );
        final refined = VoiceReminderExtractPostprocessor.refine(
          tasks: [heuristic.task!],
          referenceDate: ref,
        );
        return _finalizeExtractedTasks(
          tasks: refined,
          transcript: transcript,
          groups: groups,
          shoppingListItemTitles: VoiceShoppingListContext
              .shouldUseShoppingItemTitles(
            forcedGroup: forcedGroup,
            contextGroup: contextGroup,
            forcedGroupName: forcedGroupName,
            contextGroupName: contextGroupName,
          ),
          noteCapture: false,
        );
      }
    }

    final mode = classification.mode == VoiceExtractMode.reminder
        ? VoiceExtractMode.reminder
        : classification.mode;

    final noteCapture = mode == VoiceExtractMode.noteCapture;
    final shoppingListItemTitles = !noteCapture &&
        VoiceShoppingListContext.shouldUseShoppingItemTitles(
          forcedGroup: forcedGroup,
          contextGroup: contextGroup,
          forcedGroupName: forcedGroupName,
          contextGroupName: contextGroupName,
        );

    final request = VoiceExtractRequest(
      transcript: transcript,
      groupNames: names,
      referenceDate: referenceDateForPrompt,
      contextGroupName: contextGroupName,
      tagsByGroupName: tagsByGroupName,
      forcedGroupName: forcedGroupName,
      shoppingListItemTitles: shoppingListItemTitles,
      mode: mode,
    );

    final sw = Stopwatch()..start();
    final dtos = await _llm.extractTasks(request);
    sw.stop();
    await VoicePerfLogger.phase(
      'llm_extract_tasks',
      elapsedMs: sw.elapsedMilliseconds,
      hypothesisId: 'B',
      data: {
        'taskCount': dtos.length,
        'intent': classification.intentLabel,
        'provider': _llm.providerId,
        'model': _llm.modelId,
      },
    );
    final refined = mode == VoiceExtractMode.reminder
        ? VoiceReminderExtractPostprocessor.refine(
            tasks: dtos,
            referenceDate: ref,
          )
        : dtos;
    return _finalizeExtractedTasks(
      tasks: refined,
      transcript: transcript,
      groups: groups,
      shoppingListItemTitles: shoppingListItemTitles,
      noteCapture: noteCapture,
    );
  }

  List<ExtractedVoiceTaskDto> _finalizeExtractedTasks({
    required List<ExtractedVoiceTaskDto> tasks,
    required String transcript,
    required List<GroupModel> groups,
    required bool shoppingListItemTitles,
    required bool noteCapture,
  }) {
    return tasks
        .map((dto) {
          final title = shoppingListItemTitles
              ? VoiceTaskTitleSanitizer.sanitizeShoppingItemTitle(dto.title)
              : VoiceTaskTitleSanitizer.sanitize(
                  dto.title,
                  stripDateHints: dto.date != null,
                  stripTimeHints: dto.time != null,
                );
          final description = noteCapture ? dto.description.trim() : dto.description;
          var groupName = dto.groupName?.trim();
          if (groupName == null || groupName.isEmpty) {
            groupName = inferGroupNameFromTranscript(
              transcript: transcript,
              groups: groups,
            );
          }
          return dto.copyWith(
            title: title,
            description: description,
            groupName: groupName,
          );
        })
        .toList();
  }

  Future<List<ExtractedVoiceTaskDto>> enrichExtractedVoiceTasksWithTagAssignments({
    required List<ExtractedVoiceTaskDto> tasks,
    required List<GroupModel> groups,
    String? forcedGroupId,
    required Map<String, List<TagModel>> tagsByGroupId,
    String? transcript,
    bool allowLlmTagFallback = false,
  }) async {
    if (tasks.isEmpty) return tasks;

    final out = List<ExtractedVoiceTaskDto>.from(tasks);
    for (var i = 0; i < out.length; i++) {
      final gid = resolveGroupId(
        groupNameFromLlm: out[i].groupName,
        groups: groups,
        forcedGroupId: forcedGroupId,
      );
      final tags =
          gid == null ? const <TagModel>[] : (tagsByGroupId[gid] ?? const []);
      final canonical = _canonicalTagName(
        out[i].tagName,
        tags,
        preserveIfMissing: out[i].tagExplicit,
      );
      out[i] = out[i].copyWith(tagName: canonical);
    }

    if (!allowLlmTagFallback || _openRouterTagFallback == null) return out;

    final byGroup = <String, List<int>>{};
    for (var i = 0; i < out.length; i++) {
      if (out[i].tagName != null) continue;
      final gid = resolveGroupId(
        groupNameFromLlm: out[i].groupName,
        groups: groups,
        forcedGroupId: forcedGroupId,
      );
      if (gid != null && gid.isNotEmpty) {
        byGroup.putIfAbsent(gid, () => []).add(i);
      }
    }

    for (final e in byGroup.entries) {
      final gid = e.key;
      final tags = tagsByGroupId[gid] ?? const <TagModel>[];
      if (tags.isEmpty) continue;

      final indices = e.value;
      final titles = indices.map((i) => out[i].title).toList();
      final sw = Stopwatch()..start();
      final assigned = await _openRouterTagFallback.assignShoppingTags(
        itemTitles: titles,
        tags: tags,
        transcriptContext: transcript,
      );
      sw.stop();
      await VoicePerfLogger.phase(
        'llm_assign_tags_fallback',
        elapsedMs: sw.elapsedMilliseconds,
        hypothesisId: 'D',
        data: {
          'groupId': gid,
          'itemCount': titles.length,
        },
      );
      for (var j = 0; j < indices.length; j++) {
        final idx = indices[j];
        if (j < assigned.length && assigned[j] != null) {
          out[idx] = out[idx].copyWith(
            tagName: _canonicalTagName(assigned[j], tags),
          );
        }
      }
    }
    return out;
  }

  String? _canonicalTagName(
    String? raw,
    List<TagModel> tags, {
    bool preserveIfMissing = false,
  }) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final id = resolveTagIdByName(trimmed, tags);
    if (id == null) {
      return preserveIfMissing ? trimmed : null;
    }
    return tags.firstWhere((t) => t.id == id).name;
  }

  void dispose() {
    _groq.close();
    _llm.close();
    _openRouterTagFallback?.close();
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
  final List<TaskModel> pendingDatetimeReminderSync;
  final List<String> pendingReminderCancelIds;

  const VoicePersistResult({
    required this.created,
    required this.reopened,
    this.pendingDatetimeReminderSync = const [],
    this.pendingReminderCancelIds = const [],
  });

  int get total => created + reopened;
}

Future<void> runDeferredVoiceReminderSync({
  required NotificationService notification,
  required VoicePersistResult result,
}) async {
  for (final task in result.pendingDatetimeReminderSync) {
    await notification.syncTaskDatetimeReminders(task);
  }
  for (final id in result.pendingReminderCancelIds) {
    await notification.cancelAllTaskReminderSlots(id);
  }
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

class _PersistWorkItem {
  final ExtractedVoiceTaskDto dto;
  final String? groupId;
  final List<String> tagIds;
  final TaskModel? duplicate;

  const _PersistWorkItem({
    required this.dto,
    required this.groupId,
    required this.tagIds,
    this.duplicate,
  });
}

class _PersistOutcome {
  final int created;
  final int reopened;
  final List<TaskModel> pendingSync;
  final List<String> pendingCancel;

  const _PersistOutcome({
    required this.created,
    required this.reopened,
    this.pendingSync = const [],
    this.pendingCancel = const [],
  });
}

Future<VoicePersistResult> persistExtractedVoiceTasksWithDedup({
  required List<ExtractedVoiceTaskDto> dtos,
  required List<GroupModel> groups,
  String? forcedGroupId,
  required FirebaseService firebase,
  required NotificationService notification,
  required Map<String, List<TaskModel>> existingTasksByGroupId,
  required Map<String, List<TagModel>> tagsByGroupId,
  bool deferReminderSync = false,
  int maxConcurrentWrites = 4,
}) async {
  var created = 0;
  var reopened = 0;
  final pendingSync = <TaskModel>[];
  final pendingCancel = <String>[];
  final cache = <String, List<TaskModel>>{
    for (final e in existingTasksByGroupId.entries)
      e.key: List<TaskModel>.from(e.value),
  };

  final work = <_PersistWorkItem>[];
  for (final dto in dtos) {
    final groupId = resolveGroupId(
      groupNameFromLlm: dto.groupName,
      groups: groups,
      forcedGroupId: forcedGroupId,
    );
    final tagIds = _tagIdsForDto(groupId, dto.tagName, tagsByGroupId);
    TaskModel? dup;
    if (groupId != null && groupId.isNotEmpty) {
      dup = findDuplicateGroupTaskByTitle(cache[groupId] ?? [], dto.title);
    }
    work.add(
      _PersistWorkItem(
        dto: dto,
        groupId: groupId,
        tagIds: tagIds,
        duplicate: dup,
      ),
    );
  }

  Future<_PersistOutcome> processOne(_PersistWorkItem item) async {
    final dto = item.dto;
    final groupId = item.groupId;
    final tagIds = item.tagIds;
    final dup = item.duplicate;

    if (dup != null && groupId != null && groupId.isNotEmpty) {
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
      final sync = <TaskModel>[];
      final cancel = <String>[];
      if (deferReminderSync) {
        if (updated.reminderType == 'datetime') {
          sync.add(updated);
        } else {
          cancel.add(updated.id);
        }
      } else if (updated.reminderType == 'datetime') {
        await notification.syncTaskDatetimeReminders(updated);
      } else {
        await notification.cancelAllTaskReminderSlots(updated.id);
      }
      _replaceTaskInCache(cache, updated);
      return _PersistOutcome(
        created: 0,
        reopened: 1,
        pendingSync: sync,
        pendingCancel: cancel,
      );
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
    final sync = <TaskModel>[];
    final cancel = <String>[];
    if (deferReminderSync) {
      if (due.reminderType == 'datetime') {
        sync.add(persisted);
      } else {
        cancel.add(id);
      }
    } else if (due.reminderType == 'datetime') {
      await notification.syncTaskDatetimeReminders(persisted);
    } else {
      await notification.cancelAllTaskReminderSlots(id);
    }
    return _PersistOutcome(
      created: 1,
      reopened: 0,
      pendingSync: sync,
      pendingCancel: cancel,
    );
  }

  for (var i = 0; i < work.length; i += maxConcurrentWrites) {
    final chunk = work.skip(i).take(maxConcurrentWrites).toList();
    final outcomes = await Future.wait(chunk.map(processOne));
    for (final o in outcomes) {
      created += o.created;
      reopened += o.reopened;
      pendingSync.addAll(o.pendingSync);
      pendingCancel.addAll(o.pendingCancel);
    }
  }

  return VoicePersistResult(
    created: created,
    reopened: reopened,
    pendingDatetimeReminderSync: pendingSync,
    pendingReminderCancelIds: pendingCancel,
  );
}

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
