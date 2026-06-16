import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/eximium_colors.dart';

/// Marca Eximium (quatro cápsulas empilhadas) do design system.
class ExBrandMark extends StatelessWidget {
  const ExBrandMark({
    super.key,
    this.size = 22,
    this.color,
  });

  /// Largura do ícone; altura segue proporção do SVG original (369×422).
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? ExColors.brandGreen;
    final scale = size / 369;
    final height = 422 * scale;

    RRect pill(double x, double y, double w, double h, double rx) {
      return RRect.fromRectAndRadius(
        Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale),
        Radius.circular(rx * scale),
      );
    }

    return SizedBox(
      width: size,
      height: height,
      child: CustomPaint(
        painter: _ExBrandMarkPainter(
          fill: fill,
          pills: [
            pill(0, 0, 368.99, 119.63, 59.19),
            pill(0, 151.11, 238.54, 119.63, 59.82),
            pill(143.92, 302.23, 225.07, 119.63, 59.82),
            pill(0, 302.23, 120.73, 119.63, 59.82),
          ],
        ),
      ),
    );
  }
}

class _ExBrandMarkPainter extends CustomPainter {
  _ExBrandMarkPainter({required this.fill, required this.pills});

  final Color fill;
  final List<RRect> pills;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = fill;
    for (final pill in pills) {
      canvas.drawRRect(pill, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExBrandMarkPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.pills != pills;
  }
}

/// Wordmark "Eximium To Do" conforme o redesign.
class ExBrand extends StatelessWidget {
  const ExBrand({
    super.key,
    this.markSize = 22,
    this.fontSize = 17,
    this.markOnly = false,
  });

  final double markSize;
  final double fontSize;
  final bool markOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;

    final mark = ExBrandMark(size: markSize);
    if (markOnly) return mark;

    final wordmarkStyle = GoogleFonts.redHatDisplay(
      fontSize: fontSize,
      letterSpacing: -0.01 * fontSize,
      height: 1.1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        const SizedBox(width: 9),
        Text.rich(
          TextSpan(
            style: wordmarkStyle,
            children: [
              TextSpan(
                text: 'Eximium',
                style: wordmarkStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              TextSpan(
                text: ' To Do',
                style: wordmarkStyle.copyWith(
                  fontWeight: FontWeight.w300,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
