import 'package:flutter/material.dart';

/// Mapeia `GroupModel.icon` (Firestore / modal de criação) para ícone Material.
IconData groupIconFromKey(String key) {
  switch (key.trim()) {
    case 'work':
      return Icons.work_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'fitness_center':
      return Icons.fitness_center_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'group':
      return Icons.group_rounded;
    default:
      return Icons.groups_rounded;
  }
}
