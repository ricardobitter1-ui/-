import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
        backgroundColor: AppTheme.brandPrimary.withValues(alpha: 0.1),
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
        gradient: const LinearGradient(
          colors: [AppTheme.brandPrimary, AppTheme.brandSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
