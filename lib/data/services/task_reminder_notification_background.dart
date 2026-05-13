import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../business_logic/complete_task_action.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../firebase_options.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Isolate em background (Android / iOS): botão "Concluir" sem abrir a UI.
@pragma('vm:entry-point')
void taskReminderNotificationBackground(NotificationResponse response) {
  unawaited(_taskReminderNotificationBackgroundImpl(response));
}

Future<void> _taskReminderNotificationBackgroundImpl(
  NotificationResponse response,
) async {
  if (response.actionId != NotificationService.kActionComplete) return;

  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    return;
  }

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final fs = FirebaseService(uid);
  final ns = NotificationService();
  await ns.initialize();

  final taskId = NotificationService.parseTaskIdFromPayload(response.payload);
  if (taskId == null) {
    final nid = response.id;
    if (nid != null) await ns.cancelNotification(nid);
    return;
  }

  final task = await fs.fetchTaskById(taskId);
  if (task == null) {
    final nid = response.id;
    if (nid != null) await ns.cancelNotification(nid);
    return;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (isOccurrenceCompletedOnCalendarDay(task, today)) {
    final nid = response.id;
    if (nid != null) await ns.cancelNotification(nid);
    return;
  }

  await completeTaskToggle(
    fs: fs,
    ns: ns,
    task: task,
    occurrenceCalendarDay: today,
  );
  final nid = response.id;
  if (nid != null) await ns.cancelNotification(nid);
}
