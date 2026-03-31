import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Converte hex do utilizador (com ou sem `#`, 6 ou 8 dígitos) para [Color].
/// Fallback: [AppTheme.brandPrimary].
Color parseAppHexColor(String hex) {
  final raw = hex.trim();
  final sanitized = raw.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
  if (sanitized.isEmpty) return AppTheme.brandPrimary;

  final normalized = sanitized.length > 8
      ? sanitized.substring(sanitized.length - 8)
      : sanitized;

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return AppTheme.brandPrimary;

  if (normalized.length <= 6) {
    return Color(0xFF000000 | value);
  }
  return Color(value & 0xFFFFFFFF);
}

int _colorByte(double component01) =>
    (component01.clamp(0.0, 1.0) * 255.0).round();

/// Luminância relativa WCAG (sRGB), entre 0 e 1.
double colorRelativeLuminance(Color color) {
  double linearize01(double srgb) {
    final v = srgb.clamp(0.0, 1.0);
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linearize01(color.r);
  final g = linearize01(color.g);
  final b = linearize01(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

const Color _railContrastBlend = Color(0xFF2B2D42);
const double _maxRailLuminanceForWhiteText = 0.40;

/// Ajusta a cor do grupo até texto branco ser legível (cores claras → blend com navy).
Color railCardSurfaceForWhiteText(Color userColor) {
  var c = userColor.a == 0
      ? AppTheme.brandPrimary
      : Color.fromARGB(
          255,
          _colorByte(userColor.r),
          _colorByte(userColor.g),
          _colorByte(userColor.b),
        );

  for (var i = 0; i < 16; i++) {
    if (colorRelativeLuminance(c) <= _maxRailLuminanceForWhiteText) {
      return c;
    }
    c = Color.lerp(c, _railContrastBlend, 0.24) ?? c;
  }
  return _railContrastBlend;
}
