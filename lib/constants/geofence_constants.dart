import '../data/models/task_model.dart';

/// Limite conservador do Android (~100 geofences por app); margem de segurança.
const int kMaxRegisteredGeofences = 90;

/// Padrão quando a tarefa não tem raio salvo (dados antigos).
const double kDefaultGeofenceRadiusMeters = 100;

/// Mínimo oferecido na UI; abaixo disso o GPS costuma falhar em disparar.
const double kMinGeofenceRadiusMeters = 50;

bool taskNeedsGeofenceSync(TaskModel t) {
  if (t.isCompleted) return false;
  if (t.reminderType != 'location') return false;
  if (t.latitude == null || t.longitude == null) return false;
  return true;
}

double effectiveGeofenceRadiusMeters(TaskModel t) {
  final r = t.geofenceRadiusMeters;
  if (r != null && r >= kMinGeofenceRadiusMeters) return r;
  if (r != null && r > 0) return r;
  return kDefaultGeofenceRadiusMeters;
}
