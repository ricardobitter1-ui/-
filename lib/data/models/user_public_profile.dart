import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil público em `users/{uid}` (só campos seguros para mostrar a outros membros).
class UserPublicProfile {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final DateTime? updatedAt;

  const UserPublicProfile({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.updatedAt,
  });

  /// Rótulo para UI: nome guardado ou fallback quando vazio / doc em falta.
  String get resolvedLabel {
    final t = displayName.trim();
    if (t.isNotEmpty) return t;
    return fallbackForUid(uid);
  }

  static String fallbackForUid(String uid) {
    if (uid.isEmpty) return 'Membro';
    if (uid.length <= 10) return uid;
    return '…${uid.substring(uid.length - 8)}';
  }

  factory UserPublicProfile.fromMap(String uid, Map<String, dynamic> data) {
    final rawPhoto = data['photoUrl'] as String?;
    final photo = rawPhoto?.trim();
    return UserPublicProfile(
      uid: uid,
      displayName: (data['displayName'] as String?)?.trim() ?? '',
      photoUrl: (photo == null || photo.isEmpty) ? null : photo,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
