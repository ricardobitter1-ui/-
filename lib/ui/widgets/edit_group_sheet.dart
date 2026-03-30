import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/group_model.dart';
import '../../data/services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';

/// Sheet para editar nome, ícone e cor de um grupo existente (apenas metadados).
class EditGroupSheet extends ConsumerStatefulWidget {
  final GroupModel group;
  const EditGroupSheet({super.key, required this.group});

  @override
  ConsumerState<EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends ConsumerState<EditGroupSheet> {
  late final TextEditingController _nameController;
  late String _icon;
  late String _color;

  static const _colorOptions = <String>[
    '#0052FF',
    '#5A189A',
    '#FF6B6B',
    '#2EC4B6',
    '#FFB703',
    '#2B2D42',
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameController = TextEditingController(text: g.name);
    _icon = g.icon.isNotEmpty ? g.icon : 'group';
    _color = g.color.isNotEmpty ? g.color : '#0052FF';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final updated = widget.group.copyWith(
      name: name,
      icon: _icon,
      color: _color,
    );

    try {
      await ref.read(firebaseServiceProvider).updateGroup(updated);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao guardar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Editar grupo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Nome do grupo',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Ícone:', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _icon,
                items: const [
                  DropdownMenuItem(value: 'group', child: Text('group')),
                  DropdownMenuItem(value: 'work', child: Text('work')),
                  DropdownMenuItem(value: 'home', child: Text('home')),
                  DropdownMenuItem(
                    value: 'fitness_center',
                    child: Text('fitness'),
                  ),
                  DropdownMenuItem(value: 'school', child: Text('school')),
                ],
                onChanged: (v) => setState(() => _icon = v ?? 'group'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Cor:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _colorOptions)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: parseAppHexColor(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c == _color
                            ? AppTheme.primaryBlue
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
