import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// Localização “enquanto usa o app” (mapa, pin atual).
  Future<bool> ensureWhenInUseLocationPermission() async {
    if (kIsWeb) return false;
    if (_isAndroid || Platform.isIOS) {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
    final p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      final r = await Geolocator.requestPermission();
      return r == LocationPermission.whileInUse ||
          r == LocationPermission.always;
    }
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Android: “o tempo todo” para geofence em segundo plano. Em outras plataformas retorna true.
  Future<bool> ensureBackgroundLocationPermission() async {
    if (kIsWeb) return false;
    if (!_isAndroid) return true;

    final whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) {
      final r = await Permission.locationWhenInUse.request();
      if (!r.isGranted) return false;
    }

    final always = await Permission.locationAlways.status;
    if (always.isGranted) return true;

    final req = await Permission.locationAlways.request();
    return req.isGranted;
  }

  Future<void> openSystemLocationSettings() async {
    await openAppSettings();
  }

  /// Solicita as permissões e pega a coordenada atual
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
