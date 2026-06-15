import 'package:flutter/material.dart';

import '../theme/eximium_colors.dart';
import '../theme/eximium_typography.dart';

class CustomAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final double radius;

  const CustomAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl!),
        backgroundColor: ExColors.brandGreen.withValues(alpha: 0.1),
      );
    }

    // Fallback para a primeira letra do nome
    final String initial = (displayName != null && displayName!.isNotEmpty)
        ? displayName![0].toUpperCase()
        : '?';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ExColors.gradientBrand,
        boxShadow: [
          BoxShadow(
            color: ExColors.brandGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: ExText.h2(ExColors.onBrandGreen).copyWith(
            fontSize: radius,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
