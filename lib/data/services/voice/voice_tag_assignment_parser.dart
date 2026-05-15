import 'dart:convert';

import '../../models/tag_model.dart';
import '../../../utils/title_search_key.dart';

/// Interpreta JSON de atribuição de etiquetas (legado / fallback LLM).
abstract final class VoiceTagAssignmentParser {
  static List<String?> parseTagAssignmentsResponse(
    String raw,
    int expectedCount,
    List<TagModel> allowedTags,
    List<String> itemTitles,
  ) {
    final trimmed = raw.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return List<String?>.filled(expectedCount, null);
    }
    final decoded = jsonDecode(trimmed.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) {
      return List<String?>.filled(expectedCount, null);
    }
    final arr = decoded['assignments'];
    if (arr is! List) {
      return List<String?>.filled(expectedCount, null);
    }

    final allowedNames = {
      for (final t in allowedTags) normalizeTitleSearchKey(t.name): t.name,
    };

    String? canonicalTagName(String? rawName) {
      if (rawName == null) return null;
      final s = rawName.trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return allowedNames[normalizeTitleSearchKey(s)];
    }

    final byNormTitle = <String, String?>{};
    for (final e in arr) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final title = (m['title'] ?? m['titulo'])?.toString().trim() ?? '';
      if (title.isEmpty) continue;
      final tn = m['tagName'] ?? m['tag'];
      final tagStr = tn?.toString().trim();
      byNormTitle[normalizeTitleSearchKey(title)] =
          canonicalTagName(tagStr);
    }

    final out = <String?>[];
    for (final t in itemTitles) {
      out.add(byNormTitle[normalizeTitleSearchKey(t)]);
    }
    while (out.length < expectedCount) {
      out.add(null);
    }
    if (out.length > expectedCount) {
      return out.sublist(0, expectedCount);
    }
    return out;
  }
}
