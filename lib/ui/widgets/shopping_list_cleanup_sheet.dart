import 'package:flutter/material.dart';

import '../../business_logic/shopping_list_cleanup_plan.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/services/voice/tag_assignment_llm_service.dart';
import '../theme/app_theme.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';

Future<bool?> showShoppingListCleanupReviewSheet({
  required BuildContext context,
  required ShoppingListCleanupPlan plan,
  required List<TagModel> tags,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _ShoppingListCleanupReviewBody(
      plan: plan,
      tags: tags,
    ),
  );
}

class _ShoppingListCleanupReviewBody extends StatelessWidget {
  const _ShoppingListCleanupReviewBody({
    required this.plan,
    required this.tags,
  });

  final ShoppingListCleanupPlan plan;
  final List<TagModel> tags;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final changes = plan.changes;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rever limpeza automática',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2B2D42),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            changes.isEmpty
                ? 'Nada a alterar nesta lista.'
                : '${changes.length} alteração(ões) proposta(s). Confirme para aplicar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: changes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'A lista já está organizada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: changes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _ChangeTile(change: changes[i], tags: tags),
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: changes.isEmpty
                ? () => Navigator.pop(context, false)
                : () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              changes.isEmpty ? 'Fechar' : 'Guardar alterações',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangeTile extends StatelessWidget {
  const _ChangeTile({
    required this.change,
    required this.tags,
  });

  final ShoppingListCleanupChange change;
  final List<TagModel> tags;

  @override
  Widget build(BuildContext context) {
    final (:icon, :color, :title, :subtitle) = _describeChange(change);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color, String title, String? subtitle})
      _describeChange(ShoppingListCleanupChange change) {
    switch (change.type) {
      case ShoppingListCleanupChangeType.tagAssigned:
        return (
          icon: Icons.label_rounded,
          color: AppTheme.brandPrimary,
          title: change.task.title,
          subtitle: change.newTagName != null
              ? 'Etiqueta: ${change.newTagName}'
              : null,
        );
      case ShoppingListCleanupChangeType.duplicateRemoved:
        return (
          icon: Icons.content_copy_rounded,
          color: Colors.orange.shade700,
          title: 'Remover duplicado: ${change.task.title}',
          subtitle: change.relatedTask != null
              ? 'Mantém "${change.relatedTask!.title}"'
              : null,
        );
      case ShoppingListCleanupChangeType.duplicateReopened:
        return (
          icon: Icons.replay_rounded,
          color: Colors.green.shade700,
          title: 'Reativar: ${change.task.title}',
          subtitle: 'Estava concluído; volta para a lista ativa.',
        );
    }
  }
}

Future<bool> confirmShoppingListCleanupDialog(BuildContext context) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CleanupConfirmSheet(),
  );
  return ok == true;
}

/// Folha de confirmação da limpeza automática, no estilo do Eximium DS.
class _CleanupConfirmSheet extends StatelessWidget {
  const _CleanupConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ExRadius.xl),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 26 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // pega da folha
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: c.surface3,
                  borderRadius: BorderRadius.circular(ExRadius.pill),
                ),
              ),
            ),
            // ícone com gradiente
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ExRadius.lg),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ExColors.lavender.withValues(alpha: 0.18),
                      ExColors.brandGreen.withValues(alpha: 0.16),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 28,
                  color: c.infoText,
                ),
              ),
            ),
            const SizedBox(height: ExSpace.s4),
            Text(
              'Limpeza automática',
              textAlign: TextAlign.center,
              style: ExText.h1(c.textPrimary),
            ),
            const SizedBox(height: ExSpace.s2),
            Text(
              'A IA vai revisar sua lista e aplicar estas mudanças:',
              textAlign: TextAlign.center,
              style: ExText.bodyLg(c.textSecondary),
            ),
            const SizedBox(height: ExSpace.s5),
            _CleanupAction(
              icon: Icons.content_copy_rounded,
              tint: ExColors.brandGreen,
              tintText: c.successText,
              title: 'Remover duplicatas',
              subtitle: 'Itens repetidos são unificados',
            ),
            const SizedBox(height: ExSpace.s2 + 2),
            _CleanupAction(
              icon: Icons.sort_rounded,
              tint: ExColors.lavender,
              tintText: c.infoText,
              title: 'Organizar categorias',
              subtitle: 'Itens vão para a etiqueta certa',
            ),
            const SizedBox(height: ExSpace.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: c.textMuted),
                const SizedBox(width: ExSpace.s2),
                Text(
                  'Você poderá revisar antes de salvar.',
                  style: ExText.body(c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: ExSpace.s5),
            _PrimaryPillButton(
              label: 'Organizar lista',
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: ExSpace.s3 - 2),
            _GhostPillButton(
              label: 'Cancelar',
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de ação proposta dentro da folha de confirmação.
class _CleanupAction extends StatelessWidget {
  const _CleanupAction({
    required this.icon,
    required this.tint,
    required this.tintText,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color tint;
  final Color tintText;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(ExRadius.md + 4),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(ExRadius.md - 1),
            ),
            child: Icon(icon, size: 19, color: tintText),
          ),
          const SizedBox(width: ExSpace.s3 + 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ExText.body(c.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 1),
                Text(subtitle, style: ExText.body(c.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ExRadius.pill),
        boxShadow: [
          BoxShadow(
            color: ExColors.brandGreen.withValues(alpha: 0.4),
            blurRadius: 22,
          ),
        ],
      ),
      child: Material(
        color: ExColors.brandGreen,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: SizedBox(
            height: 50,
            child: Center(
              child: Text(
                label,
                style: ExText.h3(ExColors.onBrandGreen),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostPillButton extends StatelessWidget {
  const _GhostPillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: c.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(
              label,
              style: ExText.h3(c.textSecondary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> runShoppingListCleanupFlow({
  required BuildContext context,
  required List<TaskModel> tasks,
  required List<TagModel> tags,
  required Future<ShoppingListCleanupPlan> Function() buildPlan,
  required Future<void> Function(ShoppingListCleanupPlan plan) applyPlan,
}) async {
  final confirmed = await confirmShoppingListCleanupDialog(context);
  if (!confirmed || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.brandPrimary),
              SizedBox(height: 16),
              Text('A analisar a lista…'),
            ],
          ),
        ),
      ),
    ),
  );

  ShoppingListCleanupPlan plan;
  try {
    plan = await buildPlan();
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TagAssignmentLlmService.friendlyErrorMessage(e)),
        ),
      );
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.pop(context);

  final save = await showShoppingListCleanupReviewSheet(
    context: context,
    plan: plan,
    tags: tags,
  );
  if (save != true || !context.mounted) return;

  try {
    await applyPlan(plan);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plan.changes.isEmpty
                ? 'Nada foi alterado.'
                : 'Limpeza aplicada (${plan.changes.length} alteração(ões)).',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar: $e')),
      );
    }
  }
}
