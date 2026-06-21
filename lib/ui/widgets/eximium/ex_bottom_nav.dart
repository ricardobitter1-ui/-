import 'package:flutter/material.dart';

import '../../theme/eximium_colors.dart';
import '../../theme/eximium_spacing.dart';
import '../../theme/eximium_typography.dart';

/// Item da [ExBottomNav].
class ExBottomNavItem {
  const ExBottomNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barra de navegação **flutuante** do DS: margem 16, altura ~64, `surface1`,
/// borda, radius 26, `shadowFloat`.
///
/// Item ativo = pílula `rgba(green,.14)` + ícone/label verde; inativos em
/// `textMuted`.
class ExBottomNav extends StatelessWidget {
  const ExBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ExBottomNavItem> items;

  /// Padding inferior para listas/conteúdo rolável acima da barra flutuante.
  static double scrollBottomPadding(
    BuildContext context, {
    double gap = ExSpace.s4,
  }) {
    return MediaQuery.paddingOf(context).bottom +
        ExFabAboveBottomNavLocation.navOuterBottomMargin +
        ExFabAboveBottomNavLocation.navHeight +
        gap;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ExSpace.s4,
          0,
          ExSpace.s4,
          ExSpace.s4,
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: c.border),
            boxShadow: c.shadowFloat,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ExBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final Color fg = selected ? c.textAccent : c.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? ExColors.brandGreen.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(ExRadius.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 22, color: fg),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: ExText.label(fg).copyWith(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Posiciona o FAB acima da [ExBottomNav] flutuante.
///
/// O vão entre a base do FAB e o topo do menu usa o mesmo inset horizontal
/// ([fabEndInset], 22px) para manter o ritmo de espaçamento do DS.
///
/// Cálculo: SafeArea bottom + margem nav (16) + altura nav (64) + gap (22) = 102 + safe.
class ExFabAboveBottomNavLocation extends FloatingActionButtonLocation {
  const ExFabAboveBottomNavLocation();

  static const double navHeight = 64;
  static const double navOuterBottomMargin = ExSpace.s4;
  static const double fabEndInset = 22;

  /// Mesmo valor do inset lateral — espaçamento uniforme em torno do FAB.
  static const double fabGapAboveNav = fabEndInset;

  /// Distância do fundo da tela até a base do FAB (acima da barra).
  static double totalBottomInset(double safeAreaBottom) =>
      safeAreaBottom +
      navOuterBottomMargin +
      navHeight +
      fabGapAboveNav;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final scaffoldSize = scaffoldGeometry.scaffoldSize;
    final safeBottom = scaffoldGeometry.minViewPadding.bottom;
    final bottom = totalBottomInset(safeBottom);

    return Offset(
      scaffoldSize.width - fabSize.width - fabEndInset,
      scaffoldSize.height - fabSize.height - bottom,
    );
  }
}
