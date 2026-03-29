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

/// Tarefas SEM data — alimenta o Dashboard Inbox (atemporais / backlog).
final atemporalTasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getAtemporalTasksStream();
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
/// Uso: ref.watch(groupTasksStreamProvider('groupId'))
final groupTasksStreamProvider =
    StreamProvider.family<List<TaskModel>, String>((ref, groupId) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getTasksByGroupStream(groupId);
});

