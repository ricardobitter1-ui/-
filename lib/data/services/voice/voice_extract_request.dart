import '../../../business_logic/voice_intent_router.dart';

/// Pedido de extração de tarefas a partir de texto transcrito.
class VoiceExtractRequest {
  final String transcript;
  final List<String> groupNames;
  final String referenceDate;
  final String? contextGroupName;
  final Map<String, List<String>> tagsByGroupName;
  /// Quando o ditado é aberto dentro de um grupo: só esse nome no prompt.
  final String? forcedGroupName;
  final VoiceExtractMode mode;

  const VoiceExtractRequest({
    required this.transcript,
    required this.groupNames,
    required this.referenceDate,
    this.contextGroupName,
    this.tagsByGroupName = const {},
    this.forcedGroupName,
    this.mode = VoiceExtractMode.shoppingOrGeneral,
  });

  List<String> get effectiveGroupNames {
    final forced = forcedGroupName?.trim();
    if (forced != null && forced.isNotEmpty) return [forced];
    return groupNames;
  }

  Map<String, List<String>> get effectiveTagsByGroupName {
    final forced = forcedGroupName?.trim();
    if (forced == null || forced.isEmpty) return tagsByGroupName;
    final tags = tagsByGroupName[forced];
    if (tags == null) return {};
    return {forced: tags};
  }
}
