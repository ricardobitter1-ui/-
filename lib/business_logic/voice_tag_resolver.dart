import 'package:diacritic/diacritic.dart';

import '../data/models/tag_model.dart';

String _norm(String s) => removeDiacritics(s.trim().toLowerCase());

/// Devolve o id da etiqueta cujo nome coincide (normalizado) com [tagName], ou null.
String? resolveTagIdByName(String? tagName, List<TagModel> tags) {
  final t = tagName?.trim();
  if (t == null || t.isEmpty) return null;
  final key = _norm(t);
  for (final tag in tags) {
    if (_norm(tag.name) == key) return tag.id;
  }
  return null;
}
