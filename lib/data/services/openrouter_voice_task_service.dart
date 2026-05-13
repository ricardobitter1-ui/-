import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../constants/voice_task_extraction_prompt.dart';
import '../models/extracted_voice_task_dto.dart';
import '../models/tag_model.dart';
import '../../utils/title_search_key.dart';
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
    return parseTagAssignmentsResponse(content, itemTitles.length, tags, itemTitles);
  }

  /// Para testes e reutilização: interpreta o JSON do modelo.
  static List<String?> parseTagAssignmentsResponse(
    String raw,
    int expectedCount,
    List<TagModel> allowedTags,
    List<String> itemTitles,
  ) {
    final trimmed = raw.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return List<String?>.filled(expectedCount, null);
    }
    final decoded = jsonDecode(trimmed.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) {
      return List<String?>.filled(expectedCount, null);
    }
    final arr = decoded['assignments'];
    if (arr is! List) {
      return List<String?>.filled(expectedCount, null);
    }

    final allowedNames = {
      for (final t in allowedTags) normalizeTitleSearchKey(t.name): t.name,
    };

    String? canonicalTagName(String? rawName) {
      if (rawName == null) return null;
      final s = rawName.trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return allowedNames[normalizeTitleSearchKey(s)];
    }

    final byNormTitle = <String, String?>{};
    for (final e in arr) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final title = (m['title'] ?? m['titulo'])?.toString().trim() ?? '';
      if (title.isEmpty) continue;
      final tn = m['tagName'] ?? m['tag'];
      final tagStr = tn?.toString().trim();
      byNormTitle[normalizeTitleSearchKey(title)] =
          canonicalTagName(tagStr);
    }

    final out = <String?>[];
    for (final t in itemTitles) {
      out.add(byNormTitle[normalizeTitleSearchKey(t)]);
    }
    while (out.length < expectedCount) {
      out.add(null);
    }
    if (out.length > expectedCount) {
      return out.sublist(0, expectedCount);
    }
    return out;
  }

  void close() {
    _client.close();
  }
}
