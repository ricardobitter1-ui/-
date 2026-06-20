import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/extracted_voice_task_dto.dart';
import 'voice_extract_prompt_builder.dart';
import 'voice_extract_request.dart';

/// Cliente HTTP partilhado para APIs OpenAI-compatible (Groq, OpenRouter).
class OpenAiCompatibleChatClient {
  OpenAiCompatibleChatClient({
    required this.chatCompletionsUrl,
    required this.apiKey,
    required this.model,
    this.qualityModel,
    this.extraHeaders = const {},
    this.providerLabel = 'llm',
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String chatCompletionsUrl;
  final String apiKey;
  final String model;
  final String? qualityModel;
  final Map<String, String> extraHeaders;
  final String providerLabel;

  final http.Client _client;

  Future<List<ExtractedVoiceTaskDto>> extractTasks(
    VoiceExtractRequest request,
  ) async {
    return _extractWithModel(request, model);
  }

  Future<List<ExtractedVoiceTaskDto>> _extractWithModel(
    VoiceExtractRequest request,
    String modelId,
  ) async {
    final system = VoiceExtractPromptBuilder.systemPromptFor(request);
    final user = VoiceExtractPromptBuilder.buildUserContent(request);
    final messages = [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': user},
    ];

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      ...extraHeaders,
    };

    var body = <String, dynamic>{
      'model': modelId,
      'messages': messages,
      'response_format': {'type': 'json_object'},
    };

    var response = await _client.post(
      Uri.parse(chatCompletionsUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      body = <String, dynamic>{
        'model': modelId,
        'messages': messages,
      };
      response = await _client.post(
        Uri.parse(chatCompletionsUrl),
        headers: headers,
        body: jsonEncode(body),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '$providerLabel falhou (${response.statusCode}): ${response.body}',
      );
    }

    final content = _parseContent(response.body);
    try {
      final tasks = ExtractedVoiceTaskDto.parseTasksJson(content);
      if (tasks.isNotEmpty) return tasks;
    } catch (_) {}

    final fallback = qualityModel?.trim();
    if (fallback != null &&
        fallback.isNotEmpty &&
        fallback != modelId) {
      return _extractWithModel(request, fallback);
    }

    return ExtractedVoiceTaskDto.parseTasksJson(content);
  }

  String _parseContent(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) {
      throw FormatException('Resposta $providerLabel sem choices');
    }
    final first = choices.first;
    if (first is! Map) throw FormatException('Choice inválida');
    final msg = first['message'];
    if (msg is! Map) throw FormatException('Sem message');
    return msg['content']?.toString() ?? '';
  }

  void close() {
    _client.close();
  }
}
