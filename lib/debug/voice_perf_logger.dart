import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Medições de tempo do fluxo de ditado (apenas em debug).
abstract final class VoicePerfLogger {
  static const _sessionId = 'a2df98';
  static const _logFileName = 'debug-a2df98.log';
  static const _ingestUrl =
      'http://127.0.0.1:7278/ingest/2a3e2593-bf19-46a9-b152-7052cfdb15d3';

  static String? _runId;

  static void beginRun() {
    _runId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String get runId => _runId ?? 'unknown';

  /// [hypothesisId] A=Groq, B=OpenRouter extract, C=Firestore fetch, D=OpenRouter tags, E=persist
  static Future<void> phase(
    String phase, {
    required int elapsedMs,
    String hypothesisId = '',
    Map<String, Object?> data = const {},
  }) async {
    if (!kDebugMode) return;

    final payload = <String, Object?>{
      'sessionId': _sessionId,
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': 'voice_perf',
      'message': phase,
      'data': <String, Object?>{
        'elapsedMs': elapsedMs,
        ...data,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final line = jsonEncode(payload);
    debugPrint('[VoicePerf] $phase: ${elapsedMs}ms $data');

    await _appendToLogFile(line);
    unawaited(_postIngest(line)); // ignore: discarded_futures
  }

  static Future<void> summary(Map<String, int> phasesMs) async {
    if (!kDebugMode) return;
    final wallMs = phasesMs['total'] ?? phasesMs.values.fold<int>(0, (a, b) => a + b);
    await phase(
      'SUMMARY',
      elapsedMs: wallMs,
      hypothesisId: 'ALL',
      data: {
        'phasesMs': phasesMs,
        'wallMs': wallMs,
      },
    );
  }

  static Future<void> _appendToLogFile(String line) async {
    final candidates = <String>[
      if (Platform.environment['VOICE_DEBUG_LOG'] != null)
        Platform.environment['VOICE_DEBUG_LOG']!,
      _logFileName,
      '${Directory.current.path}${Platform.pathSeparator}$_logFileName',
    ];

    for (final path in candidates) {
      try {
        final file = File(path);
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        await file.writeAsString('$line\n', mode: FileMode.append);
        return;
      } catch (_) {}
    }
  }

  static Future<void> _postIngest(String line) async {
    try {
      await http
          .post(
            Uri.parse(_ingestUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': _sessionId,
            },
            body: line,
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
