import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/group_model.dart';
import '../models/group_invite_model.dart';
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

  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _groupsCollection => _firestore.collection('groups');
  CollectionReference get _groupInvitesCollection =>
      _firestore.collection('groupInvites');

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
      createdBy: data['createdBy'],
      assigneeIds: List<String>.from(
        data['assigneeIds'] as List<dynamic>? ?? [],
      ),
    );
  }

  /// Tarefas pessoais (`ownerId`) + tarefas de grupos onde o utilizador é membro.
  ///
  /// Usa várias queries simples e funde os resultados no cliente. Isto evita
  /// `Filter.or` na coleção `tasks`, que o Firestore costuma rejeitar com
  /// `permission-denied` porque as security rules não conseguem provar o conjunto
  /// resultante para queries OR.
  Stream<List<TaskModel>> getTasksStream() {
    if (uid == null) return Stream.value([]);
    final userId = uid!;

    return _groupsCollection
        .where('members', arrayContains: userId)
        .snapshots()
        .asyncExpand((groupsSnapshot) {
      final groupIds = groupsSnapshot.docs.map((d) => d.id).toList();

      final personal = _tasksCollection
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .map((s) => s.docs.map(_taskFromDoc).toList());

      if (groupIds.isEmpty) {
        return personal;
      }

      const maxGroupStreams = 29;
      final capped = groupIds.length > maxGroupStreams
          ? groupIds.sublist(0, maxGroupStreams)
          : groupIds;

      final groupStreams = capped
          .map(
            (gid) => _tasksCollection
                .where('groupId', isEqualTo: gid)
                .snapshots()
                .map((s) => s.docs.map(_taskFromDoc).toList()),
          )
          .toList();

      return _mergeTaskStreams([personal, ...groupStreams]);
    });
  }

  /// Funde listas de tarefas por id (última versão por [TaskModel.id] vence).
  static Stream<List<TaskModel>> _mergeTaskStreams(
    List<Stream<List<TaskModel>>> streams,
  ) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first;

    final latest = List<List<TaskModel>?>.filled(streams.length, null);
    late StreamController<List<TaskModel>> controller;
    final subscriptions = <StreamSubscription<List<TaskModel>>>[];

    void emit() {
      if (latest.any((e) => e == null)) return;
      final byId = <String, TaskModel>{};
      for (final list in latest) {
        for (final t in list!) {
          byId[t.id] = t;
        }
      }
      if (!controller.isClosed) {
        controller.add(byId.values.toList());
      }
    }

    controller = StreamController<List<TaskModel>>(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          final idx = i;
          subscriptions.add(
            streams[idx].listen(
              (list) {
                latest[idx] = list;
                emit();
              },
              onError: (Object e, StackTrace st) {
                if (!controller.isClosed) {
                  controller.addError(e, st);
                }
              },
            ),
          );
        }
      },
      onCancel: () {
        for (final s in subscriptions) {
          s.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  Stream<List<TaskModel>> getAtemporalTasksStream() {
    if (uid == null) return Stream.value([]);

    return getTasksStream().map(
      (tasks) => tasks.where((t) => t.dueDate == null).toList(),
    );
  }

  Stream<List<TaskModel>> getScheduledTasksStream(DateTime date) {
    if (uid == null) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return getTasksStream().map((tasks) {
      final filtered = tasks.where((t) {
        final d = t.dueDate;
        if (d == null) return false;
        return !d.isBefore(startOfDay) && d.isBefore(startOfNextDay);
      }).toList();
      filtered.sort(
        (a, b) => (a.dueDate ?? DateTime(0)).compareTo(b.dueDate ?? DateTime(0)),
      );
      return filtered;
    });
  }

  /// Stream direto por grupo (uma query). Preferível ao filtro em cima de
  /// [getTasksStream] para o ecrã de detalhe e para alinhar com as rules.
  Stream<List<TaskModel>> getTasksByGroupStream(String groupId) {
    if (uid == null) return Stream.value([]);
    final gid = groupId.trim();
    if (gid.isEmpty) return Stream.value([]);

    return _tasksCollection
        .where('groupId', isEqualTo: gid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_taskFromDoc).toList());
  }

  Future<void> addTask(TaskModel task) async {
    if (uid == null) throw Exception('Usuário não autenticado');

    final taskData = task.toMap()..remove('id');
    taskData['ownerId'] = uid;
    taskData['createdBy'] = uid;
    taskData['createdAt'] = FieldValue.serverTimestamp();

    await _tasksCollection.add(taskData);
  }

  Future<void> toggleTaskCompletion(String taskId, bool currentStatus) async {
    await _tasksCollection.doc(taskId).update({'isCompleted': !currentStatus});
  }

  Future<void> updateTask(TaskModel task) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final taskData = task.toMap()..remove('id');
    await _tasksCollection.doc(task.id).update(taskData);
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

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

  /// Preenche `members` / `admins` / `isPersonal` em grupos antigos (ex.: "Pessoal" sem lista).
  Future<void> ensureCollaborationBackfill() async {
    if (uid == null) return;
    final owned = await _groupsCollection.where('ownerId', isEqualTo: uid).get();
    for (final doc in owned.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final members = List<String>.from(data['members'] as List<dynamic>? ?? []);
      if (members.isNotEmpty) continue;
      final isDefault = data['isDefault'] as bool? ?? false;
      final name = data['name'] as String? ?? '';
      await doc.reference.update({
        'members': [uid],
        'admins': [uid],
        'isPersonal': data['isPersonal'] == true || isDefault || name == 'Pessoal',
      });
    }
  }

  Future<void> addGroup(GroupModel group) async {
    if (uid == null) throw Exception('Usuário não autenticado');

    final groupData = group.toMap();
    groupData['ownerId'] = uid;
    groupData['members'] = [uid];
    groupData['admins'] = [uid];
    groupData['isPersonal'] = false;
    groupData['createdAt'] = FieldValue.serverTimestamp();

    await _groupsCollection.add(groupData);
  }

  /// Atualiza metadados (nome, ícone, cor). Requer admin do grupo nas rules.
  Future<void> updateGroup(GroupModel group) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    if (!group.isAdmin(uid)) {
      throw Exception('Apenas administradores podem editar o grupo');
    }

    await _groupsCollection.doc(group.id).update({
      'name': group.name,
      'icon': group.icon,
      'color': group.color,
    });
  }

  Future<void> deleteGroup(String groupId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final snap = await _groupsCollection.doc(groupId).get();
    if (!snap.exists) return;
    final g = GroupModel.fromMap(
      groupId,
      snap.data() as Map<String, dynamic>,
    );
    if (g.ownerId != uid) {
      throw Exception('Apenas o dono pode apagar o grupo');
    }
    await _groupsCollection.doc(groupId).delete();
  }

  // ─── Convites ───────────────────────────────────────────────────────────────

  Future<void> createInvite({
    required String groupId,
    required String inviteeUid,
  }) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final invitee = inviteeUid.trim();
    if (invitee.isEmpty) throw Exception('UID do convidado inválido');
    if (invitee == uid) throw Exception('Não pode convidar a si próprio');

    final groupSnap = await _groupsCollection.doc(groupId).get();
    if (!groupSnap.exists) throw Exception('Grupo não encontrado');
    final group = GroupModel.fromMap(
      groupId,
      groupSnap.data() as Map<String, dynamic>,
    );
    if (group.isPersonal) {
      throw Exception('Grupo pessoal não pode ser partilhado');
    }
    if (!group.isAdmin(uid)) {
      throw Exception('Apenas administradores podem convidar');
    }
    if (group.isMember(invitee)) {
      throw Exception('Este utilizador já é membro');
    }

    final inviteId = GroupInviteModel.documentId(groupId, invitee);
    final inviteRef = _groupInvitesCollection.doc(inviteId);
    final existing = await inviteRef.get();
    if (existing.exists) {
      final st = (existing.data() as Map<String, dynamic>)['status'] as String?;
      if (st == 'pending') {
        throw Exception('Já existe um convite pendente para este utilizador');
      }
      await inviteRef.delete();
    }
    await inviteRef.set({
      'groupId': groupId,
      'inviteeUid': invitee,
      'invitedBy': uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Convites pendentes onde o utilizador atual é o convidado.
  Stream<List<GroupInviteModel>> getPendingInvitesForMeStream() {
    if (uid == null) return Stream.value([]);

    return _groupInvitesCollection
        .where('inviteeUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => GroupInviteModel.fromMap(
                  d.id,
                  d.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  /// Aceita em dois passos (exigido pelas security rules).
  Future<void> acceptInvite(String groupId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final inviteId = GroupInviteModel.documentId(groupId, uid!);
    final inviteRef = _groupInvitesCollection.doc(inviteId);
    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) throw Exception('Convite não encontrado');
    final st = (inviteSnap.data() as Map<String, dynamic>)['status'] as String?;
    if (st != 'pending') throw Exception('Convite já foi tratado');

    await inviteRef.update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });
    await _groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayUnion([uid!]),
    });
  }

  Future<void> declineInvite(String groupId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final inviteId = GroupInviteModel.documentId(groupId, uid!);
    final inviteRef = _groupInvitesCollection.doc(inviteId);
    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) return;
    final st = (inviteSnap.data() as Map<String, dynamic>)['status'] as String?;
    if (st != 'pending') return;

    await inviteRef.update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove um membro (e o seu papel de admin, se houver). Apenas admins.
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberUid,
  }) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final groupSnap = await _groupsCollection.doc(groupId).get();
    if (!groupSnap.exists) throw Exception('Grupo não encontrado');
    final group = GroupModel.fromMap(
      groupId,
      groupSnap.data() as Map<String, dynamic>,
    );
    if (!group.isAdmin(uid)) {
      throw Exception('Apenas administradores podem remover membros');
    }
    if (memberUid == group.ownerId) {
      throw Exception('Não é possível remover o dono do grupo');
    }
    await _groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayRemove([memberUid]),
      'admins': FieldValue.arrayRemove([memberUid]),
    });
  }
}
