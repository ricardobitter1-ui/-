import 'package:diacritic/diacritic.dart';

import '../data/models/group_model.dart';
import '../data/models/group_type.dart';

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

  static bool isContinuousGroup(GroupModel? group) {
    return group?.type == GroupType.continuous;
  }

  /// Preferência: tipo do grupo; fallback legado por nome (migração).
  static bool shouldUseShoppingItemTitles({
    GroupModel? forcedGroup,
    GroupModel? contextGroup,
    String? forcedGroupName,
    String? contextGroupName,
  }) {
    if (isContinuousGroup(forcedGroup) || isContinuousGroup(contextGroup)) {
      return true;
    }
    return isShoppingListGroupName(forcedGroupName) ||
        isShoppingListGroupName(contextGroupName);
  }
}
