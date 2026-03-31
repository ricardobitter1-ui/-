import 'package:flutter/material.dart';

import '../../data/models/tag_model.dart';

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
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Todas'),
              selected: selectedTagId == null,
              onSelected: (_) => onSelect(null),
            ),
            const SizedBox(width: 8),
            for (final t in sorted)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: CircleAvatar(
                    radius: 8,
                    backgroundColor: Color(t.color),
                  ),
                  label: Text(t.name),
                  selected: selectedTagId == t.id,
                  onSelected: (sel) => onSelect(sel ? t.id : null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
