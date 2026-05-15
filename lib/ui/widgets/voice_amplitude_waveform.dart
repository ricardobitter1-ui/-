import 'package:flutter/material.dart';

import '../../business_logic/voice_recording_quality.dart';
import '../theme/app_theme.dart';

/// Barras de amplitude centradas, estilo onda de voz.
class VoiceAmplitudeWaveform extends StatelessWidget {
  const VoiceAmplitudeWaveform({
    super.key,
    required this.levels,
    this.barCount = 32,
    this.height = 72,
    this.activeColor = AppTheme.brandPrimary,
    this.idleColor,
  });

  final List<double> levels;
  final int barCount;
  final double height;
  final Color activeColor;
  final Color? idleColor;

  @override
  Widget build(BuildContext context) {
    final idle = idleColor ?? activeColor.withValues(alpha: 0.22);
    final count = levels.length.clamp(1, barCount);
    final barWidth = 3.0;
    final gap = 3.0;

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(count, (i) {
          final level = levels[i].clamp(0.06, 1.0);
          final barHeight = height * level;
          final t = level;
          final color = Color.lerp(idle, activeColor, t) ?? activeColor;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: gap / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(barWidth),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Normaliza dBFS do pacote [record] para altura de barra (0–1).
double voiceAmplitudeLevel(double dbfs) =>
    VoiceRecordingQuality.amplitudeLevel(dbfs);
