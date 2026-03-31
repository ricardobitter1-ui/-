import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/group_color_presets.dart';
import '../models/task_model.dart';
import '../models/tag_model.dart';
import '../models/group_model.dart';
import '../models/group_invite_model.dart';
import '../models/user_public_profile.dart';
import '../../utils/title_search_key.dart';
import 'auth_service.dart';
import 'user_public_profile_sync.dart';

// Este provider agora observa o estado de autenticação e injeta o UID no serviço
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final authState = ref.watch(authStateProvider);
  return FirebaseService(authState.value?.uid);
});

class FirebaseService {
  final String? uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService(this.uid);

  /// Deep link `exmtodo://invite?token=…` (Spark).
  static Uri inviteUriFromShareToken(String shareToken) => Uri(
        scheme: 'exmtodo',
        host: 'invite',
        queryParameters: {'token': shareToken},
      );

  String _newShareToken() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Integrações: buscar por nome estável com a mesma normalização do app —
  /// `where('titleSearchKey', isEqualTo: normalizeTitleSearchKey(termo))` e filtros
  /// de escopo (`ownerId`, `groupId`, etc.). Índice composto conforme a query.
  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _groupsCollection => _firestore.collection('groups');
  CollectionReference get _groupInvitesCollection =>
      _firestore.collection('groupInvites');

  TaskModel _taskFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawKey = data['titleSearchKey'];
    final fromDoc = rawKey is String ? rawKey.trim() : null;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      resolvedSearchKey:
          (fromDoc != null && fromDoc.isNotEmpty) ? fromDoc : null,
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
      tagIds: List<String>.from(
        data['tagIds'] as List<dynamic>? ?? [],
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
    taskData['titleSearchKey'] = normalizeTitleSearchKey(task.title);
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
    taskData['titleSearchKey'] = normalizeTitleSearchKey(task.title);
    await _tasksCollection.doc(task.id).update(taskData);
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  // ─── Tags por grupo (`groups/{groupId}/tags/{tagId}`) ─────────────────────────

  Stream<List<TagModel>> streamGroupTags(String groupId) {
    if (uid == null) return Stream.value([]);
    final gid = groupId.trim();
    if (gid.isEmpty) return Stream.value([]);

    return _groupsCollection.doc(gid).collection('tags').snapshots().map((s) {
      final list = s.docs
          .map((d) => TagModel.fromDoc(d, groupId: gid))
          .toList();
      list.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return list;
    });
  }

  /// Etiquetas de outros grupos do utilizador (ex.: sugestões), com dedupe por nome+cor.
  Future<List<TagModel>> fetchSuggestionTagsExcludingGroup(
    String currentGroupId,
  ) async {
    if (uid == null) return [];
    final cur = currentGroupId.trim();
    final groupsSnap =
        await _groupsCollection.where('members', arrayContains: uid).get();
    final out = <TagModel>[];
    final seen = <String>{};
    for (final g in groupsSnap.docs) {
      if (g.id == cur) continue;
      final tagSnap = await _groupsCollection.doc(g.id).collection('tags').get();
      for (final d in tagSnap.docs) {
        final t = TagModel.fromDoc(d, groupId: g.id);
        final key = '${t.name.toLowerCase()}\u0000${t.color}';
        if (seen.contains(key)) continue;
        seen.add(key);
        out.add(t);
      }
    }
    out.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return out;
  }

  Future<String> addGroupTag({
    required String groupId,
    required String name,
    required int color,
  }) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final n = name.trim();
    if (n.isEmpty) throw Exception('Nome da etiqueta inválido');
    final ref = _groupsCollection.doc(groupId).collection('tags').doc();
    await ref.set({'name': n, 'color': color});
    return ref.id;
  }

