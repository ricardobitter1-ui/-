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
    String? timeStr;
    final tm =
        _timePattern.firstMatch(normForTime) ?? _timeBare.firstMatch(normForTime);
    if (tm != null) {
      final h = int.parse(tm.group(1)!);
      final m = tm.groupCount >= 2 && tm.group(2) != null
          ? int.parse(tm.group(2)!)
          : 0;
      timeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    var dateStr = _resolveRelativeDate(text, referenceDate);
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
