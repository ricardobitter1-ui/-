import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/group_model.dart';
import 'auth_service.dart';

// Este provider agora observa o estado de autenticação e injeta o UID no serviço
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final authState = ref.watch(authStateProvider);
  return FirebaseService(authState.value?.uid);
});

class FirebaseService {
  final String? uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService(this.uid);

  // ─── Collections ─────────────────────────────────────────────────────────────

  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _groupsCollection => _firestore.collection('groups');

  // ─── Helper: Deserializa um doc de tarefa ────────────────────────────────────

  TaskModel _taskFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isCompleted: data['isCompleted'] ?? false,
      reminderType: data['reminderType'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      locationTrigger: data['locationTrigger'],
      ownerId: data['ownerId'],
      groupId: data['groupId'],
    );
  }

  // ─── TASK STREAMS ─────────────────────────────────────────────────────────────

  /// Stream de TODAS as tarefas do usuário (mantido para compatibilidade com HomeScreen).
  Stream<List<TaskModel>> getTasksStream() {
    if (uid == null) return Stream.value([]);

    return _tasksCollection
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_taskFromDoc).toList());
  }

  /// Stream de tarefas SEM data (atemporais).
  /// Implementado via [getTasksStream] + filtro local para não exigir índice composto
  /// (`ownerId` + `dueDate` + `createdAt`).
  Stream<List<TaskModel>> getAtemporalTasksStream() {
    if (uid == null) return Stream.value([]);

    return getTasksStream().map(
      (tasks) => tasks.where((t) => t.dueDate == null).toList(),
    );
  }

  /// Stream de tarefas agendadas para uma data específica — alimenta o Calendário.
  /// REQUER índice composto no Firestore: tasks → ownerId (ASC) + dueDate (ASC).
  /// Crie o índice em: Firebase Console → Firestore → Indexes → Add Index.
  Stream<List<TaskModel>> getScheduledTasksStream(DateTime date) {
    if (uid == null) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return _tasksCollection
        .where('ownerId', isEqualTo: uid)
        .where(
          'dueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('dueDate', isLessThan: Timestamp.fromDate(startOfNextDay))
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_taskFromDoc).toList());
  }

  /// Stream de tarefas de um grupo específico (com ou sem data).
  /// Implementado em cima de [getTasksStream] + filtro local para não usar query
  /// composta (`ownerId` + `groupId`), que exige índice no Firestore e em alguns
  /// dispositivos tem sido associado a travamentos na UI.
  Stream<List<TaskModel>> getTasksByGroupStream(String groupId) {
    if (uid == null) return Stream.value([]);
    final gid = groupId.trim();
    if (gid.isEmpty) return Stream.value([]);

    return getTasksStream().map(
      (tasks) => tasks.where((t) => t.groupId == gid).toList(),
    );
  }

  // ─── TASK CRUD ────────────────────────────────────────────────────────────────

  /// Adiciona uma nova tarefa atrelando o ownerId automaticamente.
  Future<void> addTask(TaskModel task) async {
    if (uid == null) throw Exception('Usuário não autenticado');

    final taskData = task.toMap()..remove('id');
    taskData['ownerId'] = uid;
    taskData['createdAt'] = FieldValue.serverTimestamp();

    await _tasksCollection.add(taskData);
  }

  /// Alterna status de Completo/Incompleto de uma tarefa.
  Future<void> toggleTaskCompletion(String taskId, bool currentStatus) async {
    await _tasksCollection.doc(taskId).update({'isCompleted': !currentStatus});
  }

  /// Atualiza uma tarefa existente.
  Future<void> updateTask(TaskModel task) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final taskData = task.toMap()..remove('id');
    await _tasksCollection.doc(task.id).update(taskData);
  }

  /// Remove uma tarefa.
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  // ─── GROUP STREAMS ────────────────────────────────────────────────────────────

  /// Stream de grupos onde o uid está na lista de membros.
  /// Usa array-contains para query eficiente no Firestore.
  Stream<List<GroupModel>> getGroupsStream() {
    if (uid == null) return Stream.value([]);

    return _groupsCollection
        .where('members', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => GroupModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  // ─── GROUP CRUD ───────────────────────────────────────────────────────────────

  /// Cria um novo grupo.
  /// Injeta automaticamente ownerId e members = [uid], ignorando os valores do modelo.
  Future<void> addGroup(GroupModel group) async {
    if (uid == null) throw Exception('Usuário não autenticado');

    final groupData = group.toMap();
    // Sobrescreve ownerId e members com valores seguros do servidor
    groupData['ownerId'] = uid;
    groupData['members'] = [uid];
    groupData['createdAt'] = FieldValue.serverTimestamp();

    await _groupsCollection.add(groupData);
  }

  /// Atualiza um grupo existente.
  /// Somente o dono do grupo pode editar.
  Future<void> updateGroup(GroupModel group) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    if (group.ownerId != uid) {
      throw Exception('Apenas o dono pode editar o grupo');
    }

    final groupData = group.toMap();
    await _groupsCollection.doc(group.id).update(groupData);
  }

  /// Remove um grupo pelo ID.
  Future<void> deleteGroup(String groupId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    await _groupsCollection.doc(groupId).delete();
  }
}