  Future<void> updateGroupTag({
    required String groupId,
    required String tagId,
    required String name,
    required int color,
  }) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    await _groupsCollection
        .doc(groupId)
        .collection('tags')
        .doc(tagId)
        .update({
      'name': name.trim(),
      'color': color,
    });
  }

  Future<void> deleteGroupTag(String groupId, String tagId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final tasksSnap =
        await _tasksCollection.where('groupId', isEqualTo: groupId).get();

    WriteBatch batch = _firestore.batch();
    var n = 0;
    for (final doc in tasksSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final raw = data['tagIds'] as List<dynamic>? ?? [];
      final tids = raw.map((e) => e.toString()).toList();
      if (!tids.contains(tagId)) continue;
      tids.remove(tagId);
      batch.update(doc.reference, {'tagIds': tids});
      n++;
      if (n >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        n = 0;
      }
    }
    if (n > 0) {
      await batch.commit();
    }

    await _groupsCollection.doc(groupId).collection('tags').doc(tagId).delete();
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

  /// Cria/atualiza `users/{uid}` a partir do utilizador Auth atual.
  Future<void> upsertCurrentUserProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await upsertUserPublicProfileFromUser(u);
  }

  /// Lê perfil público (com cache em memória — ver [clearUserPublicProfileReadCache]).
  Future<UserPublicProfile?> getUserPublicProfile(String targetUid) {
    return getCachedOrFetchUserPublicProfile(_firestore, targetUid);
  }

  /// Vários perfis em paralelo (reutiliza cache por UID).
  Future<Map<String, UserPublicProfile?>> getUserPublicProfiles(
    Set<String> uids,
  ) async {
    final unique = uids.where((e) => e.isNotEmpty).toSet();
    final entries = await Future.wait(
      unique.map(
        (id) async => MapEntry(
          id,
          await getCachedOrFetchUserPublicProfile(_firestore, id),
        ),
      ),
    );
    return Map.fromEntries(entries);
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

  /// Uma vez por instalação: substitui cores legadas do picker v1 pelos presets pastel (v2)
  /// nos grupos em que o utilizador atual é admin.
  Future<void> migrateLegacyGroupColorsIfNeeded() async {
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(kGroupColorMigrationV2PrefsKey) == true) return;
    try {
      final snap =
          await _groupsCollection.where('members', arrayContains: uid).get();
      for (final doc in snap.docs) {
        final g = GroupModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
        if (!g.isAdmin(uid)) continue;
        final norm = normalizeGroupColorHexForLookup(g.color);
        final replacement = mapLegacyGroupColorToPreset(norm);
        if (replacement == null) continue;
        await updateGroup(g.copyWith(color: replacement));
      }
      await prefs.setBool(kGroupColorMigrationV2PrefsKey, true);
    } catch (_) {
      // Não marcar concluído — tenta noutro arranque.
    }
  }

  Future<void> deleteGroup(String groupId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final snap = await _groupsCollection.doc(groupId).get();
    if (!snap.exists) return;
    final g = GroupModel.fromMap(
      groupId,
      snap.data() as Map<String, dynamic>,
    );
    if (g.isPersonal) {
      throw Exception('Grupos pessoais não podem ser eliminados');
    }
    if (!g.isAdmin(uid)) {
      throw Exception('Apenas administradores podem apagar o grupo');
    }
    await _groupsCollection.doc(groupId).delete();
  }

  // ─── Convites ───────────────────────────────────────────────────────────────

  /// Convite por UID (legado / avançado). Inclui [shareToken] para link partilhável.
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

    final inviteId = GroupInviteModel.documentIdForUid(groupId, invitee);
    final inviteRef = _groupInvitesCollection.doc(inviteId);
    final existing = await inviteRef.get();
    if (existing.exists) {
      final st = (existing.data() as Map<String, dynamic>)['status'] as String?;
      if (st == 'pending') {
        throw Exception('Já existe um convite pendente para este utilizador');
      }
      await inviteRef.delete();
    }
    final inviterName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    await inviteRef.set({
      'groupId': groupId,
      'inviteeUid': invitee,
      'invitedBy': uid,
      'status': 'pending',
      'shareToken': _newShareToken(),
      'groupName': group.name,
      if (inviterName.isNotEmpty) 'inviterName': inviterName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Convite por e-mail (Spark): doc `{groupId}_{emailLower}` + [shareToken] para link.
  Future<void> createInviteByEmail({
    required String groupId,
    required String email,
  }) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final emailLower = email.trim().toLowerCase();
    if (emailLower.isEmpty || !emailLower.contains('@')) {
      throw Exception('E-mail inválido');
    }
    final me = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    if (me != null && emailLower == me) {
      throw Exception('Não pode convidar o seu próprio e-mail');
    }

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

    final inviteId = GroupInviteModel.documentIdForEmail(groupId, emailLower);
    final inviteRef = _groupInvitesCollection.doc(inviteId);
    final existing = await inviteRef.get();

    if (existing.exists) {
      final st = (existing.data() as Map<String, dynamic>)['status'] as String?;
      if (st == 'pending') {
        throw Exception('Já existe um convite pendente para este e-mail');
      }
      await inviteRef.delete();
    }
    final inviterName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    final token = _newShareToken();
    await inviteRef.set({
      'groupId': groupId,
      'inviteeUid': '',
      'inviteeEmailLower': emailLower,
      'invitedBy': uid,
      'status': 'pending',
      'shareToken': token,
      'groupName': group.name,
      if (inviterName.isNotEmpty) 'inviterName': inviterName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// URI do convite mais recente pendente do grupo (admin). `null` se não houver.
  Future<String?> getLatestPendingInviteShareUriForGroup(String groupId) async {
    if (uid == null) return null;
    final groupSnap = await _groupsCollection.doc(groupId).get();
    if (!groupSnap.exists) return null;
    final group = GroupModel.fromMap(
      groupId,
      groupSnap.data() as Map<String, dynamic>,
    );
    if (!group.isAdmin(uid)) return null;

    final snap = await _groupInvitesCollection
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data() as Map<String, dynamic>;
    final token = data['shareToken'] as String?;
    if (token == null || token.isEmpty) return null;
    return inviteUriFromShareToken(token).toString();
  }

  /// Resolve convite pendente pelo token do deep link (utilizador autenticado).
  Future<GroupInviteModel?> getPendingInviteByShareToken(String shareToken) async {
    if (uid == null) return null;
    final t = shareToken.trim();
    if (t.isEmpty) return null;
    final snap = await _groupInvitesCollection
        .where('shareToken', isEqualTo: t)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return GroupInviteModel.fromMap(d.id, d.data() as Map<String, dynamic>);
  }

  Stream<List<GroupInviteModel>> _mergeTwoInviteStreams(
    Stream<List<GroupInviteModel>> a,
    Stream<List<GroupInviteModel>> b,
  ) {
    return Stream<List<GroupInviteModel>>.multi((controller) {
      var lastA = <GroupInviteModel>[];
      var lastB = <GroupInviteModel>[];

      void emit() {
        final map = <String, GroupInviteModel>{};
        for (final i in lastA) {
          map[i.id] = i;
        }
        for (final i in lastB) {
          map[i.id] = i;
        }
        final out = map.values.toList()
          ..sort((x, y) => x.createdAt.compareTo(y.createdAt));
        controller.add(out);
      }

      final subA = a.listen(
        (list) {
          lastA = list;
          emit();
        },
        onError: controller.addError,
      );
      final subB = b.listen(
        (list) {
          lastB = list;
          emit();
        },
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await subA.cancel();
        await subB.cancel();
      };
    });
  }

  /// Convites pendentes: por UID ou por e-mail da sessão Auth.
  Stream<List<GroupInviteModel>> getPendingInvitesForMeStream() {
    if (uid == null) return Stream.value([]);

    final uidStream = _groupInvitesCollection
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

    final email = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      return uidStream;
    }

    final emailStream = _groupInvitesCollection
        .where('inviteeEmailLower', isEqualTo: email)
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

    return _mergeTwoInviteStreams(uidStream, emailStream);
  }

  /// Aceita convite (ID completo do documento). Atualiza [inviteeUid] em convites por e-mail.
  Future<void> acceptInviteByDocId(String inviteDocId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final inviteRef = _groupInvitesCollection.doc(inviteDocId);
    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) throw Exception('Convite não encontrado');
    final data = inviteSnap.data() as Map<String, dynamic>;
    final st = data['status'] as String?;
    if (st != 'pending') throw Exception('Convite já foi tratado');
    final groupId = data['groupId'] as String? ?? '';

    await inviteRef.update({
      'status': 'accepted',
      'inviteeUid': uid,
      'respondedAt': FieldValue.serverTimestamp(),
    });
    await _groupsCollection.doc(groupId).update({
      'members': FieldValue.arrayUnion([uid!]),
    });
  }

  Future<void> declineInviteByDocId(String inviteDocId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    final inviteRef = _groupInvitesCollection.doc(inviteDocId);
    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) return;
    final st = (inviteSnap.data() as Map<String, dynamic>)['status'] as String?;
    if (st != 'pending') return;

    await inviteRef.update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Compat: convite por UID com id `groupId_uid`.
  Future<void> acceptInvite(String groupId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    await acceptInviteByDocId(GroupInviteModel.documentIdForUid(groupId, uid!));
  }

  Future<void> declineInvite(String groupId) async {
    if (uid == null) throw Exception('Usuário não autenticado');
    await declineInviteByDocId(GroupInviteModel.documentIdForUid(groupId, uid!));
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
