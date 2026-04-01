import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../business_logic/recurrence_calculator.dart';
import '../../utils/calendar_day_key.dart';
import '../models/task_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  final StreamController<NotificationResponse> _responseController =
      StreamController<NotificationResponse>.broadcast();

  NotificationResponse? _appLaunchNotification;

  /// Respostas a toques na notificação ou nos botões (app em memória).
  Stream<NotificationResponse> get notificationResponses => _responseController.stream;

  static const String kCategoryTaskReminder = 'task_reminder';
  static const String kActionComplete = 'action_complete';
  static const String kActionReschedule = 'action_reschedule';

  /// Slots por tarefa (iOS ~64 agendadas no total; manter margem).
  static const int kTaskNotificationSlots = 48;

  /// Base estável para IDs derivados de [taskId] (positivo, espaço para +kTaskNotificationSlots).
  static int taskNotificationBaseId(String taskId) {
    if (taskId.isEmpty) return 1;
    var h = taskId.hashCode;
    if (h < 0) h = -h;
    return h % 2000000000;
  }

  static String reminderPayload(String taskId) {
    return jsonEncode({'v': 1, 'taskId': taskId});
  }

  static String? parseTaskIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      final id = decoded['taskId'];
      if (id is! String) return null;
      final t = id.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  static const List<AndroidNotificationAction> kTaskReminderAndroidActions = [
    AndroidNotificationAction(
      kActionComplete,
      'Concluir',
      showsUserInterface: true,
    ),
    AndroidNotificationAction(
      kActionReschedule,
      'Reprogramar',
      showsUserInterface: true,
    ),
  ];

  static NotificationDetails taskReminderNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel_id_v2',
        'Lembretes de Tarefas',
        channelDescription: 'Canal principal para alertas de tarefas no horário agendado.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        actions: kTaskReminderAndroidActions,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: kCategoryTaskReminder,
      ),
      macOS: DarwinNotificationDetails(
        categoryIdentifier: kCategoryTaskReminder,
      ),
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    print('DEBUG NOTIF: Timezone detectado: ${timeZoneInfo.identifier}');
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          kCategoryTaskReminder,
          actions: [
            DarwinNotificationAction.plain(
              kActionComplete,
              'Concluir',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              kActionReschedule,
              'Reprogramar',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('DEBUG NOTIF: Resposta: id=${details.id} actionId=${details.actionId}');
        if (!_responseController.isClosed) {
          _responseController.add(details);
        }
      },
    );
    _isInitialized = true;
    print('DEBUG NOTIF: Motor de notificações inicializado.');
  }

  /// Chamar uma vez no arranque ([main]) antes de [runApp] para não perder cold start com login pendente.
  Future<void> loadAppLaunchNotification() async {
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true &&
        details!.notificationResponse != null) {
      _appLaunchNotification = details.notificationResponse;
    }
  }

  /// Primeira resposta de cold start (consumida uma vez). O coordenador chama após autenticação.
  NotificationResponse? takeAppLaunchNotification() {
    final r = _appLaunchNotification;
    _appLaunchNotification = null;
    return r;
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

    print('DEBUG NOTIF: Solicitando permissão de Alarme Exato...');
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> scheduleTaskReminder(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String taskId,
  ) async {
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

    final payload = taskId.isEmpty ? null : reminderPayload(taskId);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: taskReminderNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
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
        final occKey = localCalendarDayKey(t);
        if (task.completedOccurrenceDateKeys.contains(occKey)) continue;
        final hasTime = rule.repeatHour != null ||
            task.dueHasTime ||
            t.hour != 0 ||
            t.minute != 0;
        if (!hasTime) continue;
        try {
          await scheduleTaskReminder(base + slot, task.title, body, t, task.id);
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
      await scheduleTaskReminder(base, task.title, body, due, task.id);
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
