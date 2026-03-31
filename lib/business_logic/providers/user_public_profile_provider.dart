import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_public_profile.dart';
import '../../data/services/firebase_service.dart';

final _kMemberUidSep = String.fromCharCode(0x1E);

/// Chave estável para [groupMemberProfilesProvider] (UIDs ordenados, separador improvável).
String memberUidsCacheKey(Iterable<String> memberIds) {
  final list = memberIds.toList()..sort();
  return list.join(_kMemberUidSep);
}

/// Mapa uid → perfil (ou null se doc em falta). Cache de leitura no [FirebaseService]/sync.
final groupMemberProfilesProvider =
    FutureProvider.family<Map<String, UserPublicProfile?>, String>((ref, key) async {
  if (key.isEmpty) return {};
  final uids = key.split(_kMemberUidSep).where((e) => e.isNotEmpty).toSet();
  final svc = ref.watch(firebaseServiceProvider);
  return svc.getUserPublicProfiles(uids);
});

String memberDisplayLabel(String uid, Map<String, UserPublicProfile?> map) {
  final p = map[uid];
  if (p != null) return p.resolvedLabel;
  return UserPublicProfile.fallbackForUid(uid);
}

/// URL da foto: perfil Firestore; se for o utilizador atual, usa Auth como fallback.
String? memberPhotoUrl(
  String uid,
  Map<String, UserPublicProfile?> map, {
  String? selfUid,
  String? selfPhotoUrl,
}) {
  final fromDoc = map[uid]?.photoUrl;
  if (fromDoc != null && fromDoc.isNotEmpty) return fromDoc;
  if (selfUid != null && uid == selfUid) {
    final p = selfPhotoUrl?.trim();
    if (p != null && p.isNotEmpty) return p;
  }
  return null;
}
