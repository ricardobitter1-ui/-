import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_shopping_list_context.dart';

void main() {
  group('VoiceShoppingListContext', () {
    test('detects supermarket-like group names', () {
      expect(
        VoiceShoppingListContext.isShoppingListGroupName('Supermercado'),
        isTrue,
      );
      expect(
        VoiceShoppingListContext.isShoppingListGroupName('Mercado Central'),
        isTrue,
      );
      expect(
        VoiceShoppingListContext.isShoppingListGroupName('Lista de compras'),
        isTrue,
      );
      expect(VoiceShoppingListContext.isShoppingListGroupName('Chico'), isFalse);
    });

    test('shouldUseShoppingItemTitles from forced or context name', () {
      expect(
        VoiceShoppingListContext.shouldUseShoppingItemTitles(
          forcedGroupName: 'Supermercado',
        ),
        isTrue,
      );
      expect(
        VoiceShoppingListContext.shouldUseShoppingItemTitles(
          contextGroupName: 'Feira',
        ),
        isTrue,
      );
      expect(
        VoiceShoppingListContext.shouldUseShoppingItemTitles(
          forcedGroupName: 'Trabalho',
        ),
        isFalse,
      );
    });
  });
}
