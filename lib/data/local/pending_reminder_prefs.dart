import 'package:shared_preferences/shared_preferences.dart';

const int kDefaultPendingReminderRepeatMinutes = 30;

/// Use 0 para desativar os lembretes repetidos de tarefas pendentes.
const List<int> kPendingReminderRepeatMinuteOptions = [0, 5, 15, 30, 60];

abstract final class PendingReminderPrefsKeys {
  static const String repeatMinutes = 'pending_reminder_repeat_minutes';
}

int normalizePendingReminderRepeatMinutes(int? value) {
  if (value == null) return kDefaultPendingReminderRepeatMinutes;
  if (kPendingReminderRepeatMinuteOptions.contains(value)) return value;
  return kDefaultPendingReminderRepeatMinutes;
}

String pendingReminderRepeatLabel(int minutes) {
  if (minutes == 0) return 'Desativado';
  if (minutes == 60) return '1 hora';
  return '$minutes minutos';
}

Future<int> loadPendingReminderRepeatMinutes() async {
  final p = await SharedPreferences.getInstance();
  return normalizePendingReminderRepeatMinutes(
    p.getInt(PendingReminderPrefsKeys.repeatMinutes),
  );
}

Future<Duration?> loadPendingReminderRepeatInterval() async {
  final minutes = await loadPendingReminderRepeatMinutes();
  if (minutes == 0) return null;
  return Duration(minutes: minutes);
}

Future<void> savePendingReminderRepeatMinutes(int minutes) async {
  final p = await SharedPreferences.getInstance();
  await p.setInt(
    PendingReminderPrefsKeys.repeatMinutes,
    normalizePendingReminderRepeatMinutes(minutes),
  );
}
