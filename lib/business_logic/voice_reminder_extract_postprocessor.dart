import 'package:diacritic/diacritic.dart';

import '../data/models/extracted_voice_task_dto.dart';
import '../utils/title_search_key.dart';
import 'voice_reminder_heuristic_parser.dart';
import 'voice_task_title_sanitizer.dart';

/// Consolida e corrige extrações de lembrete (heurística ou LLM).
abstract final class VoiceReminderExtractPostprocessor {
  static List<ExtractedVoiceTaskDto> refine({
    required List<ExtractedVoiceTaskDto> tasks,
    required DateTime referenceDate,
  }) {
    if (tasks.isEmpty) return tasks;

    final enriched = tasks.map((dto) => _enrichSchedule(dto, referenceDate)).toList();
    final merged = _mergeByTitle(enriched);
    return merged.map(_cleanTemporalDescription).toList();
  }

  static ExtractedVoiceTaskDto _cleanTemporalDescription(ExtractedVoiceTaskDto dto) {
    final desc = dto.description.trim();
    if (desc.isEmpty || !_isOnlyTemporalText(desc)) return dto;
    return dto.copyWith(description: '');
  }

  static ExtractedVoiceTaskDto _enrichSchedule(
    ExtractedVoiceTaskDto dto,
    DateTime referenceDate,
  ) {
    if (dto.time != null && dto.time!.isNotEmpty) return dto;

    final schedule = VoiceReminderHeuristicParser.extractRelativeSchedule(
      dto.description,
      referenceDate,
    );
    if (schedule == null) return dto;

    var description = dto.description.trim();
    if (_isOnlyTemporalText(description)) {
      description = '';
    }

    return dto.copyWith(
      date: dto.date ?? schedule.date,
      time: schedule.time,
      description: description,
      title: VoiceTaskTitleSanitizer.sanitize(
        dto.title,
        stripDateHints: true,
        stripTimeHints: true,
      ),
    );
  }

  static bool _isOnlyTemporalText(String text) {
    final t = removeDiacritics(text.trim().toLowerCase());
    if (t.isEmpty) return false;
    return VoiceReminderHeuristicParser.extractRelativeSchedule(text, DateTime.now()) !=
        null;
  }

  static List<ExtractedVoiceTaskDto> _mergeByTitle(
    List<ExtractedVoiceTaskDto> tasks,
  ) {
    final byTitle = <String, ExtractedVoiceTaskDto>{};
    for (final dto in tasks) {
      final key = normalizeTitleSearchKey(dto.title);
      if (key.isEmpty) continue;
      final existing = byTitle[key];
      if (existing == null) {
        byTitle[key] = dto;
      } else {
        byTitle[key] = _pickBetterPair(existing, dto);
      }
    }
    return byTitle.values.toList();
  }

  static ExtractedVoiceTaskDto _pickBetterPair(
    ExtractedVoiceTaskDto a,
    ExtractedVoiceTaskDto b,
  ) {
    final aHasTime = a.time != null && a.time!.isNotEmpty;
    final bHasTime = b.time != null && b.time!.isNotEmpty;
    if (aHasTime && !bHasTime) return _mergeDescriptions(a, b);
    if (bHasTime && !aHasTime) return _mergeDescriptions(b, a);

    final aHasDate = a.date != null && a.date!.isNotEmpty;
    final bHasDate = b.date != null && b.date!.isNotEmpty;
    if (aHasDate && !bHasDate) return _mergeDescriptions(a, b);
    if (bHasDate && !aHasDate) return _mergeDescriptions(b, a);

    if (a.description.trim().isEmpty && b.description.trim().isNotEmpty) {
      return _mergeDescriptions(a, b);
    }
    if (b.description.trim().isEmpty && a.description.trim().isNotEmpty) {
      return _mergeDescriptions(b, a);
    }
    return a;
  }

  static ExtractedVoiceTaskDto _mergeDescriptions(
    ExtractedVoiceTaskDto primary,
    ExtractedVoiceTaskDto secondary,
  ) {
    final primaryDesc = primary.description.trim();
    final secondaryDesc = secondary.description.trim();
    if (primaryDesc.isNotEmpty || secondaryDesc.isEmpty) return primary;
    if (_isOnlyTemporalText(secondaryDesc)) return primary;
    return primary.copyWith(description: secondaryDesc);
  }
}
