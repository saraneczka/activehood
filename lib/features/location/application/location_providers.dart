import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cities_repository.dart';
import '../data/location_prefs.dart';
import '../data/location_service.dart';
import '../domain/user_location.dart';

/// Wybrana lokalizacja; `null` = użytkownik jeszcze nie wybrał.
///
/// Na starcie: zapamiętana miejscowość, albo GPS — ale tylko jeśli zgoda
/// była już udzielona. Systemowe pytanie o zgodę pojawia się wyłącznie
/// po kliknięciu „Użyj mojej lokalizacji”.
class LocationController extends AsyncNotifier<UserLocation?> {
  LocationService get _gps => ref.read(locationServiceProvider);
  LocationPrefs get _prefs => ref.read(locationPrefsProvider);

  @override
  Future<UserLocation?> build() async {
    final saved = await _prefs.load();
    if (saved != null && saved.source == LocationSource.city) return saved;
    if (await _gps.hasPermission()) {
      try {
        return await _gps.current(request: false);
      } on GpsException {
        return null;
      }
    }
    return null;
  }

  /// Zwraca powód niepowodzenia albo `null`, gdy się udało.
  /// Przy błędzie poprzednia lokalizacja zostaje bez zmian.
  Future<GpsFailure?> useGps() async {
    try {
      final loc = await _gps.current(request: true);
      state = AsyncData(loc);
      await _prefs.save(loc);
      return null;
    } on GpsException catch (e) {
      return e.reason;
    }
  }

  Future<void> selectCity(CityOption city) async {
    final loc = city.toLocation();
    state = AsyncData(loc);
    await _prefs.save(loc);
  }
}

final locationControllerProvider =
    AsyncNotifierProvider<LocationController, UserLocation?>(
      LocationController.new,
    );

final citiesProvider = FutureProvider<List<CityOption>>(
  (ref) => ref.watch(citiesRepositoryProvider).listCities(),
);
