import '../voice_api_config.dart';
import 'groq_voice_llm_client.dart';
import 'openrouter_voice_llm_client.dart';
import 'voice_llm_client.dart';

abstract final class VoiceLlmClientFactory {
  static VoiceLlmClient create({VoiceLlmClient? override}) {
    if (override != null) return override;
    if (VoiceApiConfig.usesGroqLlm) {
      return GroqVoiceLlmClient();
    }
    return OpenRouterVoiceLlmClient();
  }
}
