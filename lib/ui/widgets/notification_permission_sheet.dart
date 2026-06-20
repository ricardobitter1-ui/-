import 'package:flutter/material.dart';

import '../../data/services/notification_service.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import 'eximium/eximium.dart';

/// Sheet para pedir permissões de notificação e alarme exato.
/// [dismissible] true no Perfil; false só se quiser forçar (não usar na home).
Future<void> showNotificationPermissionSheet(
  BuildContext context, {
  required NotificationService notificationService,
  required bool needsNotif,
  required bool needsAlarm,
  bool dismissible = true,
  VoidCallback? onConfigured,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: dismissible,
    enableDrag: dismissible,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ExRadius.xl)),
    ),
    builder: (ctx) {
      final c = ctx.ex;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          ExSpace.s6,
          ExSpace.s3,
          ExSpace.s6,
          ExSpace.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: ExSpace.s5),
              decoration: BoxDecoration(
                color: c.surface3,
                borderRadius: BorderRadius.circular(ExRadius.pill),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ExColors.brandGreen.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                size: 32,
                color: c.textAccent,
              ),
            ),
            const SizedBox(height: ExSpace.s4),
            Text(
              'Não perca seus lembretes!',
              style: ExText.h1(c.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ExSpace.s3),
            Text(
              needsAlarm
                  ? 'Para que os lembretes toquem na hora exata, ative as notificações e a permissão de Alarmes e Lembretes nas configurações.'
                  : 'Precisamos que você libere as notificações para o app avisar na hora do lembrete.',
              textAlign: TextAlign.center,
              style: ExText.bodyLg(c.textSecondary),
            ),
            const SizedBox(height: ExSpace.s6),
            ExButton(
              label: 'Configurar permissões',
              expand: true,
              size: ExButtonSize.lg,
              onPressed: () async {
                await notificationService.requestPermission();
                if (ctx.mounted) Navigator.pop(ctx);
                onConfigured?.call();
              },
            ),
            if (dismissible)
              Padding(
                padding: const EdgeInsets.only(top: ExSpace.s2),
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Agora não', style: ExText.h3(c.textSecondary)),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// Pede permissões se ainda faltarem (ex.: ao salvar primeira tarefa com lembrete).
Future<void> ensureNotificationPermissionsIfNeeded(
  BuildContext context,
  NotificationService ns,
) async {
  await ns.initialize();
  final hasNotif = await ns.hasPermission();
  final hasAlarm = await ns.hasAlarmPermission();
  if (!hasNotif || !hasAlarm) {
    if (!context.mounted) return;
    await showNotificationPermissionSheet(
      context,
      notificationService: ns,
      needsNotif: !hasNotif,
      needsAlarm: !hasAlarm,
    );
  }
}
