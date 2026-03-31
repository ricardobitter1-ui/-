import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/group_color_presets.dart';
import '../../data/models/group_model.dart';
import '../../data/services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/group_icon.dart';

/// Conteúdo do modal "Novo Grupo". O [TextEditingController] vive no [State]
/// e é descartado com o sheet — evita `'_dependents.isEmpty'` ao dar dispose
/// cedo demais fora do modal.
class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  late final TextEditingController _nameController;
  String _icon = 'group';
  String _color = kDefaultGroupColorHex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final group = GroupModel(
      id: '',
      name: name,
      icon: _icon,
      color: _color,
      ownerId: '',
      members: const [],
      admins: const [],
      isPersonal: false,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(firebaseServiceProvider).addGroup(group);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar grupo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
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
                  'Novo Grupo',
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
                hintText: 'Nome do grupo (ex: Trabalho)',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            const Text('Ícone', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            GroupIconPickerBar(
              selectedKey: _icon,
              onSelect: (k) => setState(() => _icon = k),
              selectionBorderColor: AppTheme.brandPrimary,
            ),
            const SizedBox(height: 16),
            const Text('Cor', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in kGroupColorPresets)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: parseAppHexColor(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: normalizeGroupColorHexForLookup(c) ==
                                  normalizeGroupColorHexForLookup(_color)
                              ? AppTheme.brandPrimary
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
                child: const Text('Criar Grupo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
