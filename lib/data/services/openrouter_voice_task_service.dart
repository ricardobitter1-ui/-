import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../constants/voice_task_extraction_prompt.dart';
import '../models/extracted_voice_task_dto.dart';
import 'voice_api_config.dart';

class OpenRouterVoiceTaskService {
  OpenRouterVoiceTaskService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _url = 'https://openrouter.ai/api/v1/chat/completions';

  /// [groupNames] nomes canónicos dos grupos do utilizador.
  /// [referenceDate] dia civil local (YYYY-MM-DD).
  /// [contextGroupName] nome do grupo se o fluxo foi aberto dentro desse grupo.
  Future<List<ExtractedVoiceTaskDto>> extractTasks({
    required String transcript,
    required List<String> groupNames,
    required String referenceDate,
    String? contextGroupName,
  }) async {
    if (!VoiceApiConfig.hasOpenRouterKey) {
      throw StateError(
        'OPENROUTER_API_KEY não configurada. Use flutter run --dart-define-from-file=secrets.json',
      );
    }

    final groupsJson = jsonEncode(groupNames);
    final contextLine = contextGroupName != null && contextGroupName.trim().isNotEmpty
        ? 'Grupo de contexto do ecrã (usa este groupName quando o utilizador não disser outro e for lista de itens nesse grupo): "${contextGroupName.trim()}"\n'
        : '';

    final userContent = '''
Data de referência (hoje no dispositivo): $referenceDate
$contextLine
Grupos existentes (usa exactamente um destes nomes em groupName ou null): $groupsJson

Texto transcrito:
$transcript
''';

    final uri = Uri.parse(_url);
    final messages = [
      {'role': 'system', 'content': kVoiceTaskExtractionSystemPrompt},
      {'role': 'user', 'content': userContent},
    ];
    final headers = {
      'Authorization': 'Bearer ${VoiceApiConfig.openRouterApiKey}',
      'Content-Type': 'application/json',
      'HTTP-Referer': VoiceApiConfig.openRouterHttpReferer,
      'X-Title': 'Exm To-Do voice tasks',
    };

    var body = <String, dynamic>{
      'model': VoiceApiConfig.openRouterModel,
      'messages': messages,
      'response_format': {'type': 'json_object'},
    };

    var response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      body = <String, dynamic>{
        'model': VoiceApiConfig.openRouterModel,
        'messages': messages,
      };
      response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'OpenRouter falhou (${response.statusCode}): ${response.body}',
      );
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) {
      throw FormatException('Resposta OpenRouter sem choices');
    }
    final first = choices.first;
    if (first is! Map) throw FormatException('Choice inválida');
    final msg = first['message'];
    if (msg is! Map) throw FormatException('Sem message');
    final content = msg['content']?.toString() ?? '';
    return ExtractedVoiceTaskDto.parseTasksJson(content);
  }

  void close() {
    _client.close();
  }
}
