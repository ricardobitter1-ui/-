import 'package:intl/intl.dart';

/// Rótulo do badge de data/hora e se a tarefa está atrasada.
///
/// Atrasada = instante do prazo já passou: dias anteriores ou hoje com horário antes de [now].
class ScheduledBadgeData {
  final String label;
  final bool isOverdue;

  const ScheduledBadgeData({
    required this.label,
    required this.isOverdue,
  });
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Prazo [due] (data/hora local) já passou em relação a [now]. Alinha badge vermelho e lista Atrasadas.
bool isDueDateTimePast(DateTime due, DateTime now) => due.isBefore(now);

/// [firstDayOfWeekIndex] como em [MaterialLocalizations.firstDayOfWeekIndex]: 0 = domingo, 1 = segunda.
int _weekStartsOnWeekday(int firstDayOfWeekIndex) {
  if (firstDayOfWeekIndex == 0) return DateTime.sunday;
  return DateTime.monday;
}

DateTime _startOfWeekContaining(DateTime day, int weekStartsOnWeekday) {
  final d = _dateOnly(day);
  final diff = (d.weekday - weekStartsOnWeekday + 7) % 7;
  return d.subtract(Duration(days: diff));
}

bool _sameCalendarWeek(
  DateTime a,
  DateTime b,
  int firstDayOfWeekIndex,
) {
  final w = _weekStartsOnWeekday(firstDayOfWeekIndex);
  final sa = _startOfWeekContaining(a, w);
  final sb = _startOfWeekContaining(b, w);
  return sa.year == sb.year && sa.month == sb.month && sa.day == sb.day;
}

const _weekdayNamesPt = [
  'segunda',
  'terça',
  'quarta',
  'quinta',
  'sexta',
  'sábado',
  'domingo',
];

/// Formata o texto do badge de agendamento em pt_BR.
ScheduledBadgeData formatScheduledBadge({
  required DateTime due,
  required DateTime now,
  required int firstDayOfWeekIndex,
}) {
  final dueD = _dateOnly(due);
  final nowD = _dateOnly(now);
  final timeStr = DateFormat.Hm('pt_BR').format(due);

  if (dueD.isBefore(nowD)) {
    final days = nowD.difference(dueD).inDays;
    final label = days == 1 ? 'há 1 dia' : 'há $days dias';
    return ScheduledBadgeData(label: label, isOverdue: true);
  }

  if (dueD == nowD) {
    if (due.isBefore(now)) {
      return ScheduledBadgeData(label: 'hoje, $timeStr', isOverdue: true);
    }
    return ScheduledBadgeData(label: 'hoje, $timeStr', isOverdue: false);
  }

  final tomorrow = nowD.add(const Duration(days: 1));
  if (dueD == tomorrow) {
    return ScheduledBadgeData(label: 'amanhã, $timeStr', isOverdue: false);
  }

  final dayAfterTomorrow = nowD.add(const Duration(days: 2));
  if (dueD == dayAfterTomorrow) {
    return ScheduledBadgeData(
      label: 'depois de amanhã, $timeStr',
      isOverdue: false,
    );
  }

  if (_sameCalendarWeek(due, now, firstDayOfWeekIndex) &&
      dueD.isAfter(dayAfterTomorrow)) {
    final name = _weekdayNamesPt[due.weekday - 1];
    return ScheduledBadgeData(label: '$name, $timeStr', isOverdue: false);
  }

  final df = DateFormat('d MMM', 'pt_BR');
  var datePart = df.format(due);
  if (due.year != now.year) {
    datePart = '$datePart ${due.year}';
  }
  return ScheduledBadgeData(label: '$datePart, $timeStr', isOverdue: false);
}
