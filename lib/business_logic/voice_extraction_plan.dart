import 'package:diacritic/diacritic.dart';

import '../data/models/extracted_voice_task_dto.dart';
import '../data/models/group_model.dart';
import '../data/models/tag_model.dart';
import '../data/services/firebase_service.dart';
import 'voice_tag_resolver.dart';
import 'voice_task_group_resolver.dart';

/// Cor padrão para etiquetas criadas via ditado.
const int kDefaultVoiceTagColor = 0xFF1E88E5;

/// Etiqueta nova a criar antes de persistir tarefas do ditado.
class VoiceTagToCreate {
  final String name;
  final String groupId;
  final String groupName;
  final int color;

  const VoiceTagToCreate({
    required this.name,
    required this.groupId,
    required this.groupName,
    required this.color,
  });

  VoiceTagToCreate copyWith({
    String? name,
    String? groupId,
    String? groupName,
    int? color,
  }) {
    return VoiceTagToCreate(
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      color: color ?? this.color,
    );
  }

  String get dedupeKey =>
      '${groupId.trim()}\u0000${removeDiacritics(name.trim().toLowerCase())}';
}

/// Plano editável antes de gravar o resultado do ditado.
class VoiceExtractionPlan {
  final List<ExtractedVoiceTaskDto> tasks;
  final List<VoiceTagToCreate> tagsToCreate;

  const VoiceExtractionPlan({
    required this.tasks,
    this.tagsToCreate = const [],
  });

  VoiceExtractionPlan copyWith({
    List<ExtractedVoiceTaskDto>? tasks,
    List<VoiceTagToCreate>? tagsToCreate,
  }) {
    return VoiceExtractionPlan(
      tasks: tasks ?? this.tasks,
      tagsToCreate: tagsToCreate ?? this.tagsToCreate,
    );
  }

  bool get isEmpty => tasks.isEmpty;
}

String _tagDedupeKey(String groupId, String tagName) =>
    '${groupId.trim()}\u0000${removeDiacritics(tagName.trim().toLowerCase())}';

/// Monta o plano a partir das tarefas enriquecidas (tags explícitas inexistentes).
VoiceExtractionPlan buildVoiceExtractionPlan({
  required List<ExtractedVoiceTaskDto> tasks,
  required List<GroupModel> groups,
  String? forcedGroupId,
  required Map<String, List<TagModel>> tagsByGroupId,
}) {
  final tagsToCreate = <VoiceTagToCreate>[];
  final seen = <String>{};

  for (final dto in tasks) {
    final tagName = dto.tagName?.trim();
    if (!dto.tagExplicit || tagName == null || tagName.isEmpty) continue;

    final groupId = resolveGroupId(
      groupNameFromLlm: dto.groupName,
      groups: groups,
      forcedGroupId: forcedGroupId,
    );
    if (groupId == null || groupId.isEmpty) continue;

    final existing = tagsByGroupId[groupId] ?? const <TagModel>[];
    if (resolveTagIdByName(tagName, existing) != null) continue;

    final key = _tagDedupeKey(groupId, tagName);
    if (seen.contains(key)) continue;
    seen.add(key);

    String? groupName;
    for (final g in groups) {
      if (g.id == groupId) {
        groupName = g.name;
        break;
      }
    }

    tagsToCreate.add(
      VoiceTagToCreate(
        name: tagName,
        groupId: groupId,
        groupName: groupName ?? '',
        color: kDefaultVoiceTagColor,
      ),
    );
  }

  return VoiceExtractionPlan(
    tasks: List<ExtractedVoiceTaskDto>.from(tasks),
    tagsToCreate: tagsToCreate,
  );
}

/// Canonicaliza tagName de cada tarefa contra etiquetas existentes.
List<ExtractedVoiceTaskDto> canonicalizeTaskTagNames({
  required List<ExtractedVoiceTaskDto> tasks,
  required List<GroupModel> groups,
  String? forcedGroupId,
  required Map<String, List<TagModel>> tagsByGroupId,
}) {
  return tasks.map((dto) {
    final gid = resolveGroupId(
      groupNameFromLlm: dto.groupName,
      groups: groups,
      forcedGroupId: forcedGroupId,
    );
    final tags =
        gid == null ? const <TagModel>[] : (tagsByGroupId[gid] ?? const []);
    final raw = dto.tagName?.trim();
    if (raw == null || raw.isEmpty) return dto.copyWith(tagName: null);

    final id = resolveTagIdByName(raw, tags);
    if (id != null) {
      final canonical = tags.firstWhere((t) => t.id == id).name;
      return dto.copyWith(tagName: canonical);
    }
    if (dto.tagExplicit) {
      return dto.copyWith(tagName: raw);
    }
    return dto.copyWith(tagName: null);
  }).toList();
}

/// Cria etiquetas planeadas e devolve mapa actualizado por groupId.
Future<Map<String, List<TagModel>>> createPlannedVoiceTags({
  required List<VoiceTagToCreate> tagsToCreate,
  required FirebaseService firebase,
  required Map<String, List<TagModel>> tagsByGroupId,
}) async {
  final out = <String, List<TagModel>>{
    for (final e in tagsByGroupId.entries)
      e.key: List<TagModel>.from(e.value),
  };

  for (final planned in tagsToCreate) {
    final name = planned.name.trim();
    if (name.isEmpty) continue;

    final list = out.putIfAbsent(planned.groupId, () => <TagModel>[]);
    if (resolveTagIdByName(name, list) != null) continue;

    final id = await firebase.addGroupTag(
      groupId: planned.groupId,
      name: name,
      color: planned.color,
    );
    list.add(
      TagModel(
        id: id,
        groupId: planned.groupId,
        name: name,
        color: planned.color,
      ),
    );
    list.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  return out;
}
