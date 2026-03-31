import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/group_provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../widgets/custom_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _editDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ctrl = TextEditingController(
      text: user.displayName?.trim() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome a mostrar'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Como quer aparecer nos grupos',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) {
      ctrl.dispose();
      return;
    }

    final name = ctrl.text.trim();
    ctrl.dispose();

    try {
      await user.updateDisplayName(name.isEmpty ? null : name);
      await user.reload();
      await ref.read(firebaseServiceProvider).upsertCurrentUserProfile();
      ref.invalidate(authStateProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome atualizado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final displayName = user?.displayName ?? user?.email ?? 'Usuário';
    final photoUrl = user?.photoURL;
    final invitesAsync = ref.watch(pendingInvitesStreamProvider);
    final emailAddr = user?.email?.trim();
    final hasEmail = emailAddr != null && emailAddr.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              CustomAvatar(
                photoUrl: photoUrl,
                displayName: displayName,
                radius: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (emailAddr != null && emailAddr.isNotEmpty)
                      Text(
                        emailAddr,
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _editDisplayName,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Alterar nome a mostrar'),
          ),
          const SizedBox(height: 24),
          if (!hasEmail)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Convites por e-mail requerem sessão com e-mail (Google ou e-mail/palavra-passe).',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 13,
                ),
              ),
            ),
          invitesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (invites) {
              if (invites.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Convites pendentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...invites.map(
                    (inv) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              inv.displayGroupLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Convidou: ${inv.displayInviterLabel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(firebaseServiceProvider)
                                          .declineInviteByDocId(inv.id);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Erro: $e'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Recusar'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(firebaseServiceProvider)
                                          .acceptInviteByDocId(inv.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Entrou no grupo.',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Erro: $e'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Aceitar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair'),
            ),
          ),
        ],
      ),
    );
  }
}
