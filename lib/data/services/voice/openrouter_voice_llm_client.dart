import '../../models/extracted_voice_task_dto.dart';
import '../voice_api_config.dart';
import 'openai_compatible_chat_client.dart';
import 'voice_extract_request.dart';
import 'voice_llm_client.dart';

class OpenRouterVoiceLlmClient implements VoiceLlmClient {
  OpenRouterVoiceLlmClient({OpenAiCompatibleChatClient? chat})
      : _chat = chat ??
            OpenAiCompatibleChatClient(
              chatCompletionsUrl:
                  'https://openrouter.ai/api/v1/chat/completions',
              apiKey: VoiceApiConfig.openRouterApiKey,
              model: VoiceApiConfig.openRouterModel,
              providerLabel: 'openrouter',
              extraHeaders: {
                'HTTP-Referer': VoiceApiConfig.openRouterHttpReferer,
                'X-Title': 'Exm To-Do voice tasks',
              },
            );

  final OpenAiCompatibleChatClient _chat;

  @override
  String get providerId => 'openrouter';

  @override
  String get modelId => VoiceApiConfig.openRouterModel;

  @override
  Future<List<ExtractedVoiceTaskDto>> extractTasks(
    VoiceExtractRequest request,
  ) {
    if (!VoiceApiConfig.hasOpenRouterKey) {
      throw StateError(
        'OPENROUTER_API_KEY não configurada. Use flutter run --dart-define-from-file=secrets.json',
      );
    }
    return _chat.extractTasks(request);
  }

  @override
  void close() => _chat.close();
}
