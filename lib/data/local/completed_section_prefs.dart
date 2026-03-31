import 'package:shared_preferences/shared_preferences.dart';

/// Chaves [SharedPreferences] para o bloco colapsável "Concluídas".
///
/// - [hojeInboxSemData]: aba Hoje, lista **Sem data** (inbox).
/// - [hojeDiaSelecionado]: aba Hoje, lista **Neste dia** (data do calendário).
/// - [groupDetail]: detalhe de grupo — use [groupDetail] com `group.id`.
abstract final class CompletedSectionPrefsKeys {
  static const String hojeInboxSemData =
      'completed_section_expanded_hoje_inbox';
  static const String hojeDiaSelecionado =
      'completed_section_expanded_hoje_day';

  /// `completed_section_expanded_group_<groupId>`
  static String groupDetail(String groupId) =>
      'completed_section_expanded_group_$groupId';
}

Future<bool> loadCompletedSectionExpanded(String key) async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(key) ?? true;
}

Future<void> saveCompletedSectionExpanded(String key, bool value) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(key, value);
}
