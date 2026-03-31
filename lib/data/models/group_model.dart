import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/group_color_presets.dart';

class GroupModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String ownerId;
  final List<String> members;
  /// Administradores (subconjunto de [members]). Se vazio no Firestore, usa-se [ownerId].
  final List<String> admins;
  final bool isPersonal;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.ownerId,
    required this.members,
    this.admins = const [],
    this.isPersonal = false,
    required this.createdAt,
  });

  /// Lista efetiva de admins (fallback legacy: só o dono).
  List<String> get effectiveAdmins =>
      admins.isNotEmpty ? admins : (ownerId.isNotEmpty ? [ownerId] : []);

  bool isAdmin(String? uid) =>
      uid != null && effectiveAdmins.contains(uid);

  bool isMember(String? uid) => uid != null && members.contains(uid);

  factory GroupModel.fromMap(String id, Map<String, dynamic> data) {
    final owner = data['ownerId'] as String? ?? '';
    final memberList =
        List<String>.from(data['members'] as List<dynamic>? ?? []);
    final adminList =
        List<String>.from(data['admins'] as List<dynamic>? ?? []);
    final isDefault = data['isDefault'] as bool? ?? false;
    final personal = data['isPersonal'] as bool? ?? isDefault;
    return GroupModel(
      id: id,
      name: data['name'] as String? ?? 'Sem nome',
      icon: data['icon'] as String? ?? 'group',
      color: data['color'] as String? ?? kDefaultGroupColorHex,
      ownerId: owner,
      members: memberList,
      admins: adminList,
      isPersonal: personal,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'ownerId': ownerId,
      'members': members,
      'admins': effectiveAdmins,
      'isPersonal': isPersonal,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? ownerId,
    List<String>? members,
    List<String>? admins,
    bool? isPersonal,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      isPersonal: isPersonal ?? this.isPersonal,
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
