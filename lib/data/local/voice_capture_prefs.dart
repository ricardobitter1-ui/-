import 'package:shared_preferences/shared_preferences.dart';

const String kVoiceConfirmBeforeSaveKey = 'voice_confirm_before_save';

/// Se true (padrão), mostra resumo editável antes de gravar ditado.
Future<bool> loadVoiceConfirmBeforeSave() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(kVoiceConfirmBeforeSaveKey) ?? true;
}

Future<void> saveVoiceConfirmBeforeSave(bool value) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kVoiceConfirmBeforeSaveKey, value);
}
