import '../data/models/extracted_voice_task_dto.dart';
import '../utils/calendar_day_key.dart';

/// Resultado da heurística local para lembretes.
class VoiceReminderHeuristicResult {
  final ExtractedVoiceTaskDto? task;
  final bool confident;

  const VoiceReminderHeuristicResult({
    this.task,
    required this.confident,
  });
}

abstract final class VoiceReminderHeuristicParser {
  static final _reminderLead = RegExp(
    r'^(me\s+)?(lembre|lembra|avisa|alerta)\s*(me\s+)?(de\s+)?',
    caseSensitive: false,
  );

  static final _timePattern = RegExp(
    r'(?:às|as|a)\s*(\d{1,2})(?:[:h](\d{2}))?\s*(?:h|horas?)?',
    caseSensitive: false,
  );

  static final _timeBare = RegExp(
    r'\b(\d{1,2})[:h](\d{2})\b',
    caseSensitive: false,
  );

  /// Tenta extrair um lembrete sem LLM.
  static VoiceReminderHeuristicResult parse({
    required String transcript,
    required DateTime referenceDate,
    String? forcedGroupName,
  }) {
    var text = transcript.trim();
    if (text.isEmpty) {
      return const VoiceReminderHeuristicResult(confident: false);
    }

    if (!_reminderLead.hasMatch(text)) {
      return const VoiceReminderHeuristicResult(confident: false);
    }

    String? timeStr;
    final tm = _timePattern.firstMatch(text) ?? _timeBare.firstMatch(text);
    if (tm != null) {
      final h = int.parse(tm.group(1)!);
      final m = tm.groupCount >= 2 && tm.group(2) != null
          ? int.parse(tm.group(2)!)
          : 0;
      timeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    var dateStr = _resolveRelativeDate(text, referenceDate);
    final hasRelativeDate = RegExp(
      r'\b(hoje|amanh[ãa]|depois de amanh[ãa])\b',
      caseSensitive: false,
    ).hasMatch(text);

    text = text.replaceAll(_reminderLead, '');
    text = text.replaceAll(
      RegExp(
        r'\b(hoje|amanh[ãa]|depois de amanh[ãa])\b',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(_timePattern, '');
    text = text.replaceAll(_timeBare, '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.isEmpty) {
      return const VoiceReminderHeuristicResult(confident: false);
    }

    final confident = (timeStr != null || hasRelativeDate) && text.length >= 3;
    if (!confident) {
      return const VoiceReminderHeuristicResult(confident: false);
    }

    return VoiceReminderHeuristicResult(
      confident: true,
      task: ExtractedVoiceTaskDto(
        title: _capitalizeFirst(text),
        groupName: forcedGroupName,
        date: dateStr,
        time: timeStr,
      ),
    );
  }

  static String? _resolveRelativeDate(String text, DateTime ref) {
    final lower = text.toLowerCase();
    if (lower.contains('depois de amanh')) {
      return localCalendarDayKey(ref.add(const Duration(days: 2)));
    }
    if (lower.contains('amanh')) {
      return localCalendarDayKey(ref.add(const Duration(days: 1)));
    }
    if (lower.contains('hoje')) {
      return localCalendarDayKey(ref);
    }
    return null;
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
