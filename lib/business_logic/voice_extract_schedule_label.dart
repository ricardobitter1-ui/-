import 'package:intl/intl.dart';

import '../data/models/extracted_voice_task_dto.dart';
import '../utils/scheduled_badge_label.dart';
import 'voice_task_due_parser.dart';

/// Texto legível do agendamento extraído por voz (ou vazio se não houver).
String formatExtractedVoiceScheduleLabel(
  ExtractedVoiceTaskDto dto, {
  required DateTime now,
  required int firstDayOfWeekIndex,
}) {
  final fields = VoiceTaskDueParser.parse(dto.date, dto.time);
  final due = fields.dueDate;
  if (due == null) return '';

  if (fields.dueHasTime) {
    return formatScheduledBadge(
      due: due,
      now: now,
      firstDayOfWeekIndex: firstDayOfWeekIndex,
    ).label;
  }

  final dueD = DateTime(due.year, due.month, due.day);
  final nowD = DateTime(now.year, now.month, now.day);
  if (dueD == nowD) return 'hoje';
  if (dueD == nowD.add(const Duration(days: 1))) return 'amanhã';
  if (dueD == nowD.add(const Duration(days: 2))) return 'depois de amanhã';
  return DateFormat('d MMM', 'pt_BR').format(dueD);
}

bool extractedVoiceTaskHasSchedule(ExtractedVoiceTaskDto dto) {
  return VoiceTaskDueParser.parse(dto.date, dto.time).dueDate != null;
}
