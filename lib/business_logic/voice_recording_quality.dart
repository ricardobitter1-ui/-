/// Validação local da gravação de voz antes de enviar à API.
class VoiceRecordingQuality {
  VoiceRecordingQuality._();

  /// Duração mínima para o utilizador conseguir dizer algo útil.
  static const Duration minDuration = Duration(seconds: 2);

  /// Pico de amplitude (dBFS) abaixo disto considera-se silêncio.
  static const double minPeakDbfsForSpeech = -42.0;

  /// Valor inicial típico de silêncio no pacote [record].
  static const double silenceDbfs = -160.0;

  /// Normaliza dBFS para altura de barra (0–1) no visualizador.
  static double amplitudeLevel(double dbfs) {
    const minDb = -52.0;
    const maxDb = -6.0;
    if (dbfs <= minDb) return 0.08;
    return ((dbfs - minDb) / (maxDb - minDb)).clamp(0.08, 1.0);
  }

  /// Atualiza o pico observado durante a gravação.
  static double trackPeakDbfs(double currentPeak, double sampleDbfs) {
    if (sampleDbfs > currentPeak) return sampleDbfs;
    return currentPeak;
  }

  /// Retorna o primeiro problema encontrado, ou `null` se a gravação for aceitável.
  static VoiceRecordingQualityIssue? validate({
    required Duration duration,
    required double peakDbfs,
  }) {
    if (duration < minDuration) {
      return VoiceRecordingQualityIssue.tooShort;
    }
    if (peakDbfs < minPeakDbfsForSpeech) {
      return VoiceRecordingQualityIssue.noVoiceDetected;
    }
    return null;
  }
}

enum VoiceRecordingQualityIssue {
  tooShort,
  noVoiceDetected,
}

extension VoiceRecordingQualityIssueX on VoiceRecordingQualityIssue {
  String get userMessage => switch (this) {
        VoiceRecordingQualityIssue.tooShort =>
          'A gravação ficou muito curta. Fale por pelo menos 2 segundos e tente novamente.',
        VoiceRecordingQualityIssue.noVoiceDetected =>
          'Não detectamos voz na gravação. Verifique o microfone e fale mais perto do aparelho.',
      };
}
