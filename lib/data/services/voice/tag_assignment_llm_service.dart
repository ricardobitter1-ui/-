import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../constants/voice_task_extraction_prompt.dart';
import '../../models/tag_model.dart';
import '../voice_api_config.dart';
import 'voice_tag_assignment_parser.dart';

/// Atribui etiquetas via LLM — Groq primeiro (menos rate limit), OpenRouter como fallback.
class TagAssignmentLlmService {
  TagAssignmentLlmService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _max429Retries = 3;

  Future<List<String?>> assignShoppingTags({
    required List<String> itemTitles,
    required List<TagModel> tags,
    String? transcriptContext,
  }) async {
    if (itemTitles.isEmpty) return const [];

    final messages = _buildMessages(
      itemTitles: itemTitles,
      tags: tags,
      transcriptContext: transcriptContext,
    );

    if (VoiceApiConfig.hasGroqKey) {
      try {
        return await _callAndParse(
          url: _groqUrl,
          apiKey: VoiceApiConfig.groqApiKey,
          model: VoiceApiConfig.groqChatModel,
          messages: messages,
          providerLabel: 'Groq',
          itemTitles: itemTitles,
          tags: tags,
        );
      } catch (e) {
        if (!VoiceApiConfig.hasOpenRouterKey) rethrow;
      }
    }

    if (VoiceApiConfig.hasOpenRouterKey) {
      return _callOpenRouterWithRetries(
        messages: messages,
        itemTitles: itemTitles,
        tags: tags,
      );
    }

    throw StateError(
      'Configure GROQ_API_KEY ou OPENROUTER_API_KEY em secrets.json.',
    );
  }

  List<Map<String, String>> _buildMessages({
    required List<String> itemTitles,
    required List<TagModel> tags,
    String? transcriptContext,
  }) {
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

    return [
      {'role': 'system', 'content': kVoiceTagAssignmentSystemPrompt},
      {'role': 'user', 'content': userContent},
    ];
  }

  Future<List<String?>> _callOpenRouterWithRetries({
    required List<Map<String, String>> messages,
    required List<String> itemTitles,
    required List<TagModel> tags,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < _max429Retries; attempt++) {
      try {
        return await _callAndParse(
          url: _openRouterUrl,
          apiKey: VoiceApiConfig.openRouterApiKey,
          model: VoiceApiConfig.openRouterModel,
          messages: messages,
          providerLabel: 'OpenRouter',
          itemTitles: itemTitles,
          tags: tags,
          extraHeaders: {
            'HTTP-Referer': VoiceApiConfig.openRouterHttpReferer,
            'X-Title': 'Exm To-Do voice tags',
          },
        );
      } catch (e) {
        lastError = e;
        final waitSeconds = _retryAfterSecondsFromError(e);
        if (waitSeconds == null || attempt >= _max429Retries - 1) rethrow;
        await Future<void>.delayed(
          Duration(seconds: waitSeconds.clamp(1, 30)),
        );
      }
    }
    throw lastError ?? Exception('OpenRouter tags falhou após várias tentativas.');
  }

  Future<List<String?>> _callAndParse({
    required String url,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    required String providerLabel,
    required List<String> itemTitles,
    required List<TagModel> tags,
    Map<String, String> extraHeaders = const {},
  }) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      ...extraHeaders,
    };

    var body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'response_format': {'type': 'json_object'},
    };

    var response = await _client.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      body = <String, dynamic>{
        'model': model,
        'messages': messages,
      };
      response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '$providerLabel tags (${response.statusCode}): ${response.body}',
      );
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) {
      throw FormatException('Resposta $providerLabel sem choices');
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

  static int? _retryAfterSecondsFromError(Object error) {
    final text = error.toString();
    if (!text.contains('429')) return null;
    final match = RegExp(r'retry_after_seconds["\s:]*(\d+)').firstMatch(text);
    if (match != null) return int.tryParse(match.group(1)!);
    return 8;
  }

  /// Mensagem amigável para erros de limpeza automática / tags.
  static String friendlyErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('429')) {
      return 'Limite de uso da IA atingido. Aguarde alguns segundos e tente de novo.';
    }
    if (text.contains('404') && text.contains('No endpoints found')) {
      return 'Modelo de IA não encontrado. Verifique OPENROUTER_MODEL em secrets.json.';
    }
    if (text.contains('GROQ_API_KEY') || text.contains('OPENROUTER_API_KEY')) {
      return 'Configure GROQ_API_KEY ou OPENROUTER_API_KEY em secrets.json.';
    }
    return 'Limpeza automática falhou. Tente novamente em instantes.';
  }

  void close() => _client.close();
}
