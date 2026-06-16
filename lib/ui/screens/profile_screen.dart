import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../data/local/pending_reminder_prefs.dart';
import '../../data/local/voice_capture_prefs.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../theme/theme_mode_provider.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/eximium/eximium.dart';
import '../widgets/notification_permission_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _pendingReminderRepeatSeconds = kDefaultPendingReminderRepeatSeconds;
  bool _isLoadingPendingReminderPrefs = true;
  bool _isSavingPendingReminderPrefs = false;
  bool _voiceConfirmBeforeSave = true;
  bool _isLoadingVoiceCapturePrefs = true;
  bool _isSavingVoiceCapturePrefs = false;

  @override
  void initState() {
    super.initState();
    _loadPendingReminderPrefs();
    _loadVoiceCapturePrefs();
  }

  Future<void> _loadPendingReminderPrefs() async {
    final seconds = await loadPendingReminderRepeatSeconds();
    if (!mounted) return;
    setState(() {
      _pendingReminderRepeatSeconds = seconds;
      _isLoadingPendingReminderPrefs = false;
    });
  }

  Future<void> _loadVoiceCapturePrefs() async {
    final confirm = await loadVoiceConfirmBeforeSave();
    if (!mounted) return;
    setState(() {
      _voiceConfirmBeforeSave = confirm;
      _isLoadingVoiceCapturePrefs = false;
    });
  }

  Future<void> _saveVoiceConfirmBeforeSave(bool value) async {
    if (_isSavingVoiceCapturePrefs || value == _voiceConfirmBeforeSave) {
      return;
    }
    setState(() {
      _voiceConfirmBeforeSave = value;
      _isSavingVoiceCapturePrefs = true;
    });
    try {
      await saveVoiceConfirmBeforeSave(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferência de ditado atualizada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar preferência: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingVoiceCapturePrefs = false);
      }
    }
  }

  Future<void> _editDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ctrl = TextEditingController(text: user.displayName?.trim() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome exibido'),
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
            child: const Text('Salvar'),
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

  Future<void> _savePendingReminderRepeatSeconds(int seconds) async {
    if (_isSavingPendingReminderPrefs ||
        seconds == _pendingReminderRepeatSeconds) {
      return;
    }

    setState(() {
      _pendingReminderRepeatSeconds = seconds;
      _isSavingPendingReminderPrefs = true;
    });

    try {
      await savePendingReminderRepeatSeconds(seconds);

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

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar suas tarefas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ExColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  Future<void> _openNotificationPermissionSettings() async {
    final ns = ref.read(notificationServiceProvider);
    await ns.initialize();
    final hasNotif = await ns.hasPermission();
    final hasAlarm = await ns.hasAlarmPermission();
    if (!mounted) return;
    if (hasNotif && hasAlarm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissões de lembrete já estão ativas.'),
        ),
      );
      return;
    }
    await showNotificationPermissionSheet(
      context,
      notificationService: ns,
      needsNotif: !hasNotif,
      needsAlarm: !hasAlarm,
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    final c = context.ex;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return ExCard(
      child: Row(
        children: [
          _settingIconTile(
            context,
            icon: Icons.dark_mode_outlined,
            accent: true,
          ),
          const SizedBox(width: ExSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? 'Tema escuro' : 'Tema claro',
                  style: ExText.h3(c.textPrimary),
                ),
                const SizedBox(height: 1),
                Text(
                  'Escuro por padrão, claro como par',
                  style: ExText.body(c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: ExSpace.s2),
          _ExToggle(
            value: isDark,
            onChanged: (v) => ref
                .read(themeModeProvider.notifier)
                .set(v ? ThemeMode.dark : ThemeMode.light),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPermissionCard(BuildContext context) {
    final c = context.ex;
    return ExCard(
      onTap: _openNotificationPermissionSettings,
      child: Row(
        children: [
          _settingIconTile(
            context,
            icon: Icons.notifications_outlined,
            accent: false,
          ),
          const SizedBox(width: ExSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permissões de lembrete',
                  style: ExText.h3(c.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 1),
                Text(
                  'Notificações e alarmes exatos',
                  style: ExText.body(c.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textMuted),
        ],
      ),
    );
  }

  Widget _buildPendingReminderSettings(BuildContext context) {
    final c = context.ex;
    final isBusy =
        _isLoadingPendingReminderPrefs || _isSavingPendingReminderPrefs;

    return ExCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _settingIconTile(
                context,
                icon: Icons.notifications_active_outlined,
                accent: true,
              ),
              const SizedBox(width: ExSpace.s3),
              Expanded(
                child: Text(
                  'Lembretes pendentes',
                  style: ExText.h3(c.textPrimary),
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
          const SizedBox(height: ExSpace.s2),
          Text(
            'Repetir a notificação enquanto a tarefa agendada não for concluída.',
            style: ExText.body(c.textSecondary),
          ),
          const SizedBox(height: ExSpace.s4),
          DropdownButtonFormField<int>(
            key: ValueKey(_pendingReminderRepeatSeconds),
            initialValue: _pendingReminderRepeatSeconds,
            decoration: const InputDecoration(labelText: 'Repetir a cada'),
            items: kPendingReminderRepeatSecondOptions
                .map(
                  (seconds) => DropdownMenuItem<int>(
                    value: seconds,
                    child: Text(pendingReminderRepeatLabel(seconds)),
                  ),
                )
                .toList(),
            onChanged: isBusy
                ? null
                : (seconds) {
                    if (seconds == null) return;
                    _savePendingReminderRepeatSeconds(seconds);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCaptureSettings(BuildContext context) {
    final c = context.ex;
    final isBusy = _isLoadingVoiceCapturePrefs || _isSavingVoiceCapturePrefs;

    return ExCard(
      child: Row(
        children: [
          _settingIconTile(
            context,
            icon: Icons.mic_none_outlined,
            accent: true,
          ),
          const SizedBox(width: ExSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ditado por voz', style: ExText.h3(c.textPrimary)),
                const SizedBox(height: 1),
                Text(
                  'Confirmar antes de salvar',
                  style: ExText.body(c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: ExSpace.s2),
          if (isBusy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            _ExToggle(
              value: _voiceConfirmBeforeSave,
              onChanged: (v) => _saveVoiceConfirmBeforeSave(v),
            ),
        ],
      ),
    );
  }

  Widget _settingIconTile(
    BuildContext context, {
    required IconData icon,
    required bool accent,
  }) {
    final c = context.ex;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent
            ? ExColors.brandGreen.withValues(alpha: 0.14)
            : c.surface2,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        size: 20,
        color: accent ? c.textAccent : c.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final user = ref.watch(authStateProvider).value;
    final displayName = user?.displayName ?? user?.email ?? 'Usuário';
    final photoUrl = user?.photoURL;
    final invitesAsync = ref.watch(pendingInvitesStreamProvider);
    final emailAddr = user?.email?.trim();
    final hasEmail = emailAddr != null && emailAddr.isNotEmpty;

    return Scaffold(
      body: ExAppBackground(
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ExSpace.s5,
              ExSpace.s1,
              ExSpace.s5,
              ExSpace.s8,
            ),
            children: [
              Text('Perfil', style: ExText.h1(c.textPrimary)),
              const SizedBox(height: ExSpace.s5),
              Row(
                children: [
                  CustomAvatar(
                    photoUrl: photoUrl,
                    displayName: displayName,
                    radius: 31,
                  ),
                  const SizedBox(width: ExSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: ExText.h2(c.textPrimary)),
                        if (emailAddr != null && emailAddr.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            emailAddr,
                            style: ExText.body(c.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: ExSpace.s2),
                  ExButton(
                    label: 'Nome',
                    icon: Icons.edit_outlined,
                    variant: ExButtonVariant.secondary,
                    size: ExButtonSize.sm,
                    onPressed: _editDisplayName,
                  ),
                ],
              ),
              const SizedBox(height: ExSpace.s6),
              _buildAppearanceCard(context),
              const SizedBox(height: ExSpace.s3),
              _buildNotificationPermissionCard(context),
              const SizedBox(height: ExSpace.s3),
              _buildPendingReminderSettings(context),
              const SizedBox(height: ExSpace.s3),
              _buildVoiceCaptureSettings(context),
              const SizedBox(height: ExSpace.s6),
              if (!hasEmail)
                Padding(
                  padding: const EdgeInsets.only(bottom: ExSpace.s4),
                  child: Text(
                    'Convites por e-mail requerem sessão com e-mail (Google ou e-mail/senha).',
                    style: ExText.body(c.warningText),
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
                      const ExSectionLabel(label: 'Convites pendentes'),
                      const SizedBox(height: ExSpace.s2),
                      ...invites.map(
                        (inv) => Padding(
                          padding: const EdgeInsets.only(bottom: ExSpace.s2),
                          child: ExCard(
                            padding: const EdgeInsets.all(ExSpace.s3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  inv.displayGroupLabel,
                                  style: ExText.h3(c.textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Convidou: ${inv.displayInviterLabel}',
                                  style: ExText.body(c.textSecondary),
                                ),
                                const SizedBox(height: ExSpace.s2),
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
                                                backgroundColor:
                                                    Colors.redAccent,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Recusar'),
                                    ),
                                    const SizedBox(width: ExSpace.s2),
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
                                                content:
                                                    Text('Entrou no grupo.'),
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
                                                backgroundColor:
                                                    Colors.redAccent,
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
                      const SizedBox(height: ExSpace.s4),
                    ],
                  );
                },
              ),
              const SizedBox(height: ExSpace.s2),
              ExButton(
                label: 'Sair da conta',
                icon: Icons.logout_rounded,
                variant: ExButtonVariant.danger,
                expand: true,
                size: ExButtonSize.lg,
                onPressed: _confirmSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle do DS: trilho pill verde + glow quando ativo, knob `onBrandGreen`.
class _ExToggle extends StatelessWidget {
  const _ExToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? ExColors.brandGreen : c.surface3,
            borderRadius: BorderRadius.circular(ExRadius.pill),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: ExColors.brandGreen.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? ExColors.onBrandGreen : c.surface1,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
