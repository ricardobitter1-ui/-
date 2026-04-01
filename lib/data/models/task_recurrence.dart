import 'package:cloud_firestore/cloud_firestore.dart';

/// Unidade do intervalo em "Cada N …".
enum RecurrenceUnit {
  day,
  week,
  month,
  year,
}

/// Como a série termina.
enum RecurrenceEndType {
  never,
  untilDate,
  afterCount,
}

/// Regra de repetição persistida em `tasks.recurrence` (Firestore).
class TaskRecurrenceRule {
  final int interval;
  final RecurrenceUnit unit;
  /// Bits 0–6: domingo … sábado (0 = domingo no calendário pt_BR).
  final int weekdayMask;
  /// Hora opcional do lembrete em cada ocorrência (null = só data / meia-noite na data).
  final int? repeatHour;
  final int? repeatMinute;
  final RecurrenceEndType endType;
  final DateTime? endDate;
  /// Número total de ocorrências da série (inclui a primeira).
  final int? maxOccurrences;

  const TaskRecurrenceRule({
    required this.interval,
    required this.unit,
    this.weekdayMask = 0,
    this.repeatHour,
    this.repeatMinute,
    this.endType = RecurrenceEndType.never,
    this.endDate,
    this.maxOccurrences,
  });

  bool get hasWeekdaySelection => weekdayMask != 0;

  static int dartWeekdayToBitIndex(int dartWeekday) {
    // DateTime: seg=1 … dom=7
    return dartWeekday == DateTime.sunday ? 0 : dartWeekday;
  }

  static int bitIndexToDartWeekday(int bitIndex) {
    return bitIndex == 0 ? DateTime.sunday : bitIndex;
  }

  bool weekdaySelected(int dartWeekday) {
    final bit = dartWeekdayToBitIndex(dartWeekday);
    return (weekdayMask & (1 << bit)) != 0;
  }

  TaskRecurrenceRule copyWith({
    int? interval,
    RecurrenceUnit? unit,
    int? weekdayMask,
    int? repeatHour,
    int? repeatMinute,
    RecurrenceEndType? endType,
    DateTime? endDate,
    int? maxOccurrences,
    bool clearRepeatTime = false,
    bool clearEndDate = false,
    bool clearMaxOccurrences = false,
  }) {
    return TaskRecurrenceRule(
      interval: interval ?? this.interval,
      unit: unit ?? this.unit,
      weekdayMask: weekdayMask ?? this.weekdayMask,
      repeatHour: clearRepeatTime ? null : (repeatHour ?? this.repeatHour),
      repeatMinute: clearRepeatTime ? null : (repeatMinute ?? this.repeatMinute),
      endType: endType ?? this.endType,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      maxOccurrences:
          clearMaxOccurrences ? null : (maxOccurrences ?? this.maxOccurrences),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'interval': interval,
      'unit': unit.name,
      'weekdayMask': weekdayMask,
      'repeatHour': repeatHour,
      'repeatMinute': repeatMinute,
      'endType': endType.name,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'maxOccurrences': maxOccurrences,
    };
  }

  /// Rótulo curto para listas (ex.: cartão de tarefa).
  static String shortLabel(TaskRecurrenceRule r) {
    final u = switch (r.unit) {
      RecurrenceUnit.day => r.interval == 1 ? 'dia' : '${r.interval} dias',
      RecurrenceUnit.week => r.interval == 1 ? 'semana' : '${r.interval} semanas',
      RecurrenceUnit.month => r.interval == 1 ? 'mês' : '${r.interval} meses',
      RecurrenceUnit.year => r.interval == 1 ? 'ano' : '${r.interval} anos',
    };
    return 'Repete a cada $u';
  }

  static TaskRecurrenceRule? fromMap(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final interval = (m['interval'] as num?)?.toInt() ?? 1;
    final unitStr = m['unit'] as String? ?? 'day';
    RecurrenceUnit unit = RecurrenceUnit.day;
    for (final u in RecurrenceUnit.values) {
      if (u.name == unitStr) {
        unit = u;
        break;
      }
    }
    final mask = (m['weekdayMask'] as num?)?.toInt() ?? 0;
    final rh = (m['repeatHour'] as num?)?.toInt();
    final rm = (m['repeatMinute'] as num?)?.toInt();
    final endStr = m['endType'] as String? ?? 'never';
    RecurrenceEndType endType = RecurrenceEndType.never;
    for (final e in RecurrenceEndType.values) {
      if (e.name == endStr) {
        endType = e;
        break;
      }
    }
    final endDate = (m['endDate'] as Timestamp?)?.toDate();
    final maxOcc = (m['maxOccurrences'] as num?)?.toInt();
    return TaskRecurrenceRule(
      interval: interval < 1 ? 1 : interval,
      unit: unit,
      weekdayMask: mask,
      repeatHour: rh,
      repeatMinute: rm,
      endType: endType,
      endDate: endDate,
      maxOccurrences: maxOcc,
    );
  }
}
