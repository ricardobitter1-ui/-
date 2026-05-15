import '../../models/extracted_voice_task_dto.dart';
import '../voice_api_config.dart';
import 'openai_compatible_chat_client.dart';
import 'voice_extract_request.dart';
import 'voice_llm_client.dart';

class GroqVoiceLlmClient implements VoiceLlmClient {
  GroqVoiceLlmClient({OpenAiCompatibleChatClient? chat})
      : _chat = chat ??
            OpenAiCompatibleChatClient(
              chatCompletionsUrl:
                  'https://api.groq.com/openai/v1/chat/completions',
              apiKey: VoiceApiConfig.groqApiKey,
              model: VoiceApiConfig.groqChatModel,
              qualityModel: VoiceApiConfig.groqChatModelQuality,
              providerLabel: 'groq',
            );

  final OpenAiCompatibleChatClient _chat;

  @override
  String get providerId => 'groq';

  @override
  String get modelId => VoiceApiConfig.groqChatModel;

  @override
  Future<List<ExtractedVoiceTaskDto>> extractTasks(
    VoiceExtractRequest request,
  ) {
    if (!VoiceApiConfig.hasGroqKey) {
      throw StateError(
        'GROQ_API_KEY não configurada. Use flutter run --dart-define-from-file=secrets.json',
      );
    }
    return _chat.extractTasks(request);
  }

  @override
  void close() => _chat.close();
}
