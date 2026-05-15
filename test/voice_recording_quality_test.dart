import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_recording_quality.dart';

void main() {
  group('VoiceRecordingQuality.validate', () {
    test('aceita gravação com duração e voz suficientes', () {
      expect(
        VoiceRecordingQuality.validate(
          duration: const Duration(seconds: 3),
          peakDbfs: -30,
        ),
        isNull,
      );
    });

    test('rejeita gravação muito curta', () {
      expect(
        VoiceRecordingQuality.validate(
          duration: const Duration(milliseconds: 500),
          peakDbfs: -20,
        ),
        VoiceRecordingQualityIssue.tooShort,
      );
    });

    test('rejeita gravação sem voz detectada', () {
      expect(
        VoiceRecordingQuality.validate(
          duration: const Duration(seconds: 5),
          peakDbfs: -50,
        ),
        VoiceRecordingQualityIssue.noVoiceDetected,
      );
    });

    test('prioriza duração curta sobre silêncio', () {
      expect(
        VoiceRecordingQuality.validate(
          duration: const Duration(seconds: 1),
          peakDbfs: -160,
        ),
        VoiceRecordingQualityIssue.tooShort,
      );
    });
  });

  group('VoiceRecordingQuality.trackPeakDbfs', () {
    test('mantém o maior valor', () {
      var peak = VoiceRecordingQuality.silenceDbfs;
      peak = VoiceRecordingQuality.trackPeakDbfs(peak, -50);
      peak = VoiceRecordingQuality.trackPeakDbfs(peak, -35);
      peak = VoiceRecordingQuality.trackPeakDbfs(peak, -40);
      expect(peak, -35);
    });
  });
}
