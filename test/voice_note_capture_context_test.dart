import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_note_capture_context.dart';

void main() {
  group('VoiceNoteCaptureContext', () {
    test('detects note-like group names', () {
      expect(VoiceNoteCaptureContext.isNoteCaptureGroupName('Melhorias'), isTrue);
      expect(VoiceNoteCaptureContext.isNoteCaptureGroupName('Bugs App'), isTrue);
      expect(VoiceNoteCaptureContext.isNoteCaptureGroupName('Supermercado'), isFalse);
      expect(VoiceNoteCaptureContext.isNoteCaptureGroupName('Chico'), isFalse);
    });

    test('shouldUseNoteCapture for Melhorias narrative', () {
      expect(
        VoiceNoteCaptureContext.shouldUseNoteCapture(
          forcedGroupName: 'Melhorias',
          transcript:
              'O snackbar quando crio tarefa não mostra o grupo porque fica confuso para o utilizador perceber o feedback',
        ),
        isTrue,
      );
    });

    test('shopping list in Melhorias defers to shopping transcript', () {
      expect(
        VoiceNoteCaptureContext.shouldUseNoteCapture(
          forcedGroupName: 'Melhorias',
          transcript: 'adicione arroz, feijão e leite na lista',
        ),
        isFalse,
      );
    });

    test('long narrative from home without shopping cues', () {
      expect(
        VoiceNoteCaptureContext.shouldUseNoteCapture(
          transcript:
              'Preciso anotar que quando eu abro o detalhe do grupo o snackbar não mostra informação suficiente sobre o erro que aconteceu e fica difícil de perceber',
        ),
        isTrue,
      );
    });
  });
}
