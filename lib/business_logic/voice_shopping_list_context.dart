import 'package:diacritic/diacritic.dart';

/// Indica se o ditado deve tratar títulos como itens de lista de compras (só o produto).
abstract final class VoiceShoppingListContext {
  static final _groupNamePattern = RegExp(
    r'\b(supermercado|mercado|compras|feira|hortifruti|horti|mercearia|lista\s+de\s+compras|lista\s+compras)\b',
    caseSensitive: false,
  );

  static bool isShoppingListGroupName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final norm = removeDiacritics(name.trim().toLowerCase());
    return _groupNamePattern.hasMatch(norm);
  }

  /// Grupo fixo ou de contexto com nome de lista de compras (supermercado, mercado, etc.).
  static bool shouldUseShoppingItemTitles({
    String? forcedGroupName,
    String? contextGroupName,
  }) {
    return isShoppingListGroupName(forcedGroupName) ||
        isShoppingListGroupName(contextGroupName);
  }
}
