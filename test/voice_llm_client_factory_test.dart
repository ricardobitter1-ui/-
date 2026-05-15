import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/services/voice/groq_voice_llm_client.dart';
import 'package:todo_app/data/services/voice/openrouter_voice_llm_client.dart';
import 'package:todo_app/data/services/voice/voice_llm_client_factory.dart';
import 'package:todo_app/data/services/voice_api_config.dart';

void main() {
  group('VoiceLlmClientFactory', () {
    test('usesGroqLlm when provider is groq (default)', () {
      expect(VoiceApiConfig.usesGroqLlm, isTrue);
    });

    test('create returns GroqVoiceLlmClient by default', () {
      final client = VoiceLlmClientFactory.create();
      expect(client, isA<GroqVoiceLlmClient>());
      client.close();
    });

    test('override client is returned as-is', () {
      final custom = OpenRouterVoiceLlmClient();
      final client = VoiceLlmClientFactory.create(override: custom);
      expect(identical(client, custom), isTrue);
      client.close();
    });
  });
}
