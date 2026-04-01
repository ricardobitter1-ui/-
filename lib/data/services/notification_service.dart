import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../business_logic/recurrence_calculator.dart';
import '../models/task_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Slots por tarefa (iOS ~64 agendadas no total; manter margem).
  static const int kTaskNotificationSlots = 48;

  /// Base estável para IDs derivados de [taskId] (positivo, espaço para +kTaskNotificationSlots).
  static int taskNotificationBaseId(String taskId) {
    if (taskId.isEmpty) return 1;
    var h = taskId.hashCode;
    if (h < 0) h = -h;
    return h % 2000000000;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Fusos agora retornam Record (TimezoneInfo) ao invés de String
    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    print('DEBUG NOTIF: Timezone detectado: ${timeZoneInfo.identifier}');
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier)); 

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('DEBUG NOTIF: Notificação clicada: ${details.id}');
      },
    );
    _isInitialized = true;
    print('DEBUG NOTIF: Motor de notificações inicializado.');
  }

  Future<bool> hasPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    final bool? result = await androidImplementation?.areNotificationsEnabled();
    return result ?? false;
  }

  Future<bool> hasAlarmPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    final bool? result = await androidImplementation?.canScheduleExactNotifications();
    print('DEBUG NOTIF: Permissão de alarme exato: $result');
    return result ?? false;
  }

  Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    print('DEBUG NOTIF: Solicitando permissões POST_NOTIFICATIONS...');
    await androidImplementation?.requestNotificationsPermission();
    
    // Alarme exato pode exigir abrir configurações do sistema dependendo do Android
    print('DEBUG NOTIF: Solicitando permissão de Alarme Exato...');
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> scheduleTaskReminder(int id, String title, String body, DateTime scheduledTime) async {
    await initialize();

    final now = DateTime.now();
    print('DEBUG NOTIF: Tentando agendar ID: $id para $scheduledTime (Agora: $now)');

    if (scheduledTime.isBefore(now)) {
      print('DEBUG NOTIF: FALHA - Horário agendado está no passado.');
      return;
    }

    final hasAlarmPerm = await hasAlarmPermission();
    if (!hasAlarmPerm) {
       print('DEBUG NOTIF: AVISO - Sem permissão de Alarme Exato. O agendamento pode falhar ou atrasar.');
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
    print('DEBUG NOTIF: Agendando TZDateTime: $tzScheduledDate no local: ${tz.local.name}');
    
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel_id_v2', // Alterar ID força a criação de um canal limpo
            'Lembretes de Tarefas',
            channelDescription: 'Canal principal para alertas de tarefas no horário agendado.',
            importance: Importance.max, 
            priority: Priority.high,
            showWhen: true,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('DEBUG NOTIF: Sucesso ao agendar Notificação $id');
    } catch (e) {
      print('DEBUG NOTIF: ERRO CRÍTICO ao agendar: $e');
      rethrow;
    }
  }

  Future<void> testImmediateNotification() async {
    await initialize();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel_id_v2',
      'Test Channel',
      channelDescription: 'Canal de teste para verificar notificações.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 5));
    final tzTestTime = tz.TZDateTime.from(testTime, tz.local);
    
    print('DEBUG NOTIF: Agendando TESTE para daqui a 5 segundos: $tzTestTime');
    
    await _plugin.zonedSchedule(
      id: 999,
      title: 'Teste de Notificação',
      body: 'Se você está vendo isso, o motor de push está funcionando! 🚀',
      scheduledDate: tzTestTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancela uma notificação agendada específica
  Future<void> cancelNotification(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
    print('DEBUG NOTIF: Notificação $id cancelada.');
  }

  /// Remove todos os lembretes de data/hora associados a uma tarefa (incl. série recorrente).
  Future<void> cancelAllTaskReminderSlots(String taskId) async {
    await initialize();
    final base = taskNotificationBaseId(taskId);
    for (var i = 0; i < kTaskNotificationSlots; i++) {
      await _plugin.cancel(id: base + i);
    }
  }

  /// Agenda lembretes conforme [task] (datetime + opcional recorrência) ou cancela slots.
  Future<void> syncTaskDatetimeReminders(TaskModel task) async {
    await cancelAllTaskReminderSlots(task.id);
    if (task.id.isEmpty) return;
    if (task.isCompleted) return;
    if (task.reminderType != 'datetime') return;
    if (task.dueDate == null) return;

    final body = task.description.trim().isEmpty
        ? 'Hora de completar sua tarefa!'
        : task.description;

    final base = taskNotificationBaseId(task.id);
    final now = DateTime.now();

    if (task.recurrence != null) {
      final rule = task.recurrence!;
      final anchor = task.dueDate!;
      final dh = task.dueHasTime ? anchor.hour : null;
      final dm = task.dueHasTime ? anchor.minute : null;
      final times = RecurrenceCalculator.upcomingOccurrences(
        anchorDate: anchor,
        rule: rule,
        from: now,
        dueTimeHour: dh,
        dueTimeMinute: dm,
        maxCount: kTaskNotificationSlots,
      );
      var slot = 0;
      for (final t in times) {
        if (slot >= kTaskNotificationSlots) break;
        final hasTime = rule.repeatHour != null ||
            task.dueHasTime ||
            t.hour != 0 ||
            t.minute != 0;
        if (!hasTime) continue;
        try {
          await scheduleTaskReminder(base + slot, task.title, body, t);
        } catch (e) {
          print('DEBUG NOTIF: falha ao agendar slot $slot: $e');
        }
        slot++;
      }
      return;
    }

    if (!task.dueHasTime) return;
    final due = task.dueDate!;
    if (due.isBefore(now)) return;
    try {
      await scheduleTaskReminder(base, task.title, body, due);
    } catch (e) {
      print('DEBUG NOTIF: falha lembrete pontual: $e');
    }
  }

  /// Chamar após [FirebaseService.toggleTaskCompletion] com o estado da tarefa **antes** do toque.
  Future<void> afterToggleTaskCompletion(TaskModel taskBeforeToggle) async {
    if (taskBeforeToggle.id.isEmpty) return;
    if (!taskBeforeToggle.isCompleted) {
      await cancelAllTaskReminderSlots(taskBeforeToggle.id);
    } else {
      await syncTaskDatetimeReminders(
        taskBeforeToggle.copyWith(isCompleted: false),
      );
    }
  }
}
