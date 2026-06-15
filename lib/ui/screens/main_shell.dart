import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/task_provider.dart';
import '../../data/models/task_model.dart';
import '../../data/services/geofence_platform_service.dart';
import '../../data/services/notification_service.dart';
import '../widgets/eximium/eximium.dart';
import 'groups_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 1; // default: Hoje (aba principal)

  Future<void> _syncDatetimeReminders(List<TaskModel> tasks) async {
    final ns = ref.read(notificationServiceProvider);
    for (final task in tasks.where((t) => t.reminderType == 'datetime')) {
      await ns.syncTaskDatetimeReminders(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tasksStreamProvider, (previous, next) {
      next.whenData((tasks) {
        GeofencePlatformService.syncWithTasks(tasks);
        unawaited(_syncDatetimeReminders(tasks));
      });
    });
    final screens = <Widget>[
      const GroupsScreen(),
      const HomeScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: ExBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          ExBottomNavItem(icon: Icons.groups_rounded, label: 'Grupos'),
          ExBottomNavItem(icon: Icons.home_rounded, label: 'Início'),
          ExBottomNavItem(icon: Icons.person_rounded, label: 'Perfil'),
        ],
      ),
    );
  }
}
