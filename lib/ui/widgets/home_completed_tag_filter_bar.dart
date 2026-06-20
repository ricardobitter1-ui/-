import 'package:flutter/material.dart';

import '../../data/models/tag_model.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import 'eximium/eximium.dart';

/// Opção de filtro com chave estável entre grupos (`groupId::tagId`).
class HomeTagFilterOption {
  const HomeTagFilterOption({
    required this.compositeKey,
    required this.tag,
  });

  final String compositeKey;
  final TagModel tag;
}

/// Filtro por etiqueta quando as concluídas podem vir de vários grupos.
class HomeCompletedSectionTagFilterBar extends StatelessWidget {
  const HomeCompletedSectionTagFilterBar({
    super.key,
    required this.options,
    required this.selectedCompositeKey,
    required this.onSelect,
  });

  final List<HomeTagFilterOption> options;
  final String? selectedCompositeKey;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final sorted = [...options]..sort(
        (a, b) => a.tag.name
            .toLowerCase()
            .compareTo(b.tag.name.toLowerCase()),
      );

    return Padding(
      padding: const EdgeInsets.only(bottom: ExSpace.s3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterPill(
              label: 'Todas',
              selected: selectedCompositeKey == null,
              onTap: () => onSelect(null),
            ),
            const SizedBox(width: ExSpace.s2),
            for (final o in sorted)
              Padding(
                padding: const EdgeInsets.only(right: ExSpace.s2),
                child: _FilterPill(
                  label: o.tag.name,
                  dotColor: Color(o.tag.color),
                  selected: selectedCompositeKey == o.compositeKey,
                  onTap: () => onSelect(
                    selectedCompositeKey == o.compositeKey
                        ? null
                        : o.compositeKey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final Color bg = selected
        ? ExColors.brandGreen.withValues(alpha: 0.14)
        : c.surface2;
    final Color fg = selected ? c.textAccent : c.textSecondary;
    final Color borderColor =
        selected ? c.borderAccent : c.border;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExRadius.pill),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                ExDot(color: dotColor!),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: ExText.body(fg)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
