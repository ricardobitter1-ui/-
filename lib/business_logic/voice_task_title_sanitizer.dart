import 'package:diacritic/diacritic.dart';

/// Remove do título fragmentos de data/hora já extraídos para [date]/[time].
abstract final class VoiceTaskTitleSanitizer {
  static final _patterns = [
    RegExp(
      r'\b(hoje|amanha|depois de amanha)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:às|as|a)\s*\d{1,2}(?:[:h]\d{2})?\s*(?:h|horas?)?(?:\s+(?:da|de)\s+manha)?',
      caseSensitive: false,
    ),
    RegExp(r'\b\d{1,2}[:h]\d{2}\b', caseSensitive: false),
    RegExp(
      r'(?:,?\s*)?(?:da|de)\s+(?:manha|tarde|noite)\b',
      caseSensitive: false,
    ),
  ];

  static final _trailingPunctuation = RegExp(r'[\s,;.\-–—]+$');
  static final _leadingPunctuation = RegExp(r'^[\s,;.\-–—]+');
  static final _multiSpace = RegExp(r'\s+');

  static String sanitize(
    String title, {
    bool stripDateHints = true,
    bool stripTimeHints = true,
  }) {
    var t = title.trim();
    if (t.isEmpty) return t;

    if (stripDateHints || stripTimeHints) {
      t = _stripWithPatterns(
        t,
        patterns: _patterns.where((p) {
          final src = p.pattern;
          if (!stripDateHints && src.contains('hoje|amanha')) return false;
          if (!stripTimeHints &&
              (src.contains(r'\d') || src.contains('manha|tarde'))) {
            return false;
          }
          return true;
        }).toList(),
      );
    }

    t = t.replaceAll(_multiSpace, ' ').trim();
    t = t.replaceAll(_leadingPunctuation, '');
    t = t.replaceAll(_trailingPunctuation, '');
    if (t.isEmpty) return title.trim();

    return _capitalizeFirst(t);
  }

  static String _stripWithPatterns(
    String text, {
    required List<RegExp> patterns,
  }) {
    var out = text;
    var norm = removeDiacritics(out);
    for (final pattern in patterns) {
      var match = pattern.firstMatch(norm);
      while (match != null) {
        out = out.replaceRange(match.start, match.end, '');
        norm = removeDiacritics(out);
        match = pattern.firstMatch(norm);
      }
    }
    return out;
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
