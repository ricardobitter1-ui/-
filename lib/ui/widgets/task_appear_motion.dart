import 'package:flutter/material.dart';

bool _reduceMotion(BuildContext context) {
  return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// Entrada suave (fade + leve deslize) ao montar o cartão — útil ao mudar de bloco ativo/concluídas.
class TaskAppearMotion extends StatefulWidget {
  const TaskAppearMotion({super.key, required this.child});

  final Widget child;

  @override
  State<TaskAppearMotion> createState() => _TaskAppearMotionState();
}

class _TaskAppearMotionState extends State<TaskAppearMotion> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    final duration =
        reduce ? Duration.zero : const Duration(milliseconds: 260);
    return AnimatedOpacity(
      duration: duration,
      curve: Curves.easeOut,
      opacity: _shown ? 1 : 0,
      child: AnimatedSlide(
        duration: duration,
        curve: Curves.easeOutCubic,
        offset: _shown ? Offset.zero : const Offset(0, 0.05),
        child: widget.child,
      ),
    );
  }
}
