import 'voice_note_capture_context.dart';
import 'voice_shopping_list_context.dart';

/// Modo de extração escolhido antes de chamar o LLM.
enum VoiceExtractMode {
  /// Lista de compras / vários itens no grupo.
  shoppingOrGeneral,

  /// Nota ou melhoria: título Área:problema + descrição polida.
  noteCapture,

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

  static VoiceIntentClassification classify({
    required String transcript,
    required bool hasForcedGroup,
    String? contextGroupName,
    String? forcedGroupName,
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

    final isShoppingGroup = VoiceShoppingListContext.shouldUseShoppingItemTitles(
      forcedGroupName: forcedGroupName,
      contextGroupName: contextGroupName,
    );
    final isNoteCapture = VoiceNoteCaptureContext.shouldUseNoteCapture(
      forcedGroupName: forcedGroupName,
      contextGroupName: contextGroupName,
      transcript: t,
    );
    final looksLikeShoppingList =
        VoiceNoteCaptureContext.looksLikeShoppingListTranscript(t);

    // 1. Lembrete claro (prioridade sobre nota no mesmo áudio curto).
    if (hasReminder &&
        !hasShoppingCue &&
        wordCount <= 24 &&
        separatorHits < 2) {
      return const VoiceIntentClassification(
        mode: VoiceExtractMode.reminder,
        intentLabel: 'reminder_fast',
      );
    }

    // 2. Nota / melhoria (grupo ou narrativa longa).
    if (isNoteCapture) {
      return const VoiceIntentClassification(
        mode: VoiceExtractMode.noteCapture,
        intentLabel: 'note_llm',
      );
    }

    // 3. Lista de compras (grupo supermercado ou fala de produtos).
    if (isShoppingGroup &&
        (hasShoppingCue || looksLikeShoppingList || separatorHits >= 1)) {
      return const VoiceIntentClassification(
        mode: VoiceExtractMode.shoppingOrGeneral,
        intentLabel: 'shopping_llm',
      );
    }

    // 4. Grupo fixo sem nota nem compras → general (não assumir shopping).
    if (hasForcedGroup) {
      return const VoiceIntentClassification(
        mode: VoiceExtractMode.shoppingOrGeneral,
        intentLabel: 'forced_group_general',
      );
    }

    // 5. Home: lista longa ou muitos separadores.
    if (separatorHits >= 2 || wordCount > 28) {
      if (hasShoppingCue || looksLikeShoppingList) {
        return const VoiceIntentClassification(
          mode: VoiceExtractMode.shoppingOrGeneral,
          intentLabel: 'shopping_llm',
        );
      }
      if (VoiceNoteCaptureContext.shouldUseNoteCapture(
        forcedGroupName: forcedGroupName,
        contextGroupName: contextGroupName,
        transcript: t,
      )) {
        return const VoiceIntentClassification(
          mode: VoiceExtractMode.noteCapture,
          intentLabel: 'note_llm',
        );
      }
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
