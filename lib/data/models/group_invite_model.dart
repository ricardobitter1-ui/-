import 'package:cloud_firestore/cloud_firestore.dart';

/// Convite para entrada num grupo. ID do documento: `{groupId}_{inviteeUid}`.
class GroupInviteModel {
  final String id;
  final String groupId;
  final String inviteeUid;
  final String invitedBy;
  final String status; // pending | accepted | declined | revoked
  final DateTime createdAt;

  const GroupInviteModel({
    required this.id,
    required this.groupId,
    required this.inviteeUid,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
  });

  static String documentId(String groupId, String inviteeUid) =>
      '${groupId}_$inviteeUid';

  factory GroupInviteModel.fromMap(String id, Map<String, dynamic> data) {
    return GroupInviteModel(
      id: id,
      groupId: data['groupId'] as String? ?? '',
      inviteeUid: data['inviteeUid'] as String? ?? '',
      invitedBy: data['invitedBy'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'inviteeUid': inviteeUid,
      'invitedBy': invitedBy,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
