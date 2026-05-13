import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'voice_api_config.dart';

/// Transcrição de áudio via API OpenAI-compatible da Groq.
class GroqTranscriptionService {
  GroqTranscriptionService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
  static const _defaultModel = 'whisper-large-v3-turbo';

  Future<String> transcribeFile({
    required File audioFile,
    String model = _defaultModel,
    String language = 'pt',
  }) async {
    if (!VoiceApiConfig.hasGroqKey) {
      throw StateError(
        'GROQ_API_KEY não configurada. Use flutter run --dart-define-from-file=secrets.json',
      );
    }

    final uri = Uri.parse(_baseUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${VoiceApiConfig.groqApiKey}'
      ..fields['model'] = model
      ..fields['language'] = language
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Groq transcrição falhou (${response.statusCode}): ${response.body}',
      );
    }

    final map = jsonDecode(response.body);
    if (map is Map && map['text'] is String) {
      return (map['text'] as String).trim();
    }
    return response.body.trim();
  }

  void close() {
    _client.close();
  }
}
