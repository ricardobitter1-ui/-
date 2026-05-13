import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// FAB estilo Google Agenda: squircle com +, abre overlay, pills e botão circular com X.
class ExpandableCreateTaskFab extends StatefulWidget {
  const ExpandableCreateTaskFab({
    super.key,
    required this.onWrite,
    required this.onDictate,
  });

  final VoidCallback onWrite;
  final VoidCallback onDictate;

  @override
  State<ExpandableCreateTaskFab> createState() =>
      _ExpandableCreateTaskFabState();
}

class _ExpandableCreateTaskFabState extends State<ExpandableCreateTaskFab> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _open = false;

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _open = false);
  }

  void _openMenu() {
    if (!mounted || _overlayEntry != null) return;
    setState(() => _open = true);
    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeMenu,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.bottomRight,
              offset: const Offset(0, -10),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _FabActionPill(
                      label: 'Ditar',
                      icon: Icons.mic_rounded,
                      onTap: () {
                        _closeMenu();
                        widget.onDictate();
                      },
                    ),
                    const SizedBox(height: 8),
                    _FabActionPill(
                      label: 'Escrever',
                      icon: Icons.edit_rounded,
                      onTap: () {
                        _closeMenu();
                        widget.onWrite();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _onMainFabTap() {
    if (_open) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.brandPrimary,
          borderRadius: BorderRadius.circular(_open ? 28 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onMainFabTap,
            customBorder: _open
                ? const CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _open ? Icons.close_rounded : Icons.add_rounded,
                  key: ValueKey(_open),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FabActionPill extends StatelessWidget {
  const _FabActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2B3A5A),
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppTheme.brandPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
