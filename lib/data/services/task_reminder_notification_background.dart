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

Future<bool> _ensureFirebaseForBackgroundIsolate() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') return true;
    return false;
  } catch (_) {
    return false;
  }
}

/// No isolate de notificação, [currentUser] costuma vir `null` até a sessão
/// ser lida do disco; não confiar só na primeira leitura síncrona.
Future<String?> _waitForSignedInUid({
  Duration timeout = const Duration(seconds: 12),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }
  try {
    final user = await FirebaseAuth.instance
        .authStateChanges()
        .where((u) => u != null)
        .cast<User>()
        .timeout(const Duration(seconds: 2))
        .first;
    return user.uid;
  } on TimeoutException {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}

Future<void> _taskReminderNotificationBackgroundImpl(
  NotificationResponse response,
) async {
  if (response.actionId != NotificationService.kActionComplete) return;

  WidgetsFlutterBinding.ensureInitialized();

  final ok = await _ensureFirebaseForBackgroundIsolate();
  if (!ok) return;

  final uid = await _waitForSignedInUid();
  if (uid == null || uid.isEmpty) return;

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
