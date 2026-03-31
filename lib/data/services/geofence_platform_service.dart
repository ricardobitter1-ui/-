import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';

import '../../constants/geofence_constants.dart';
import '../models/task_model.dart';

/// Canal nativo Android: [GeofencingClient] + notificação no [GeofenceBroadcastReceiver].
class GeofencePlatformService {
  GeofencePlatformService._();

  static const MethodChannel _channel =
      MethodChannel('com.exmtodo.todo_app/geofence');

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Substitui a lista de geofences no SO pelas tarefas elegíveis (até [kMaxRegisteredGeofences]).
  static Future<void> syncWithTasks(List<TaskModel> tasks) async {
    if (!supported) return;
    final eligible = tasks
        .where(
          (t) =>
              t.id.isNotEmpty &&
              taskNeedsGeofenceSync(t),
        )
        .take(kMaxRegisteredGeofences)
        .toList();

    final payload = eligible.map((t) {
      final body = t.description.trim().isEmpty
          ? 'Lembrete de tarefa por localização'
          : t.description.trim();
      return <String, dynamic>{
        'taskId': t.id,
        'latitude': t.latitude,
        'longitude': t.longitude,
        'radiusMeters': effectiveGeofenceRadiusMeters(t),
        'locationTrigger': t.locationTrigger ?? 'arrival',
        'title': t.title,
        'body': body,
      };
    }).toList();

    try {
      await _channel.invokeMethod<void>('sync', payload);
    } on PlatformException catch (e) {
      debugPrint('GeofencePlatformService.sync failed: ${e.message}');
    }
  }
}
