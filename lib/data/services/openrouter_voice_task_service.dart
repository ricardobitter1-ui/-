import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../constants/voice_task_extraction_prompt.dart';
import '../models/extracted_voice_task_dto.dart';
import '../models/tag_model.dart';
import 'voice/voice_tag_assignment_parser.dart';
import 'voice_api_config.dart';

class OpenRouterVoiceTaskService {
  OpenRouterVoiceTaskService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _url = 'https://openrouter.ai/api/v1/chat/completions';

  /// [groupNames] nomes canónicos dos grupos do utilizador.
  /// [referenceDate] dia civil local (YYYY-MM-DD).
  /// [contextGroupName] nome do grupo se o fluxo foi aberto dentro desse grupo.
  /// [tagsByGroupName] nomes de etiquetas por nome de grupo (omitir grupos sem tags).
  Future<List<ExtractedVoiceTaskDto>> extractTasks({
    required String transcript,
    required List<String> groupNames,
    required String referenceDate,
    String? contextGroupName,
    Map<String, List<String>> tagsByGroupName = const {},
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
    final tagsLine = tagsByGroupName.isEmpty
        ? ''
        : 'Etiquetas por grupo (tagName exacto de uma destas listas ou null):\n${jsonEncode(tagsByGroupName)}\n';

    final userContent = '''
Data de referência (hoje no dispositivo): $referenceDate
$contextLine
Grupos existentes (usa exactamente um destes nomes em groupName ou null): $groupsJson
$tagsLine
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

  /// Uma entrada por título em [itemTitles] (mesma ordem preferida no output).
  Future<List<String?>> assignShoppingTags({
    required List<String> itemTitles,
    required List<TagModel> tags,
    String? transcriptContext,
  }) async {
    if (!VoiceApiConfig.hasOpenRouterKey) {
      throw StateError(
        'OPENROUTER_API_KEY não configurada. Use flutter run --dart-define-from-file=secrets.json',
      );
    }
    if (itemTitles.isEmpty) return const [];

    final tagsJson = jsonEncode(
      tags.map((t) => {'id': t.id, 'name': t.name}).toList(),
    );
    final itemsBlock = itemTitles.map((t) => '- ${t.trim()}').join('\n');
    final ctx = (transcriptContext ?? '').trim();
    final ctxBlock = ctx.isEmpty ? '(sem contexto extra)' : ctx;

    final userContent = '''
Itens a classificar (um por linha):
$itemsBlock

Etiquetas disponíveis (usa exactamente o campo "name" de uma destas entradas em tagName, ou null):
$tagsJson

Contexto (transcrição original):
$ctxBlock
''';

    final uri = Uri.parse(_url);
    final messages = [
      {'role': 'system', 'content': kVoiceTagAssignmentSystemPrompt},
      {'role': 'user', 'content': userContent},
    ];
    final headers = {
      'Authorization': 'Bearer ${VoiceApiConfig.openRouterApiKey}',
      'Content-Type': 'application/json',
      'HTTP-Referer': VoiceApiConfig.openRouterHttpReferer,
      'X-Title': 'Exm To-Do voice tags',
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
        'OpenRouter tags (${response.statusCode}): ${response.body}',
      );
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) {
      throw FormatException('Resposta OpenRouter sem choices');
    }
    final first = choices.first as Map;
    final msg = first['message'] as Map;
    final content = msg['content']?.toString() ?? '';
    return VoiceTagAssignmentParser.parseTagAssignmentsResponse(
      content,
      itemTitles.length,
      tags,
      itemTitles,
    );
  }

  /// Para testes: delega ao parser partilhado.
  static List<String?> parseTagAssignmentsResponse(
    String raw,
    int expectedCount,
    List<TagModel> allowedTags,
    List<String> itemTitles,
  ) =>
      VoiceTagAssignmentParser.parseTagAssignmentsResponse(
        raw,
        expectedCount,
        allowedTags,
        itemTitles,
      );

  void close() {
    _client.close();
  }
}
