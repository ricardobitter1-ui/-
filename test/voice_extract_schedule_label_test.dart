import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:todo_app/business_logic/voice_extract_schedule_label.dart';
import 'package:todo_app/data/models/extracted_voice_task_dto.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('formatExtractedVoiceScheduleLabel', () {
    final now = DateTime(2026, 6, 16, 14, 30);

    test('returns empty when no schedule', () {
      expect(
        formatExtractedVoiceScheduleLabel(
          const ExtractedVoiceTaskDto(title: 'Teste'),
          now: now,
          firstDayOfWeekIndex: 0,
        ),
        '',
      );
      expect(
        extractedVoiceTaskHasSchedule(
          const ExtractedVoiceTaskDto(title: 'Teste'),
        ),
        isFalse,
      );
    });

    test('formats datetime reminder for today', () {
      const dto = ExtractedVoiceTaskDto(
        title: 'Panela',
        date: '2026-06-16',
        time: '14:35',
      );
      expect(extractedVoiceTaskHasSchedule(dto), isTrue);
      expect(
        formatExtractedVoiceScheduleLabel(
          dto,
          now: now,
          firstDayOfWeekIndex: 0,
        ),
        'hoje, 14:35',
      );
    });

    test('formats date-only reminder', () {
      const dto = ExtractedVoiceTaskDto(
        title: 'Panela',
        date: '2026-06-17',
      );
      expect(
        formatExtractedVoiceScheduleLabel(
          dto,
          now: now,
          firstDayOfWeekIndex: 0,
        ),
        'amanhã',
      );
    });
  });
}
