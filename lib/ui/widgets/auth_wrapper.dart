import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/firebase_service.dart';
import '../screens/main_shell.dart';
import '../screens/login_screen.dart';
import 'pending_invite_coordinator.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  String? _lastSyncedUid;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    authState.whenData((user) {
      final uid = user?.uid;
      if (uid != null && uid != _lastSyncedUid) {
        _lastSyncedUid = uid;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(firebaseServiceProvider).ensureCollaborationBackfill();
          ref.read(fcmServiceProvider).syncTokenForCurrentUser();
        });
      }
      if (uid == null) {
        _lastSyncedUid = null;
      }
    });

    return authState.when(
      data: (user) {
        if (user != null) {
          return const PendingInviteCoordinator(child: MainShell());
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Erro na autenticação: $err'),
        ),
      ),
    );
  }
}
