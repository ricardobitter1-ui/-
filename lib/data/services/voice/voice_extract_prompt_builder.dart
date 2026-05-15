import 'dart:convert';

import '../../../business_logic/voice_intent_router.dart';
import '../../../constants/voice_task_extraction_prompt.dart';
import 'voice_extract_request.dart';

abstract final class VoiceExtractPromptBuilder {
  static String systemPromptFor(VoiceExtractMode mode) {
    switch (mode) {
      case VoiceExtractMode.reminder:
        return kVoiceReminderExtractionSystemPrompt;
      case VoiceExtractMode.reminderHeuristic:
      case VoiceExtractMode.shoppingOrGeneral:
        return kVoiceTaskExtractionSystemPrompt;
    }
  }

  static String buildUserContent(VoiceExtractRequest req) {
    final groupsJson = jsonEncode(req.effectiveGroupNames);
    final contextLine =
        req.contextGroupName != null && req.contextGroupName!.trim().isNotEmpty
            ? 'Grupo de contexto do ecrã (usa este groupName quando o utilizador não disser outro e for lista de itens nesse grupo): "${req.contextGroupName!.trim()}"\n'
            : '';
    final forcedLine = req.forcedGroupName != null &&
            req.forcedGroupName!.trim().isNotEmpty
        ? 'Grupo fixo do ecrã (usa sempre este groupName para itens de compra): "${req.forcedGroupName!.trim()}"\n'
        : '';

    final tags = req.effectiveTagsByGroupName;
    final tagsLine = tags.isEmpty
        ? ''
        : 'Etiquetas por grupo (tagName exacto de uma destas listas ou null):\n${jsonEncode(tags)}\n';

    return '''
Data de referência (hoje no dispositivo): ${req.referenceDate}
$contextLine$forcedLine
Grupos existentes (usa exactamente um destes nomes em groupName ou null): $groupsJson
$tagsLine
Texto transcrito:
${req.transcript}
''';
  }
}
