import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../data/local/pending_reminder_prefs.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../widgets/custom_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _pendingReminderRepeatMinutes = kDefaultPendingReminderRepeatMinutes;
  bool _isLoadingPendingReminderPrefs = true;
  bool _isSavingPendingReminderPrefs = false;

  @override
  void initState() {
    super.initState();
    _loadPendingReminderPrefs();
  }

  Future<void> _loadPendingReminderPrefs() async {
    final minutes = await loadPendingReminderRepeatMinutes();
    if (!mounted) return;
    setState(() {
      _pendingReminderRepeatMinutes = minutes;
      _isLoadingPendingReminderPrefs = false;
    });
  }

  Future<void> _editDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ctrl = TextEditingController(text: user.displayName?.trim() ?? '');
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nome atualizado.')));
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

  Future<void> _savePendingReminderRepeatMinutes(int minutes) async {
    if (_isSavingPendingReminderPrefs ||
        minutes == _pendingReminderRepeatMinutes) {
      return;
    }

    setState(() {
      _pendingReminderRepeatMinutes = minutes;
      _isSavingPendingReminderPrefs = true;
    });

    try {
      await savePendingReminderRepeatMinutes(minutes);

      final ns = ref.read(notificationServiceProvider);
      final tasks = ref
          .read(tasksStreamProvider)
          .maybeWhen(data: (tasks) => tasks, orElse: () => const []);
      for (final task in tasks.where((t) => t.reminderType == 'datetime')) {
        await ns.syncTaskDatetimeReminders(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuração de lembretes atualizada.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar lembretes: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPendingReminderPrefs = false);
      }
    }
  }

  Widget _buildPendingReminderSettings(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isBusy =
        _isLoadingPendingReminderPrefs || _isSavingPendingReminderPrefs;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lembretes pendentes',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isBusy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Repetir a notificação enquanto a tarefa agendada não for concluída.',
              style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              key: ValueKey(_pendingReminderRepeatMinutes),
              initialValue: _pendingReminderRepeatMinutes,
              decoration: const InputDecoration(labelText: 'Repetir a cada'),
              items: kPendingReminderRepeatMinuteOptions
                  .map(
                    (minutes) => DropdownMenuItem<int>(
                      value: minutes,
                      child: Text(pendingReminderRepeatLabel(minutes)),
                    ),
                  )
                  .toList(),
              onChanged: isBusy
                  ? null
                  : (minutes) {
                      if (minutes == null) return;
                      _savePendingReminderRepeatMinutes(minutes);
                    },
            ),
          ],
        ),
      ),
    );
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
          _buildPendingReminderSettings(context),
          const SizedBox(height: 24),
          if (!hasEmail)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Convites por e-mail requerem sessão com e-mail (Google ou e-mail/palavra-passe).',
                style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Entrou no grupo.'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
