import 'package:diacritic/diacritic.dart';

/// Chave derivada do título para buscas e integrações (minúsculas, sem acentos).
String normalizeTitleSearchKey(String title) {
  final t = title.trim();
  if (t.isEmpty) return '';
  return removeDiacritics(t).toLowerCase();
}
