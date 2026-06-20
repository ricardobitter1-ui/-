import 'dart:convert';

const _unset = Object();

/// Uma tarefa devolvida pelo LLM antes de mapear para [TaskModel].
class ExtractedVoiceTaskDto {
  final String title;
  final String description;
  final String? date;
  final String? time;
  final String? groupName;
  /// Nome da etiqueta do grupo (fase 2 LLM).
  final String? tagName;
  /// True quando o utilizador pediu explicitamente esta tag/categoria (pode criar se não existir).
  final bool tagExplicit;

  const ExtractedVoiceTaskDto({
    required this.title,
    this.description = '',
    this.date,
    this.time,
    this.groupName,
    this.tagName,
    this.tagExplicit = false,
  });

  ExtractedVoiceTaskDto copyWith({
    String? title,
    String? description,
    Object? date = _unset,
    Object? time = _unset,
    Object? groupName = _unset,
    Object? tagName = _unset,
    bool? tagExplicit,
  }) {
    return ExtractedVoiceTaskDto(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date == _unset ? this.date : date as String?,
      time: time == _unset ? this.time : time as String?,
      groupName: groupName == _unset ? this.groupName : groupName as String?,
      tagName: tagName == _unset ? this.tagName : tagName as String?,
      tagExplicit: tagExplicit ?? this.tagExplicit,
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
          tagExplicit: _parseBool(m['tagExplicit'] ?? m['tagExplicito']),
        ),
      );
    }
    return out;
  }

  static bool _parseBool(Object? v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'sim';
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
