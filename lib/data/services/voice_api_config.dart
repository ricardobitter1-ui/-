/// Chaves lidas em compile time via `--dart-define-from-file=secrets.json`.
/// Copie [secrets.json.example] para `secrets.json` na raiz do projeto e preencha.
abstract final class VoiceApiConfig {
  static const String groqApiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String openRouterApiKey =
      String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  /// Modelo de chat/completions no OpenRouter (tags, extração por voz).
  /// Deve ser um modelo de chat — não usar modelos de rerank/embeddings.
  static const String openRouterModel = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'meta-llama/llama-3.3-70b-instruct:free',
  );
  static const String openRouterHttpReferer = String.fromEnvironment(
    'OPENROUTER_HTTP_REFERER',
    defaultValue: 'https://localhost',
  );

  /// `groq` (default) ou `openrouter`.
  static const String voiceLlmProvider = String.fromEnvironment(
    'VOICE_LLM_PROVIDER',
    defaultValue: 'groq',
  );

  static const String groqChatModel = String.fromEnvironment(
    'GROQ_CHAT_MODEL',
    defaultValue: 'llama-3.1-8b-instant',
  );

  static const String groqChatModelQuality = String.fromEnvironment(
    'GROQ_CHAT_MODEL_QUALITY',
    defaultValue: 'llama-3.3-70b-versatile',
  );

  static bool get hasGroqKey => groqApiKey.trim().isNotEmpty;
  static bool get hasOpenRouterKey => openRouterApiKey.trim().isNotEmpty;

  static bool get usesGroqLlm =>
      voiceLlmProvider.trim().toLowerCase() != 'openrouter';

  static bool get hasLlmConfigured =>
      usesGroqLlm ? hasGroqKey : hasOpenRouterKey;

  /// STT (Groq) + LLM conforme [voiceLlmProvider].
  static bool get isConfigured => hasGroqKey && hasLlmConfigured;

  static String get activeLlmProviderLabel =>
      usesGroqLlm ? 'groq' : 'openrouter';

  static String get activeChatModel =>
      usesGroqLlm ? groqChatModel : openRouterModel;

  static String configurationHint() {
    if (!hasGroqKey) {
      return 'Defina GROQ_API_KEY em secrets.json (transcrição de áudio).';
    }
    if (!hasLlmConfigured) {
      if (usesGroqLlm) {
        return 'GROQ_API_KEY em falta para o LLM (ou defina VOICE_LLM_PROVIDER=openrouter).';
      }
      return 'Defina OPENROUTER_API_KEY ou use VOICE_LLM_PROVIDER=groq.';
    }
    return '';
  }
}
