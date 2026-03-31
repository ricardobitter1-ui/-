import 'package:flutter/material.dart';

/// Opção do seletor de ícone de grupo (chave persistida em [GroupModel.icon]).
class GroupIconChoice {
  const GroupIconChoice({
    required this.key,
    required this.labelPt,
    required this.icon,
  });

  final String key;
  final String labelPt;
  final IconData icon;
}

/// Ordem do picker (criar / editar grupo).
const List<GroupIconChoice> kGroupIconChoices = <GroupIconChoice>[
  GroupIconChoice(key: 'group', labelPt: 'Grupo', icon: Icons.group_rounded),
  GroupIconChoice(key: 'work', labelPt: 'Trabalho', icon: Icons.work_rounded),
  GroupIconChoice(key: 'home', labelPt: 'Lar', icon: Icons.home_rounded),
  GroupIconChoice(
    key: 'cottage',
    labelPt: 'Casa',
    icon: Icons.cottage_rounded,
  ),
  GroupIconChoice(
    key: 'grocery',
    labelPt: 'Mercado',
    icon: Icons.local_grocery_store_rounded,
  ),
  GroupIconChoice(
    key: 'fitness_center',
    labelPt: 'Fitness',
    icon: Icons.fitness_center_rounded,
  ),
  GroupIconChoice(key: 'school', labelPt: 'Estudos', icon: Icons.school_rounded),
  GroupIconChoice(
    key: 'flight_takeoff',
    labelPt: 'Viagem',
    icon: Icons.flight_takeoff_rounded,
  ),
  GroupIconChoice(key: 'pets', labelPt: 'Pets', icon: Icons.pets_rounded),
  GroupIconChoice(
    key: 'restaurant',
    labelPt: 'Refeições',
    icon: Icons.restaurant_rounded,
  ),
  GroupIconChoice(
    key: 'music_note',
    labelPt: 'Lazer',
    icon: Icons.music_note_rounded,
  ),
  GroupIconChoice(
    key: 'attach_money',
    labelPt: 'Finanças',
    icon: Icons.attach_money_rounded,
  ),
];

/// Mapeia `GroupModel.icon` (Firestore / modal de criação) para ícone Material.
IconData groupIconFromKey(String key) {
  final k = key.trim();
  for (final c in kGroupIconChoices) {
    if (c.key == k) return c.icon;
  }
  return Icons.groups_rounded;
}

/// Chave persistida válida para o picker, ou `group` se for legado/desconhecido.
String coerceGroupIconPickerKey(String raw) {
  final t = raw.trim();
  if (kGroupIconChoices.any((c) => c.key == t)) return t;
  return 'group';
}

/// Barra horizontal de ícones para criar/editar grupo.
class GroupIconPickerBar extends StatelessWidget {
  const GroupIconPickerBar({
    super.key,
    required this.selectedKey,
    required this.onSelect,
    required this.selectionBorderColor,
  });

  final String selectedKey;
  final ValueChanged<String> onSelect;
  final Color selectionBorderColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in kGroupIconChoices) ...[
            Tooltip(
              message: c.labelPt,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(c.key),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.key == selectedKey
                            ? selectionBorderColor
                            : Colors.grey.shade300,
                        width: c.key == selectedKey ? 2.5 : 1,
                      ),
                      color: c.key == selectedKey
                          ? selectionBorderColor.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                    ),
                    child: Icon(
                      c.icon,
                      size: 22,
                      color: c.key == selectedKey
                          ? selectionBorderColor
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
