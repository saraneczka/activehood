import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_location.dart';

/// Zapamiętuje ostatni wybór lokalizacji między uruchomieniami.
/// Dla GPS zapisujemy tylko „gps” — współrzędne pobieramy na nowo.
class LocationPrefs {
  const LocationPrefs();

  static const _key = 'location.v1';

  Future<UserLocation?> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['source'] == 'gps') {
        return const UserLocation(
          lat: 0,
          lng: 0,
          label: UserLocation.gpsLabel,
          source: LocationSource.gps,
        );
      }
      return UserLocation(
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        label: m['label'] as String,
        source: LocationSource.city,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(UserLocation loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(
          loc.source == LocationSource.gps
              ? {'source': 'gps'}
              : {
                  'source': 'city',
                  'label': loc.label,
                  'lat': loc.lat,
                  'lng': loc.lng,
                },
        ),
      );
    } catch (_) {
      // brak zapisu nie blokuje aplikacji
    }
  }
}

final locationPrefsProvider = Provider<LocationPrefs>(
  (ref) => const LocationPrefs(),
);
