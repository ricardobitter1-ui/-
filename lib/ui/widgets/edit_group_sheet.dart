import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/group_color_presets.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_type.dart';
import 'group_type_picker.dart';
import '../../data/services/firebase_service.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../theme/group_icon.dart';
import 'eximium/eximium.dart';

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
  late GroupType _type;

  List<String> _colorsForPicker() {
    final n = normalizeGroupColorHexForLookup(_color);
    if (n.isEmpty) return kGroupColorPresets;
    final has = kGroupColorPresets.any(
      (p) => normalizeGroupColorHexForLookup(p) == n,
    );
    if (has) return kGroupColorPresets;
    return [...kGroupColorPresets, n];
  }

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameController = TextEditingController(text: g.name);
    _icon = coerceGroupIconPickerKey(g.icon.isNotEmpty ? g.icon : 'group');
    _color = g.color.isNotEmpty ? g.color : kDefaultGroupColorHex;
    _type = g.type;
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
      type: _type,
    );

    try {
      final fs = ref.read(firebaseServiceProvider);
      await fs.updateGroup(updated);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ExRadius.xl),
        ),
      ),
      child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: ExSpace.s3,
          left: ExSpace.s5,
          right: ExSpace.s5,
          bottom: MediaQuery.of(context).viewInsets.bottom + ExSpace.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: ExSpace.s4),
                decoration: BoxDecoration(
                  color: c.surface3,
                  borderRadius: BorderRadius.circular(ExRadius.pill),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Editar grupo', style: ExText.h2(c.textPrimary)),
                _CircleCloseButton(
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: ExSpace.s3),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Nome do grupo',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: ExSpace.s4),
            GroupTypePicker(
              selected: _type,
              onSelected: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: ExSpace.s4),
            const ExSectionLabel(label: 'Ícone'),
            const SizedBox(height: ExSpace.s2),
            GroupIconPickerBar(
              selectedKey: _icon,
              onSelect: (k) => setState(() => _icon = k),
              selectionBorderColor: ExColors.brandGreen,
            ),
            const SizedBox(height: ExSpace.s4),
            const ExSectionLabel(label: 'Cor'),
            const SizedBox(height: ExSpace.s2),
            Wrap(
              spacing: ExSpace.s3 - 2,
              runSpacing: ExSpace.s3 - 2,
              children: [
                for (final preset in _colorsForPicker())
                  GestureDetector(
                    onTap: () => setState(() => _color = preset),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: parseAppHexColor(preset),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: normalizeGroupColorHexForLookup(preset) ==
                                  normalizeGroupColorHexForLookup(_color)
                              ? ExColors.brandGreen
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ExSpace.s5),
            ExButton(
              label: 'Salvar',
              onPressed: _submit,
              expand: true,
              size: ExButtonSize.lg,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Botão circular de fechar (surface2 + borda) usado no sheet de edição.
class _CircleCloseButton extends StatelessWidget {
  const _CircleCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return Material(
      color: c.surface2,
      shape: CircleBorder(side: BorderSide(color: c.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.close_rounded, size: 20, color: c.textSecondary),
        ),
      ),
    );
  }
}
