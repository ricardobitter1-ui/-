import '../data/models/task_recurrence.dart';

/// Calcula instantes de ocorrência para lembretes locais.
class RecurrenceCalculator {
  RecurrenceCalculator._();

  static DateTime _atTimeOnDate(
    DateTime date,
    TaskRecurrenceRule rule, {
    int? dueTimeHour,
    int? dueTimeMinute,
  }) {
    final h = rule.repeatHour ?? dueTimeHour ?? 0;
    final m = rule.repeatMinute ?? dueTimeMinute ?? 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  static DateTime _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static DateTime _mondayOfWeek(DateTime d) {
    final day = _startOfDay(d);
    final wd = day.weekday;
    return day.subtract(Duration(days: wd - 1));
  }

  static int _lastDayOfMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static DateTime _monthlyDate(int year, int month, int preferredDay) {
    final last = _lastDayOfMonth(year, month);
    final day = preferredDay > last ? last : preferredDay;
    return DateTime(year, month, day);
  }

  /// [indexOneBased] = n-ésima ocorrência da série a contar do início (âncora).
  static bool _allowsOccurrence(
    DateTime occurrence,
    TaskRecurrenceRule rule,
    int indexOneBased,
  ) {
    switch (rule.endType) {
      case RecurrenceEndType.never:
        return true;
      case RecurrenceEndType.untilDate:
        if (rule.endDate == null) return true;
        final end = _startOfDay(rule.endDate!);
        return !_startOfDay(occurrence).isAfter(end);
      case RecurrenceEndType.afterCount:
        final max = rule.maxOccurrences;
        if (max == null || max < 1) return true;
        return indexOneBased <= max;
    }
  }

  /// Próximas ocorrências com instante >= [from], no máximo [maxCount] itens.
  static List<DateTime> upcomingOccurrences({
    required DateTime anchorDate,
    required TaskRecurrenceRule rule,
    DateTime? from,
    int? dueTimeHour,
    int? dueTimeMinute,
    int maxCount = 64,
  }) {
    final start = from ?? DateTime.now();
    final interval = rule.interval < 1 ? 1 : rule.interval;

    switch (rule.unit) {
      case RecurrenceUnit.day:
        return _daily(
          anchorDate: anchorDate,
          rule: rule,
          interval: interval,
          start: start,
          maxCount: maxCount,
          dueTimeHour: dueTimeHour,
          dueTimeMinute: dueTimeMinute,
        );
      case RecurrenceUnit.week:
        return _weekly(
          anchorDate: anchorDate,
          rule: rule,
          interval: interval,
          start: start,
          maxCount: maxCount,
          dueTimeHour: dueTimeHour,
          dueTimeMinute: dueTimeMinute,
        );
      case RecurrenceUnit.month:
        return _monthly(
          anchorDate: anchorDate,
          rule: rule,
          interval: interval,
          start: start,
          maxCount: maxCount,
          dueTimeHour: dueTimeHour,
          dueTimeMinute: dueTimeMinute,
        );
      case RecurrenceUnit.year:
        return _yearly(
          anchorDate: anchorDate,
          rule: rule,
          interval: interval,
          start: start,
          maxCount: maxCount,
          dueTimeHour: dueTimeHour,
          dueTimeMinute: dueTimeMinute,
        );
    }
  }

  static List<DateTime> _daily({
    required DateTime anchorDate,
    required TaskRecurrenceRule rule,
    required int interval,
    required DateTime start,
    required int maxCount,
    int? dueTimeHour,
    int? dueTimeMinute,
  }) {
    final results = <DateTime>[];
    var day = _startOfDay(anchorDate);
    var seriesIndex = 0;

    for (var guard = 0; guard < 4000 && results.length < maxCount; guard++) {
      seriesIndex++;
      if (rule.endType == RecurrenceEndType.afterCount &&
          rule.maxOccurrences != null &&
          seriesIndex > rule.maxOccurrences!) {
        break;
      }

      final occ = _atTimeOnDate(
        day,
        rule,
        dueTimeHour: dueTimeHour,
        dueTimeMinute: dueTimeMinute,
      );

      if (!_allowsOccurrence(occ, rule, seriesIndex)) {
        break;
      }

      if (!occ.isBefore(start)) {
        results.add(occ);
      }

      day = day.add(Duration(days: interval));
    }
    return results;
  }

  static List<DateTime> _weekly({
    required DateTime anchorDate,
    required TaskRecurrenceRule rule,
    required int interval,
    required DateTime start,
    required int maxCount,
    int? dueTimeHour,
    int? dueTimeMinute,
  }) {
    final results = <DateTime>[];
    var mask = rule.weekdayMask;
    if (mask == 0) {
      mask = 1 << TaskRecurrenceRule.dartWeekdayToBitIndex(anchorDate.weekday);
    }

    final anchorMonday = _mondayOfWeek(anchorDate);
    final anchorDay = _startOfDay(anchorDate);
    var seriesIndex = 0;

    for (var wMul = 0; wMul < 520 && results.length < maxCount; wMul++) {
      final weekMonday = anchorMonday.add(Duration(days: 7 * interval * wMul));
      final candidates = <DateTime>[];
      for (var bit = 0; bit < 7; bit++) {
        if ((mask & (1 << bit)) == 0) continue;
        final wd = TaskRecurrenceRule.bitIndexToDartWeekday(bit);
        final d = weekMonday.add(Duration(days: wd - 1));
        if (!d.isBefore(anchorDay)) {
          candidates.add(d);
        }
      }
      candidates.sort();

      for (final d in candidates) {
        seriesIndex++;
        if (rule.endType == RecurrenceEndType.afterCount &&
            rule.maxOccurrences != null &&
            seriesIndex > rule.maxOccurrences!) {
          return results;
        }

        final occ = _atTimeOnDate(
          d,
          rule,
          dueTimeHour: dueTimeHour,
          dueTimeMinute: dueTimeMinute,
        );

        if (!_allowsOccurrence(occ, rule, seriesIndex)) {
          return results;
        }

        if (!occ.isBefore(start)) {
          results.add(occ);
          if (results.length >= maxCount) return results;
        }
      }
    }
    return results;
  }

  static void _advanceMonths(int interval, int y, int mo, void Function(int y, int mo) out) {
    var yy = y;
    var mm = mo + interval;
    while (mm > 12) {
      mm -= 12;
      yy++;
    }
    out(yy, mm);
  }

  static List<DateTime> _monthly({
    required DateTime anchorDate,
    required TaskRecurrenceRule rule,
    required int interval,
    required DateTime start,
    required int maxCount,
    int? dueTimeHour,
    int? dueTimeMinute,
  }) {
    final results = <DateTime>[];
    final preferredDay = anchorDate.day;
    final anchorDay = _startOfDay(anchorDate);
    var y = anchorDate.year;
    var mo = anchorDate.month;
    var seriesIndex = 0;

    for (var stepped = 0; stepped < 500 && results.length < maxCount; stepped++) {
      seriesIndex++;
      if (rule.endType == RecurrenceEndType.afterCount &&
          rule.maxOccurrences != null &&
          seriesIndex > rule.maxOccurrences!) {
        break;
      }

      final day = _monthlyDate(y, mo, preferredDay);
      if (day.isBefore(anchorDay)) {
        _advanceMonths(interval, y, mo, (ny, nm) {
          y = ny;
          mo = nm;
        });
        continue;
      }

      final occ = _atTimeOnDate(
        day,
        rule,
        dueTimeHour: dueTimeHour,
        dueTimeMinute: dueTimeMinute,
      );

      if (!_allowsOccurrence(occ, rule, seriesIndex)) {
        break;
      }

      if (!occ.isBefore(start)) {
        results.add(occ);
      }

      _advanceMonths(interval, y, mo, (ny, nm) {
        y = ny;
        mo = nm;
      });
    }
    return results;
  }

  static List<DateTime> _yearly({
    required DateTime anchorDate,
    required TaskRecurrenceRule rule,
    required int interval,
    required DateTime start,
    required int maxCount,
    int? dueTimeHour,
    int? dueTimeMinute,
  }) {
    final results = <DateTime>[];
    final mo = anchorDate.month;
    final preferredDay = anchorDate.day;
    final anchorDay = _startOfDay(anchorDate);
    var y = anchorDate.year;
    var seriesIndex = 0;

    for (var stepped = 0; stepped < 200 && results.length < maxCount; stepped++) {
      seriesIndex++;
      if (rule.endType == RecurrenceEndType.afterCount &&
          rule.maxOccurrences != null &&
          seriesIndex > rule.maxOccurrences!) {
        break;
      }

      final day = _monthlyDate(y, mo, preferredDay);
      if (day.isBefore(anchorDay)) {
        y += interval;
        continue;
      }

      final occ = _atTimeOnDate(
        day,
        rule,
        dueTimeHour: dueTimeHour,
        dueTimeMinute: dueTimeMinute,
      );

      if (!_allowsOccurrence(occ, rule, seriesIndex)) {
        break;
      }

      if (!occ.isBefore(start)) {
        results.add(occ);
      }

      y += interval;
    }
    return results;
  }
}
