import '../data/models/task_model.dart';
import '../data/models/user_public_profile.dart';
import '../utils/calendar_day_key.dart';

/// Evento resumido para o feed de atividade do grupo.
class GroupActivityEvent {
  final String label;
  final DateTime at;

  const GroupActivityEvent({required this.label, required this.at});
}

/// Monta eventos recentes a partir das tarefas do grupo (adições e conclusões).
List<GroupActivityEvent> buildGroupActivityFeed({
  required List<TaskModel> tasks,
  required Map<String, UserPublicProfile?> profiles,
  String Function(String uid, Map<String, UserPublicProfile?> profiles)?
      displayNameFor,
  DateTime? now,
  int maxEvents = 5,
  Duration window = const Duration(days: 7),
}) {
  final clock = now ?? DateTime.now();
  final cutoff = clock.subtract(window);
  final nameFor = displayNameFor ?? _defaultDisplayName;
  final events = <GroupActivityEvent>[];

  final addedByDayAndUser = <String, List<TaskModel>>{};
  for (final t in tasks) {
    final at = t.createdAt;
    final by = t.createdBy?.trim();
    if (at == null || by == null || by.isEmpty || at.isBefore(cutoff)) continue;
    final key = '${localCalendarDayKey(at)}|$by';
    addedByDayAndUser.putIfAbsent(key, () => []).add(t);
  }
  for (final entry in addedByDayAndUser.entries) {
    final count = entry.value.length;
    final by = entry.key.split('|').last;
    final at = entry.value
        .map((t) => t.createdAt!)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final who = nameFor(by, profiles);
    events.add(
      GroupActivityEvent(
        at: at,
        label: count == 1
            ? '$who adicionou 1 item'
            : '$who adicionou $count itens',
      ),
    );
  }

  final completedByDay = <String, int>{};
  for (final t in tasks) {
    final at = t.completedAt;
    if (at == null || at.isBefore(cutoff)) continue;
    final key = localCalendarDayKey(at);
    completedByDay[key] = (completedByDay[key] ?? 0) + 1;
  }
  for (final entry in completedByDay.entries) {
    final count = entry.value;
    final parts = entry.key.split('-');
    final at = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    events.add(
      GroupActivityEvent(
        at: at,
        label: count == 1
            ? '1 item concluído'
            : '$count itens concluídos',
      ),
    );
  }

  events.sort((a, b) => b.at.compareTo(a.at));
  return events.take(maxEvents).toList();
}

String _defaultDisplayName(
  String uid,
  Map<String, UserPublicProfile?> profiles,
) {
  final p = profiles[uid];
  final name = p?.displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return 'Alguém';
}
