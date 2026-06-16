import 'package:flutter/material.dart';

import '../../theme/eximium_colors.dart';
import '../../theme/eximium_spacing.dart';
import 'ex_brand.dart';

/// Barra superior fixa com a marca Eximium To Do.
///
/// Usada no shell principal e em telas empilhadas para dar respiro no topo
/// e identidade visual consistente.
class ExAppBar extends StatelessWidget {
  const ExAppBar({
    super.key,
    this.leading,
    this.title,
    this.trailing,
    this.showBackWhenCanPop = false,
    this.includeSafeArea = true,
    this.showBottomBorder = true,
  });

  final Widget? leading;
  /// Conteúdo central; omita para exibir a marca Eximium To Do.
  final Widget? title;
  final Widget? trailing;
  final bool showBackWhenCanPop;
  final bool includeSafeArea;
  final bool showBottomBorder;

  static const double _horizontalPadding = 22;
  static const double _verticalPadding = 16;

  /// Espaço entre a borda inferior da barra e o conteúdo da tela.
  static const double contentGap = 12;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final topInset =
        includeSafeArea ? MediaQuery.paddingOf(context).top : 0.0;
    final canPop = Navigator.of(context).canPop();

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null && showBackWhenCanPop && canPop) {
      resolvedLeading = IconButton(
        tooltip: 'Voltar',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      );
    }

    final barColor = c.surface0.withValues(alpha: 0.92);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: barColor,
            border: showBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: c.border.withValues(alpha: 0.55),
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding,
              topInset + _verticalPadding,
              _horizontalPadding,
              _verticalPadding,
            ),
            child: Row(
              children: [
                if (resolvedLeading != null) ...[
                  resolvedLeading,
                  const SizedBox(width: ExSpace.s1),
                ],
                Expanded(
                  child: title ?? const ExBrand(),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
        ColoredBox(color: barColor, child: const SizedBox(height: contentGap)),
      ],
    );
  }
}
