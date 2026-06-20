import 'package:shared_preferences/shared_preferences.dart';

/// Padrão: repetir a cada 30 minutos (comportamento anterior).
const int kDefaultPendingReminderRepeatSeconds = 30 * 60;

/// Use 0 para desativar os lembretes repetidos de tarefas pendentes.
/// Valores em segundos (30 s facilita testes; demais equivalem às opções em minutos).
const List<int> kPendingReminderRepeatSecondOptions = [
  0,
  30,
  5 * 60,
  15 * 60,
  30 * 60,
  60 * 60,
];

abstract final class PendingReminderPrefsKeys {
  static const String repeatSeconds = 'pending_reminder_repeat_seconds';
  /// Chave antiga (minutos); lida uma vez na migração e removida.
  static const String repeatMinutes = 'pending_reminder_repeat_minutes';
}

int normalizePendingReminderRepeatSeconds(int? value) {
  if (value == null) return kDefaultPendingReminderRepeatSeconds;
  if (kPendingReminderRepeatSecondOptions.contains(value)) return value;
  return kDefaultPendingReminderRepeatSeconds;
}

String pendingReminderRepeatLabel(int seconds) {
  if (seconds == 0) return 'Desativado';
  if (seconds == 60 * 60) return '1 hora';
  if (seconds < 60) return '$seconds segundos';
  final m = seconds ~/ 60;
  return '$m minutos';
}

Future<int> loadPendingReminderRepeatSeconds() async {
  final p = await SharedPreferences.getInstance();

  if (p.containsKey(PendingReminderPrefsKeys.repeatSeconds)) {
    return normalizePendingReminderRepeatSeconds(
      p.getInt(PendingReminderPrefsKeys.repeatSeconds),
    );
  }

  final legacyMinutes = p.getInt(PendingReminderPrefsKeys.repeatMinutes);
  final migrated = legacyMinutes == null
      ? kDefaultPendingReminderRepeatSeconds
      : normalizePendingReminderRepeatSeconds(legacyMinutes * 60);

  await p.setInt(PendingReminderPrefsKeys.repeatSeconds, migrated);
  await p.remove(PendingReminderPrefsKeys.repeatMinutes);
  return migrated;
}

Future<Duration?> loadPendingReminderRepeatInterval() async {
  final seconds = await loadPendingReminderRepeatSeconds();
  if (seconds == 0) return null;
  return Duration(seconds: seconds);
}

Future<void> savePendingReminderRepeatSeconds(int seconds) async {
  final p = await SharedPreferences.getInstance();
  final normalized = normalizePendingReminderRepeatSeconds(seconds);
  await p.setInt(PendingReminderPrefsKeys.repeatSeconds, normalized);
  await p.remove(PendingReminderPrefsKeys.repeatMinutes);
}

/// Máximo de alarmes discretos para repetição pendente até [untilExclusive].
int maxPendingReminderDiscreteRepeats({
  required DateTime nextFire,
  required DateTime? untilExclusive,
  required Duration repeatInterval,
  required int slotsRemaining,
}) {
  if (repeatInterval.inMilliseconds <= 0 || slotsRemaining <= 0) return 0;
  if (untilExclusive == null) return slotsRemaining;
  if (!nextFire.isBefore(untilExclusive)) return 0;
  final remainingMs = untilExclusive.difference(nextFire).inMilliseconds;
  if (remainingMs <= 0) return 0;
  final count = (remainingMs / repeatInterval.inMilliseconds).ceil();
  return count.clamp(1, slotsRemaining);
}
