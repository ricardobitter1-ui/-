import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_public_profile.dart';

final Map<String, UserPublicProfile?> _publicProfileReadCache = {};

void clearUserPublicProfileReadCache() => _publicProfileReadCache.clear();

/// Escreve `users/{uid}` a partir do [User] Auth (evita dependência circular com [FirebaseService]).
Future<void> upsertUserPublicProfileFromUser(User user) async {
  final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final dn = user.displayName?.trim() ?? '';
  final email = user.email?.trim() ?? '';
  final name = dn.isNotEmpty
      ? dn
      : (email.contains('@') ? email.split('@').first : 'Membro');

  final data = <String, dynamic>{
    'displayName': name,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  final photo = user.photoURL?.trim();
  if (photo != null && photo.isNotEmpty) {
    data['photoUrl'] = photo;
  }
  await doc.set(data, SetOptions(merge: true));
  _publicProfileReadCache.remove(user.uid);
}

/// Lê perfil com cache em memória (sessão). Usado por [FirebaseService].
Future<UserPublicProfile?> getCachedOrFetchUserPublicProfile(
  FirebaseFirestore db,
  String targetUid,
) async {
  if (targetUid.isEmpty) return null;
  if (_publicProfileReadCache.containsKey(targetUid)) {
    return _publicProfileReadCache[targetUid];
  }
  final snap = await db.collection('users').doc(targetUid).get();
  if (!snap.exists) {
    _publicProfileReadCache[targetUid] = null;
    return null;
  }
  final data = snap.data();
  if (data == null) {
    _publicProfileReadCache[targetUid] = null;
    return null;
  }
  final p = UserPublicProfile.fromMap(targetUid, data);
  _publicProfileReadCache[targetUid] = p;
  return p;
}
