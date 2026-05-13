import '../utils/calendar_day_key.dart';

class VoiceTaskDueFields {
  final DateTime? dueDate;
  final bool dueHasTime;
  final String? reminderType;

  const VoiceTaskDueFields({
    this.dueDate,
    this.dueHasTime = false,
    this.reminderType,
  });
}

abstract final class VoiceTaskDueParser {
  static VoiceTaskDueFields parse(String? date, String? time) {
    final d = date?.trim();
    if (d == null || d.isEmpty || !isValidCalendarDayKey(d)) {
      return const VoiceTaskDueFields();
    }
    final parts = d.split('-');
    final y = int.parse(parts[0]);
    final mo = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    final t = time?.trim();
    if (t != null && t.isNotEmpty) {
      final tp = t.split(':');
      final h = int.tryParse(tp[0].trim()) ?? 0;
      final mm = tp.length > 1 ? int.tryParse(tp[1].trim()) ?? 0 : 0;
      return VoiceTaskDueFields(
        dueDate: DateTime(y, mo, day, h, mm),
        dueHasTime: true,
        reminderType: 'datetime',
      );
    }

    return VoiceTaskDueFields(
      dueDate: DateTime(y, mo, day),
      dueHasTime: false,
      reminderType: 'datetime',
    );
  }
}
