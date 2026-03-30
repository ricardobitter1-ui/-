import 'package:cloud_firestore/cloud_firestore.dart';

/// Convite para entrada num grupo.
///
/// IDs de documento:
/// - Por UID: `{groupId}_{inviteeUid}` (legado).
/// - Por e-mail: `{groupId}_{inviteeEmailLower}` (e-mail normalizado em minúsculas).
class GroupInviteModel {
  final String id;
  final String groupId;
  /// Vazio para convites só por e-mail até aceitar.
  final String inviteeUid;
  final String invitedBy;
  final String status; // pending | accepted | declined | revoked
  final DateTime createdAt;
  final String? inviteeEmailLower;
  final String? shareToken;
  final String? groupName;
  final String? inviterName;

  const GroupInviteModel({
    required this.id,
    required this.groupId,
    required this.inviteeUid,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    this.inviteeEmailLower,
    this.shareToken,
    this.groupName,
    this.inviterName,
  });

  static String documentIdForUid(String groupId, String inviteeUid) =>
      '${groupId}_$inviteeUid';

  /// [emailLower] já normalizado (trim + toLowerCase).
  static String documentIdForEmail(String groupId, String emailLower) =>
      '${groupId}_$emailLower';

  /// Compatível com o nome antigo.
  static String documentId(String groupId, String inviteeUid) =>
      documentIdForUid(groupId, inviteeUid);

  String get displayGroupLabel =>
      (groupName != null && groupName!.trim().isNotEmpty)
          ? groupName!.trim()
          : groupId;

  String get displayInviterLabel =>
      (inviterName != null && inviterName!.trim().isNotEmpty)
          ? inviterName!.trim()
          : invitedBy;

  factory GroupInviteModel.fromMap(String id, Map<String, dynamic> data) {
    return GroupInviteModel(
      id: id,
      groupId: data['groupId'] as String? ?? '',
      inviteeUid: data['inviteeUid'] as String? ?? '',
      invitedBy: data['invitedBy'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inviteeEmailLower: data['inviteeEmailLower'] as String?,
      shareToken: data['shareToken'] as String?,
      groupName: data['groupName'] as String?,
      inviterName: data['inviterName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'inviteeUid': inviteeUid,
      'invitedBy': invitedBy,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (inviteeEmailLower != null) 'inviteeEmailLower': inviteeEmailLower,
      if (shareToken != null) 'shareToken': shareToken,
      if (groupName != null) 'groupName': groupName,
      if (inviterName != null) 'inviterName': inviterName,
    };
  }
}
