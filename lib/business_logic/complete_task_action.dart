import '../data/models/task_model.dart';
import '../data/services/firebase_service.dart';
import '../data/services/notification_service.dart';
import '../utils/calendar_day_key.dart';
import 'task_day_visibility.dart';
import 'task_occurrence_display.dart';

/// Retorna false se a série recorrente não tem ocorrência em [day] (e toggle foi ignorado).
Future<bool> completeTaskToggle({
  required FirebaseService fs,
  required NotificationService ns,
  required TaskModel task,
  DateTime? occurrenceCalendarDay,
}) async {
  if (isDatetimeRecurringTask(task)) {
    final now = DateTime.now();
    final day = occurrenceCalendarDay ??
        DateTime(now.year, now.month, now.day);
    if (!taskVisibleOnDay(task, day)) {
      return false;
    }
    final key = localCalendarDayKey(day);
    final done = task.completedOccurrenceDateKeys.contains(key);
    await fs.setOccurrenceDateKeyCompleted(task.id, key, !done);
    final nextKeys = !done
        ? (List<String>.from([...task.completedOccurrenceDateKeys, key])
          ..sort())
        : task.completedOccurrenceDateKeys.where((k) => k != key).toList();
    await ns.syncTaskDatetimeReminders(
      task.copyWith(
        completedOccurrenceDateKeys: nextKeys,
        isCompleted: false,
      ),
    );
    return true;
  }

  await fs.toggleTaskCompletion(task.id, task.isCompleted);
  await ns.afterToggleTaskCompletion(task);
  return true;
}
