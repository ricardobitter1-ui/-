import 'package:flutter/material.dart';

import '../../data/models/tag_model.dart';

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
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Todas'),
              selected: selectedCompositeKey == null,
              onSelected: (_) => onSelect(null),
            ),
            const SizedBox(width: 8),
            for (final o in sorted)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: CircleAvatar(
                    radius: 8,
                    backgroundColor: Color(o.tag.color),
                  ),
                  label: Text(o.tag.name),
                  selected: selectedCompositeKey == o.compositeKey,
                  onSelected: (sel) => onSelect(sel ? o.compositeKey : null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
