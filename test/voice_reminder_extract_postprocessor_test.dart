import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_reminder_extract_postprocessor.dart';
import 'package:todo_app/data/models/extracted_voice_task_dto.dart';

void main() {
  group('VoiceReminderExtractPostprocessor', () {
  final ref = DateTime(2026, 6, 16, 14, 30);

    test('merges duplicate reminders keeping scheduled one', () {
      final out = VoiceReminderExtractPostprocessor.refine(
        tasks: const [
          ExtractedVoiceTaskDto(title: 'Desligar a panela'),
          ExtractedVoiceTaskDto(
            title: 'Desligar a panela',
            description: 'daqui 3 minutos',
            date: '2026-06-16',
            time: '14:33',
          ),
        ],
        referenceDate: ref,
      );
      expect(out, hasLength(1));
      expect(out.first.title, 'Desligar a panela');
      expect(out.first.time, '14:33');
      expect(out.first.description, isEmpty);
    });

    test('fills schedule from temporal description when title-only duplicate exists', () {
      final out = VoiceReminderExtractPostprocessor.refine(
        tasks: const [
          ExtractedVoiceTaskDto(title: 'Desligar a panela'),
          ExtractedVoiceTaskDto(
            title: 'Desligar a panela',
            description: 'daqui um minuto',
          ),
        ],
        referenceDate: ref,
      );
      expect(out, hasLength(1));
      expect(out.first.time, '14:31');
      expect(out.first.date, '2026-06-16');
      expect(out.first.description, isEmpty);
    });

    test('keeps distinct reminders with different titles', () {
      final out = VoiceReminderExtractPostprocessor.refine(
        tasks: const [
          ExtractedVoiceTaskDto(title: 'Desligar a panela'),
          ExtractedVoiceTaskDto(title: 'Ligar o forno'),
        ],
        referenceDate: ref,
      );
      expect(out, hasLength(2));
    });
  });
}
