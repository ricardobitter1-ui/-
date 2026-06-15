import 'package:flutter/material.dart';

import '../../data/models/tag_model.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';

/// Filtro horizontal por etiqueta na seção de concluídas (vocabulário de um único grupo).
class CompletedSectionTagFilterBar extends StatelessWidget {
  const CompletedSectionTagFilterBar({
    super.key,
    required this.tags,
    required this.selectedTagId,
    required this.onSelect,
  });

  /// Etiquetas que aparecem em pelo menos uma tarefa concluída (já resolvidas).
  final List<TagModel> tags;
  final String? selectedTagId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final sorted = [...tags]..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    return Padding(
      padding: const EdgeInsets.only(bottom: ExSpace.s3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TagFilterPill(
              label: 'Todas',
              selected: selectedTagId == null,
              onTap: () => onSelect(null),
            ),
            const SizedBox(width: ExSpace.s2),
            for (final t in sorted)
              Padding(
                padding: const EdgeInsets.only(right: ExSpace.s2),
                child: _TagFilterPill(
                  label: t.name,
                  dotColor: Color(t.color),
                  selected: selectedTagId == t.id,
                  onTap: () =>
                      onSelect(selectedTagId == t.id ? null : t.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TagFilterPill extends StatelessWidget {
  const _TagFilterPill({
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
    final Color fg = selected ? c.textAccent : c.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? ExColors.brandGreen.withValues(alpha: 0.14)
                : c.surface2,
            borderRadius: BorderRadius.circular(ExRadius.pill),
            border: Border.all(
              color: selected ? c.borderAccent : c.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: ExSpace.s2 - 2),
              ],
              Text(
                label,
                style: ExText.body(fg).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
