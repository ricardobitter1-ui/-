import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CompletedTasksSectionHeader extends StatelessWidget {
  const CompletedTasksSectionHeader({
    super.key,
    required this.expanded,
    required this.count,
    required this.onToggle,
  });

  final bool expanded;
  final int count;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final label = 'Concluídas ($count)';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          expanded: expanded,
          label:
              '$label. Toque para ${expanded ? 'recolher' : 'expandir'} a lista de tarefas concluídas.',
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
