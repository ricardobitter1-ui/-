/// Chaves lidas em compile time via `--dart-define-from-file=secrets.json`.
/// Copie [secrets.json.example] para `secrets.json` na raiz do projeto e preencha.
abstract final class VoiceApiConfig {
  static const String groqApiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String openRouterApiKey =
      String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  static const String openRouterModel = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'openai/gpt-4o-mini',
  );
  static const String openRouterHttpReferer = String.fromEnvironment(
    'OPENROUTER_HTTP_REFERER',
    defaultValue: 'https://localhost',
  );

  static bool get hasGroqKey => groqApiKey.trim().isNotEmpty;
  static bool get hasOpenRouterKey => openRouterApiKey.trim().isNotEmpty;
  static bool get isConfigured => hasGroqKey && hasOpenRouterKey;
}
