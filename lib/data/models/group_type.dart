/// Tipo de grupo — define comportamento via [GroupTypeConfig].
enum GroupType {
  tasks,
  continuous,
  /// Reservado para fase futura (sem UI na v1).
  project,
  /// Reservado para fase futura (sem UI na v1).
  routine,
}

const _kGroupTypeTasks = 'tasks';
const _kGroupTypeContinuous = 'continuous';
const _kGroupTypeProject = 'project';
const _kGroupTypeRoutine = 'routine';

GroupType groupTypeFromFirestore(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case _kGroupTypeContinuous:
      return GroupType.continuous;
    case _kGroupTypeProject:
      return GroupType.project;
    case _kGroupTypeRoutine:
      return GroupType.routine;
    case _kGroupTypeTasks:
    case null:
    case '':
      return GroupType.tasks;
    default:
      return GroupType.tasks;
  }
}

String groupTypeToFirestore(GroupType type) {
  switch (type) {
    case GroupType.tasks:
      return _kGroupTypeTasks;
    case GroupType.continuous:
      return _kGroupTypeContinuous;
    case GroupType.project:
      return _kGroupTypeProject;
    case GroupType.routine:
      return _kGroupTypeRoutine;
  }
}

/// Tipos disponíveis na UI de criação/edição (v1).
const kGroupTypeTemplatesV1 = [GroupType.tasks, GroupType.continuous];
