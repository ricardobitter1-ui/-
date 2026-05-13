import 'dart:convert';

/// Uma tarefa devolvida pelo LLM antes de mapear para [TaskModel].
class ExtractedVoiceTaskDto {
  final String title;
  final String description;
  final String? date;
  final String? time;
  final String? groupName;
  /// Nome da etiqueta do grupo (fase 2 LLM); deve coincidir com uma tag existente.
  final String? tagName;

  const ExtractedVoiceTaskDto({
    required this.title,
    this.description = '',
    this.date,
    this.time,
    this.groupName,
    this.tagName,
  });

  ExtractedVoiceTaskDto copyWith({
    String? title,
    String? description,
    String? date,
    String? time,
    String? groupName,
    String? tagName,
  }) {
    return ExtractedVoiceTaskDto(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      groupName: groupName ?? this.groupName,
      tagName: tagName ?? this.tagName,
    );
  }

  static List<ExtractedVoiceTaskDto> parseTasksJson(String raw) {
    final decoded = _decodeJsonObject(raw);
    final tasksRaw = decoded['tasks'];
    if (tasksRaw is! List) {
      throw FormatException('JSON sem lista "tasks" válida');
    }
    final out = <ExtractedVoiceTaskDto>[];
    for (final item in tasksRaw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final title = (m['title'] ?? m['titulo'])?.toString().trim() ?? '';
      if (title.isEmpty) continue;
      out.add(
        ExtractedVoiceTaskDto(
          title: title,
          description: (m['description'] ?? m['descricao'])?.toString() ?? '',
          date: _nullableString(m['date'] ?? m['data']),
          time: _nullableString(m['time'] ?? m['hora']),
          groupName: _nullableString(m['groupName'] ?? m['grupo']),
          tagName: _nullableString(m['tagName'] ?? m['tag']),
        ),
      );
    }
    return out;
  }

  static String? _nullableString(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  static Map<String, dynamic> _decodeJsonObject(String raw) {
    final trimmed = raw.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw FormatException('Resposta não contém JSON objeto');
    }
    final slice = trimmed.substring(start, end + 1);
    final decoded = jsonDecode(slice);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON raiz deve ser objeto');
    }
    return decoded;
  }
}
