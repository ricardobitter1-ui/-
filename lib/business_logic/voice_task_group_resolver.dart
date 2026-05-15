import 'package:diacritic/diacritic.dart';

import '../data/models/group_model.dart';

String normalizeGroupLabel(String s) =>
    removeDiacritics(s.trim().toLowerCase());

final _groupMentionCue = RegExp(
  r'(?:\b(?:para|pro|pra|no|na|do|da|de|em|grupo)\s+)+',
  caseSensitive: false,
);

/// Quando o LLM não preenche [groupName], tenta achar um grupo citado na fala.
String? inferGroupNameFromTranscript({
  required String transcript,
  required List<GroupModel> groups,
}) {
  final haystack = normalizeGroupLabel(transcript);
  if (haystack.isEmpty || groups.isEmpty) return null;

  String? bestName;
  var bestScore = 0;

  for (final g in groups) {
    final name = g.name.trim();
    if (name.isEmpty) continue;
    final needle = normalizeGroupLabel(name);
    if (needle.length < 2) continue;
    if (!haystack.contains(needle)) continue;

    var score = needle.length;
    final cue = '${_groupMentionCue.pattern}$needle';
    if (RegExp(cue, caseSensitive: false).hasMatch(haystack)) {
      score += 12;
    }
    final wordBoundary = RegExp(r'\b${RegExp.escape(needle)}\b');
    if (wordBoundary.hasMatch(haystack)) {
      score += 6;
    }

    if (score > bestScore) {
      bestScore = score;
      bestName = name;
    } else if (score == bestScore && bestName != null) {
      bestName = null;
    }
  }

  return bestName;
}

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
