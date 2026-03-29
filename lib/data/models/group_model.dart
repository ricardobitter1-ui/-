import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String ownerId;
  final List<String> members;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.ownerId,
    required this.members,
    required this.createdAt,
  });

  /// Deserializa um documento do Firestore para GroupModel.
  /// Aplica defaults defensivos para campos ausentes.
  factory GroupModel.fromMap(String id, Map<String, dynamic> data) {
    return GroupModel(
      id: id,
      name: data['name'] as String? ?? 'Sem nome',
      icon: data['icon'] as String? ?? 'group',
      color: data['color'] as String? ?? '#0052FF',
      ownerId: data['ownerId'] as String? ?? '',
      members: List<String>.from(data['members'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serializa o GroupModel para um Map pronto para escrita no Firestore.
  /// Não inclui o campo `id` (é o ID do documento).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'ownerId': ownerId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Cria uma cópia do GroupModel com campos substituídos.
  /// Imutabilidade segura para uso com Riverpod.
  GroupModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? ownerId,
    List<String>? members,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GroupModel(id: $id, name: $name, icon: $icon, color: $color, members: ${members.length})';
}
