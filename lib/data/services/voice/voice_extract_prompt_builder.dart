import 'dart:convert';

import '../../../business_logic/voice_intent_router.dart';
import '../../../constants/voice_task_extraction_prompt.dart';
import 'voice_extract_request.dart';

abstract final class VoiceExtractPromptBuilder {
  static String systemPromptFor(VoiceExtractRequest req) {
    switch (req.mode) {
      case VoiceExtractMode.reminder:
        return kVoiceReminderExtractionSystemPrompt;
      case VoiceExtractMode.noteCapture:
        return kVoiceNoteCaptureExtractionSystemPrompt;
      case VoiceExtractMode.reminderHeuristic:
      case VoiceExtractMode.shoppingOrGeneral:
        return req.shoppingListItemTitles
            ? kVoiceShoppingListExtractionSystemPrompt
            : kVoiceTaskExtractionSystemPrompt;
    }
  }

  static String buildUserContent(VoiceExtractRequest req) {
    final groupsJson = jsonEncode(req.effectiveGroupNames);
    final contextLine =
        req.contextGroupName != null && req.contextGroupName!.trim().isNotEmpty
            ? 'Grupo de contexto do ecrã (usa este groupName quando o utilizador não disser outro e for lista de itens nesse grupo): "${req.contextGroupName!.trim()}"\n'
            : '';
    final isNote = req.mode == VoiceExtractMode.noteCapture;
    final forcedLine = req.forcedGroupName != null &&
            req.forcedGroupName!.trim().isNotEmpty
        ? isNote
            ? 'Grupo fixo do ecrã (usa sempre este groupName): "${req.forcedGroupName!.trim()}"\n'
            : 'Grupo fixo do ecrã (usa sempre este groupName para itens de compra): "${req.forcedGroupName!.trim()}"\n'
        : '';

    final tags = req.effectiveTagsByGroupName;
    final tagsLine = tags.isEmpty
        ? ''
        : 'Etiquetas por grupo (tagName exacto de uma destas listas ou null):\n${jsonEncode(tags)}\n';
    final shoppingLine = req.shoppingListItemTitles
        ? 'Modo lista de compras: cada "title" = só o nome do produto (ex.: "Arroz"), nunca verbos como "comprar" ou "pegar".\n'
        : '';
    final noteLine = isNote
        ? 'Modo nota: "title" = Área: problema; "description" = texto sucinto polido (1-4 frases), sem inventar factos.\n'
        : '';
    final tagHintLine = tags.isNotEmpty && !req.shoppingListItemTitles
        ? 'Se eu pedir explicitamente uma tag/categoria/etiqueta, preenche tagName e tagExplicit=true. '
            'Se o nome já estiver em "Etiquetas por grupo", liga com tagExplicit=true ou false; '
            'se não existir mas eu pedi, tagExplicit=true.\n'
        : '';

    return '''
Data de referência (hoje no dispositivo): ${req.referenceDate}
$noteLine$shoppingLine$tagHintLine$contextLine$forcedLine
Grupos existentes (usa exactamente um destes nomes em groupName ou null): $groupsJson
$tagsLine
Texto transcrito:
${req.transcript}
''';
  }
}
