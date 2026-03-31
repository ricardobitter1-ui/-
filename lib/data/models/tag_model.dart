import 'package:cloud_firestore/cloud_firestore.dart';

/// Etiqueta escopada a um grupo (`groups/{groupId}/tags/{id}`).
class TagModel {
  final String id;
  final String groupId;
  final String name;
  /// Valor compatível com [Color.value] (ex. `0xFF2196F3`).
  final int color;

  const TagModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.color,
  });

  factory TagModel.fromDoc(
    DocumentSnapshot doc, {
    required String groupId,
  }) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return TagModel(
      id: doc.id,
      groupId: groupId,
      name: (m['name'] as String?)?.trim() ?? '',
      color: (m['color'] as num?)?.toInt() ?? 0xFF2196F3,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': color,
      };
}
