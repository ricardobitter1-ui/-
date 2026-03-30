import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_service.dart';
import '../../data/models/task_model.dart';

// ─── Provider original (mantido para compatibilidade — HomeScreen atual) ───────

/// Todas as tarefas do usuário em tempo real.
final tasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getTasksStream();
});

// ─── Providers especializados — Fase 2 ────────────────────────────────────────

/// Tarefas SEM data — derivadas de [tasksStreamProvider] (filtro `dueDate == null`).
/// Evita query Firestore com `where` + `isNull` + `orderBy`, que exige índice composto.
final atemporalTasksStreamProvider =
    Provider<AsyncValue<List<TaskModel>>>((ref) {
  return ref.watch(tasksStreamProvider).whenData(
        (tasks) => tasks.where((t) => t.dueDate == null).toList(),
      );
});

/// Tarefas agendadas para uma data específica — alimenta a aba Calendário.
/// Uso: ref.watch(scheduledTasksStreamProvider(DateTime.now()))
/// IMPORTANTE: Requer índice composto no Firestore (ownerId ASC + dueDate ASC).
final scheduledTasksStreamProvider =
    StreamProvider.family<List<TaskModel>, DateTime>((ref, date) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getScheduledTasksStream(date);
});

/// Tarefas de um grupo específico (com ou sem data).
/// Deriva de [tasksStreamProvider] (query só por `ownerId`, igual à Home) e filtra
/// por `groupId` no cliente. Evita query composta Firestore + índice e reduz risco
/// de ANR/travamento ao abrir o detalhe do grupo.
/// Uso: `ref.watch(groupTasksStreamProvider(groupId))` → [AsyncValue].
final groupTasksStreamProvider =
    Provider.family<AsyncValue<List<TaskModel>>, String>((ref, groupId) {
  final gid = groupId.trim();
  if (gid.isEmpty) {
    return const AsyncValue.data([]);
  }
  return ref.watch(tasksStreamProvider).whenData(
        (tasks) => tasks.where((t) => t.groupId == gid).toList(),
      );
});

