import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});

/// Regista o token FCM em `users/{uid}/fcmTokens/{tokenId}` (alinhado com [firestore.rules]).
class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  final _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSub;

  User? _currentUser() {
    final a = _ref.read(authStateProvider);
    return switch (a) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  Future<void> syncTokenForCurrentUser() async {
    final user = _currentUser();
    if (user == null) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _persistToken(user.uid, token);

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) {
          final u = _currentUser();
          if (u != null) {
            _persistToken(u.uid, newToken);
          }
        },
      );
    } catch (e, st) {
      debugPrint('FCM sync failed: $e\n$st');
    }
  }

  static String _tokenDocId(String token) {
    var h = 0;
    for (final u in token.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return 't_${h.toRadixString(16)}';
  }

  Future<void> _persistToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(_tokenDocId(token))
        .set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
