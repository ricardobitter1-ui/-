import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_navigator.dart';
import '../../business_logic/complete_task_action.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import 'task_form_modal.dart';

/// Processa toques em lembretes locais (corpo + ações Concluir / Reprogramar).
class TaskNotificationCoordinator extends ConsumerStatefulWidget {
  const TaskNotificationCoordinator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TaskNotificationCoordinator> createState() =>
      _TaskNotificationCoordinatorState();
}

class _TaskNotificationCoordinatorState
    extends ConsumerState<TaskNotificationCoordinator> {
  StreamSubscription<NotificationResponse>? _sub;

  String? _lastDedupeKey;
  DateTime? _lastDedupeAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ns = ref.read(notificationServiceProvider);
      _sub = ns.notificationResponses.listen(_onStreamResponse);
      _handleNotificationResponse(ns.takeAppLaunchNotification());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onStreamResponse(NotificationResponse r) {
    _handleNotificationResponse(r);
  }

  bool _shouldSkipDedupe(NotificationResponse r) {
    final key = '${r.id}_${r.actionId ?? 'tap'}_${r.payload ?? ''}';
    final now = DateTime.now();
    if (_lastDedupeKey == key &&
        _lastDedupeAt != null &&
        now.difference(_lastDedupeAt!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastDedupeKey = key;
    _lastDedupeAt = now;
    return false;
  }

  void _handleNotificationResponse(NotificationResponse? response) {
    if (response == null) return;
    if (_shouldSkipDedupe(response)) return;
    final taskId = NotificationService.parseTaskIdFromPayload(response.payload);
    if (taskId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _process(taskId, response.actionId);
    });
  }

  void _snack(String message) {
    final c = rootNavigatorKey.currentContext;
    if (c == null) return;
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _process(String taskId, String? actionId) async {
    if (!mounted) return;

    final fs = ref.read(firebaseServiceProvider);
    final ns = ref.read(notificationServiceProvider);

    if (actionId == NotificationService.kActionComplete) {
      final task = await fs.fetchTaskById(taskId);
      if (!mounted) return;
      if (task == null) {
        _snack('Tarefa não encontrada.');
        return;
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (isOccurrenceCompletedOnCalendarDay(task, today)) {
        _snack('Tarefa já concluída.');
        return;
      }
      await completeTaskToggle(
        fs: fs,
        ns: ns,
        task: task,
        occurrenceCalendarDay: today,
      );
      if (!mounted) return;
      _snack('Tarefa concluída.');
      return;
    }

    final task = await fs.fetchTaskById(taskId);
    if (!mounted) return;
    if (task == null) {
      _snack('Tarefa não encontrada.');
      return;
    }

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final openSchedule = actionId == NotificationService.kActionReschedule;
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskFormModal(
        initialTask: task,
        showReminderQuickActions: true,
        openScheduleDialogOnOpen: openSchedule,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
