import 'package:diacritic/diacritic.dart';

import 'voice_shopping_list_context.dart';

/// Ditado em modo nota: título Área:problema + descrição com polimento leve.
abstract final class VoiceNoteCaptureContext {
  static final _groupNamePattern = RegExp(
    r'\b(melhoria|melhorias|bug|bugs|ideia|ideias|backlog|anotac|anotacao|anotacoes|nota|notas)\b',
    caseSensitive: false,
  );

  static final _narrativePattern = RegExp(
    r'\b(porque|melhoria|bug|quando eu|precisa|problema|anotar|deveria|falta|nao\s+mostra|não\s+mostra)\b',
    caseSensitive: false,
  );

  static final _shoppingListPattern = RegExp(
    r'\b(adiciona|adicione|coloca|coloque|lista|compras?|mercado|supermercado)\b',
    caseSensitive: false,
  );

  static final _listSeparatorPattern = RegExp(
    r'\s+e\s+|\s*,\s*',
    caseSensitive: false,
  );

  static bool isNoteCaptureGroupName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final norm = removeDiacritics(name.trim().toLowerCase());
    return _groupNamePattern.hasMatch(norm);
  }

  static bool looksLikeShoppingListTranscript(String transcript) {
    final t = transcript.trim();
    if (t.isEmpty) return false;
    final hasShoppingCue = _shoppingListPattern.hasMatch(t);
    final separatorHits = _listSeparatorPattern.allMatches(t).length;
    return hasShoppingCue && separatorHits >= 1;
  }

  /// Grupo de notas/melhorias ou fala narrativa longa (fora de lista de compras).
  static bool shouldUseNoteCapture({
    String? forcedGroupName,
    String? contextGroupName,
    required String transcript,
  }) {
    final t = transcript.trim();
    if (t.isEmpty) return false;

    final groupIsNote = isNoteCaptureGroupName(forcedGroupName) ||
        isNoteCaptureGroupName(contextGroupName);
    final groupIsShopping =
        VoiceShoppingListContext.isShoppingListGroupName(forcedGroupName) ||
            VoiceShoppingListContext.isShoppingListGroupName(contextGroupName);

    if (looksLikeShoppingListTranscript(t)) {
      return false;
    }

    if (groupIsNote && !groupIsShopping) {
      return true;
    }

    if (groupIsShopping) {
      return false;
    }

    final wordCount = t.split(RegExp(r'\s+')).length;
    if (wordCount < 18) return false;
    return _narrativePattern.hasMatch(t);
  }
}
