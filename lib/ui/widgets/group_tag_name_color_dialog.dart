import 'package:flutter/material.dart';

import '../../data/models/tag_model.dart';

/// Cores sugeridas para etiquetas de grupo (nome + cor no Firestore).
const List<int> kGroupTagPresetColors = <int>[
  0xFFE53935,
  0xFFD81B60,
  0xFF8E24AA,
  0xFF5E35B1,
  0xFF3949AB,
  0xFF1E88E5,
  0xFF00897B,
  0xFF43A047,
  0xFFFDD835,
  0xFFF4511E,
  0xFF6D4C41,
  0xFF546E7A,
];

/// Diálogo para criar ou editar etiqueta (`TagModel?` null = criar).
class GroupTagNameColorDialog extends StatefulWidget {
  const GroupTagNameColorDialog({super.key, this.initialTag});

  final TagModel? initialTag;

  @override
  State<GroupTagNameColorDialog> createState() =>
      _GroupTagNameColorDialogState();
}

class _GroupTagNameColorDialogState extends State<GroupTagNameColorDialog> {
  late final TextEditingController _nameCtrl;
  late int _pickedColor;

  bool get _isEdit => widget.initialTag != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTag;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _pickedColor = t != null
        ? t.color
        : kGroupTagPresetColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar etiqueta' : 'Nova etiqueta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Nome (ex.: Verduras)',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kGroupTagPresetColors.map((c) {
                final sel = _pickedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _pickedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (name: name, color: _pickedColor));
          },
          child: Text(_isEdit ? 'Guardar' : 'Criar'),
        ),
      ],
    );
  }
}
