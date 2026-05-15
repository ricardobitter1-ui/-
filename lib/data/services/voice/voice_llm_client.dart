import '../../models/extracted_voice_task_dto.dart';
import 'voice_extract_request.dart';

/// Provedor de extração de tarefas via chat completions (OpenAI-compatible).
abstract interface class VoiceLlmClient {
  String get providerId;

  String get modelId;

  Future<List<ExtractedVoiceTaskDto>> extractTasks(VoiceExtractRequest request);

  void close();
}
