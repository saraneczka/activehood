import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/user_location.dart';

enum GpsFailure { serviceDisabled, denied, deniedForever, unavailable }

class GpsException implements Exception {
  const GpsException(this.reason);
  final GpsFailure reason;
}

class LocationService {
  const LocationService();

  /// Czy aplikacja ma już zgodę (bez pokazywania systemowego pytania).
  Future<bool> hasPermission() async {
    try {
      final perm = await Geolocator.checkPermission();
      return perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Bieżąca pozycja. Przy [request] = true może pokazać pytanie o zgodę.
  /// Rzuca [GpsException], gdy się nie da.
  Future<UserLocation> current({bool request = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const GpsException(GpsFailure.serviceDisabled);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && request) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        throw const GpsException(GpsFailure.deniedForever);
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.unableToDetermine) {
        throw const GpsException(GpsFailure.denied);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return UserLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        label: UserLocation.gpsLabel,
        source: LocationSource.gps,
      );
    } on GpsException {
      rethrow;
    } catch (_) {
      throw const GpsException(GpsFailure.unavailable);
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);
