import 'package:diacritic/diacritic.dart';

import '../data/models/group_model.dart';

String normalizeGroupLabel(String s) =>
    removeDiacritics(s.trim().toLowerCase());

/// Resolve o nome devolvido pelo LLM para um [GroupModel.id], com fallbacks.
String? resolveGroupId({
  required String? groupNameFromLlm,
  required List<GroupModel> groups,
  String? forcedGroupId,
}) {
  final trimmed = groupNameFromLlm?.trim();
  if (trimmed == null || trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
    final f = forcedGroupId?.trim();
    if (f != null && f.isNotEmpty) return f;
    return null;
  }

  final target = normalizeGroupLabel(trimmed);
  GroupModel? exactMatch;
  var duplicateExact = false;
  for (final g in groups) {
    if (normalizeGroupLabel(g.name) == target) {
      if (exactMatch != null) {
        duplicateExact = true;
        break;
      }
      exactMatch = g;
    }
  }
  if (!duplicateExact && exactMatch != null) return exactMatch.id;

  final ff = forcedGroupId?.trim();
  if (ff != null && ff.isNotEmpty) return ff;

  // Fallback fuzzy: substring só se único candidato
  final candidates = <GroupModel>[];
  for (final g in groups) {
    final n = normalizeGroupLabel(g.name);
    if (n.contains(target) || target.contains(n)) {
      candidates.add(g);
    }
  }
  if (candidates.length == 1) return candidates.single.id;

  return null;
}
