import 'package:diacritic/diacritic.dart';

import '../data/models/extracted_voice_task_dto.dart';
import '../data/models/group_model.dart';
import '../utils/calendar_day_key.dart';
import 'voice_task_group_resolver.dart';
import 'voice_task_title_sanitizer.dart';

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
    r'(?:as|a)\s*(\d{1,2})(?:[:h](\d{2}))?\s*(?:h|horas?)?(?:\s+(?:da|de)\s+manha)?',
    caseSensitive: false,
  );

  static final _timeBare = RegExp(
    r'\b(\d{1,2})[:h](\d{2})\b',
    caseSensitive: false,
  );

  static final _relativeCount =
      r'(?:(\d+)|(um|uma|dois|duas|tres|tr[eê]s|quatro|cinco|seis|sete|oito|nove|dez))';

  static final _relativeMinutes = RegExp(
    r'\b(?:em|daqui(?:\s+a)?)\s+' + _relativeCount + r'\s+minutos?\b',
    caseSensitive: false,
  );

  static final _relativeHours = RegExp(
    r'\b(?:em|daqui(?:\s+a)?)\s+' + _relativeCount + r'\s+horas?\b',
    caseSensitive: false,
  );

  static const _wordToInt = {
    'um': 1,
    'uma': 1,
    'dois': 2,
    'duas': 2,
    'tres': 3,
    'três': 3,
    'quatro': 4,
    'cinco': 5,
    'seis': 6,
    'sete': 7,
    'oito': 8,
    'nove': 9,
    'dez': 10,
  };

  /// Tenta extrair um lembrete sem LLM.
  static VoiceReminderHeuristicResult parse({
    required String transcript,
    required DateTime referenceDate,
    String? forcedGroupName,
    List<GroupModel> groups = const [],
  }) {
    var text = transcript.trim();
    if (text.isEmpty) {
      return const VoiceReminderHeuristicResult(confident: false);
    }

    if (!_reminderLead.hasMatch(text)) {
      return const VoiceReminderHeuristicResult(confident: false);
    }

    final normForTime = removeDiacritics(text);
    // Evita que expressões relativas ("daqui a 2 horas", "em 2 minutos")
    // sejam parcialmente interpretadas pelos regexes de horário absoluto.
    final normForAbsoluteTime = normForTime
        .replaceAll(_relativeHours, '')
        .replaceAll(_relativeMinutes, '');
    String? timeStr;
    final tm =
        _timePattern.firstMatch(normForAbsoluteTime) ??
            _timeBare.firstMatch(normForAbsoluteTime);
    if (tm != null) {
      final h = int.parse(tm.group(1)!);
      final m = tm.groupCount >= 2 && tm.group(2) != null
          ? int.parse(tm.group(2)!)
          : 0;
      timeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    var dateStr = _resolveRelativeDate(text, referenceDate);
    if (timeStr == null) {
      final relative = extractRelativeSchedule(text, referenceDate);
      if (relative != null) {
        timeStr = relative.time;
        dateStr ??= relative.date;
      }
    }
    final normText = removeDiacritics(text);
    final hasRelativeDate = RegExp(
      r'\b(hoje|amanha|depois de amanha)\b',
      caseSensitive: false,
    ).hasMatch(normText);

    text = text.replaceAll(_reminderLead, '');
    text = VoiceTaskTitleSanitizer.sanitize(
      text,
      stripDateHints: true,
      stripTimeHints: true,
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.isEmpty) {
      return const VoiceReminderHeuristicResult(confident: false);
    }

    final confident = (timeStr != null || hasRelativeDate) && text.length >= 3;
    if (!confident) {
      return const VoiceReminderHeuristicResult(confident: false);
    }

    final inferredGroup = forcedGroupName ??
        inferGroupNameFromTranscript(
          transcript: transcript,
          groups: groups,
        );
    final title = VoiceTaskTitleSanitizer.sanitize(
      _capitalizeFirst(text),
      stripDateHints: dateStr != null,
      stripTimeHints: timeStr != null,
    );

    return VoiceReminderHeuristicResult(
      confident: true,
      task: ExtractedVoiceTaskDto(
        title: title,
        groupName: inferredGroup,
        date: dateStr,
        time: timeStr,
      ),
    );
  }

  /// Extrai data/hora a partir de expressões relativas no texto.
  static ({String date, String time})? extractRelativeSchedule(
    String text,
    DateTime referenceDate,
  ) {
    final norm = removeDiacritics(text);
    final mMin = _relativeMinutes.firstMatch(norm);
    if (mMin != null) {
      final offset = _parseCount(mMin.group(1), mMin.group(2));
      if (offset == null) return null;
      final target = referenceDate.add(Duration(minutes: offset));
      return (
        date: localCalendarDayKey(target),
        time:
            '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}',
      );
    }
    final mHour = _relativeHours.firstMatch(norm);
    if (mHour != null) {
      final offset = _parseCount(mHour.group(1), mHour.group(2));
      if (offset == null) return null;
      final target = referenceDate.add(Duration(hours: offset));
      return (
        date: localCalendarDayKey(target),
        time:
            '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}',
      );
    }
    return null;
  }

  static int? _parseCount(String? digits, String? word) {
    if (digits != null && digits.isNotEmpty) {
      return int.tryParse(digits);
    }
    if (word == null || word.isEmpty) return null;
    return _wordToInt[removeDiacritics(word.toLowerCase())];
  }

  static String? _resolveRelativeDate(String text, DateTime ref) {
    final lower = text.toLowerCase();
    if (RegExp(r'depois de amanh', caseSensitive: false).hasMatch(lower)) {
      return localCalendarDayKey(ref.add(const Duration(days: 2)));
    }
    if (RegExp(r'\bamanh', caseSensitive: false).hasMatch(lower)) {
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
