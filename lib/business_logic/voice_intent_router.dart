/// Modo de extração escolhido antes de chamar o LLM.
enum VoiceExtractMode {
  /// Lista de compras / vários itens no grupo.
  shoppingOrGeneral,

  /// Lembrete com data/hora — prompt enxuto ou heurística.
  reminder,

  /// Heurística local aplicada (sem LLM nesta fase).
  reminderHeuristic,
}

/// Resultado da classificação do texto transcrito.
class VoiceIntentClassification {
  final VoiceExtractMode mode;
  final String intentLabel;

  const VoiceIntentClassification({
    required this.mode,
    required this.intentLabel,
  });
}

abstract final class VoiceIntentRouter {
  static final _reminderPattern = RegExp(
    r'lembr|lembrete|me\s+lemb|avisa|alerta',
    caseSensitive: false,
  );

  static final _shoppingPattern = RegExp(
    r'\b(adiciona|adicione|coloca|coloque|lista|compras?|mercado|supermercado)\b',
    caseSensitive: false,
  );

  static final _listSeparatorPattern = RegExp(
    r'\s+e\s+|\s*,\s*',
    caseSensitive: false,
  );

  /// [hasForcedGroup] ditado aberto dentro de um grupo (lista de compras).
  static VoiceIntentClassification classify({
    required String transcript,
    required bool hasForcedGroup,
    String? contextGroupName,
  }) {
    final t = transcript.trim();
    if (t.isEmpty) {
      return const VoiceIntentClassification(
        mode: VoiceExtractMode.shoppingOrGeneral,
        intentLabel: 'empty',
      );
    }

    final wordCount = t.split(RegExp(r'\s+')).length;
    final hasReminder = _reminderPattern.hasMatch(t);
    final hasShoppingCue = _shoppingPattern.hasMatch(t);
    final separatorHits = _listSeparatorPattern.allMatches(t).length;

    if (hasForcedGroup || (contextGroupName != null && hasShoppingCue)) {
      return const VoiceIntentClassification(
        mode: VoiceExtractMode.shoppingOrGeneral,
        intentLabel: 'shopping_llm',
      );
    }

    if (hasReminder &&
        !hasShoppingCue &&
        wordCount <= 24 &&
        separatorHits < 2) {
      return const VoiceIntentClassification(
        mode: VoiceExtractMode.reminder,
        intentLabel: 'reminder_fast',
      );
    }

    if (separatorHits >= 2 || wordCount > 28) {
      return const VoiceIntentClassification(
        mode: VoiceExtractMode.shoppingOrGeneral,
        intentLabel: 'shopping_llm',
      );
    }

    return const VoiceIntentClassification(
      mode: VoiceExtractMode.shoppingOrGeneral,
      intentLabel: 'general_llm',
    );
  }
}
