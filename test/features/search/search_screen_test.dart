import 'package:activehood/features/location/data/cities_repository.dart';
import 'package:activehood/features/location/data/location_prefs.dart';
import 'package:activehood/features/location/data/location_service.dart';
import 'package:activehood/features/location/domain/user_location.dart';
import 'package:activehood/features/search/data/classes_repository.dart';
import 'package:activehood/features/search/domain/class_result.dart';
import 'package:activehood/features/search/presentation/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ClassesRepository {
  _FakeRepo(this.results);

  final List<ClassResult> results;
  final calls = <Map<String, Object?>>[];

  @override
  Future<List<ClassResult>> searchNearby({
    required double lat,
    required double lng,
    required int radiusM,
    int? activityTypeId,
    String? level,
    String? format,
  }) async {
    calls.add({'lat': lat, 'lng': lng, 'radiusM': radiusM, 'format': format});
    return results;
  }

  @override
  Future<List<ActivityType>> activityTypes() async => const [
    ActivityType(1, 'Joga'),
  ];
}

class _FakeGps implements LocationService {
  _FakeGps({this.permitted = false, this.failure});

  final bool permitted;
  final GpsFailure? failure;
  int requests = 0;

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<UserLocation> current({bool request = true}) async {
    if (request) requests++;
    if (failure != null) throw GpsException(failure!);
    return const UserLocation(
      lat: 52.23,
      lng: 21.01,
      label: UserLocation.gpsLabel,
      source: LocationSource.gps,
    );
  }

  @override
  Future<void> openSettings() async {}
}

class _FakePrefs implements LocationPrefs {
  _FakePrefs([this.stored]);
  UserLocation? stored;

  @override
  Future<UserLocation?> load() async => stored;

  @override
  Future<void> save(UserLocation loc) async => stored = loc;
}

class _FakeCities implements CitiesRepository {
  @override
  Future<List<CityOption>> listCities() async => const [
    CityOption(name: 'Bytom', lat: 50.35, lng: 18.91, placesCount: 24),
    CityOption(name: 'Czeladź', lat: 50.32, lng: 19.08, placesCount: 9),
    CityOption(
      name: 'Tarnowskie Góry',
      lat: 50.44,
      lng: 18.85,
      placesCount: 15,
    ),
  ];
}

final _yoga = ClassResult.fromMap({
  'class_id': 'c1',
  'title': 'Joga poranna',
  'activity': 'Joga',
  'level': 'beginner',
  'format': 'group',
  'price_pln': 40,
  'schedule_note': 'pon/śr 8:00',
  'place_id': 'p1',
  'place_name': 'Studio Om',
  'address': 'ul. Prosta 1',
  'place_lat': 50.34,
  'place_lng': 18.91,
  'distance_m': 820,
});

const _bytom = UserLocation(
  lat: 50.35,
  lng: 18.91,
  label: 'Bytom',
  source: LocationSource.city,
);

class _Deps {
  _Deps(this.repo, this.gps, this.prefs);
  final _FakeRepo repo;
  final _FakeGps gps;
  final _FakePrefs prefs;
}

Future<_Deps> _pump(
  WidgetTester tester, {
  List<ClassResult> results = const [],
  _FakeGps? gps,
  UserLocation? saved,
}) async {
  final deps = _Deps(_FakeRepo(results), gps ?? _FakeGps(), _FakePrefs(saved));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        classesRepositoryProvider.overrideWithValue(deps.repo),
        locationServiceProvider.overrideWithValue(deps.gps),
        locationPrefsProvider.overrideWithValue(deps.prefs),
        citiesRepositoryProvider.overrideWithValue(_FakeCities()),
      ],
      child: const MaterialApp(home: SearchScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return deps;
}

void main() {
  testWidgets('bez zgody i bez zapisu: nie pyta o GPS, prosi o wybór', (
    tester,
  ) async {
    final d = await _pump(tester);
    expect(find.text('Gdzie szukać zajęć?'), findsOneWidget);
    expect(find.text('Wybierz lokalizację'), findsOneWidget);
    expect(d.gps.requests, 0);
    expect(d.repo.calls, isEmpty);
  });

  testWidgets('zapamiętana miejscowość: szuka wokół niej', (tester) async {
    final d = await _pump(tester, results: [_yoga], saved: _bytom);
    expect(find.text('Bytom'), findsOneWidget);
    expect(find.text('Joga poranna'), findsOneWidget);
    expect(find.text('820 m'), findsOneWidget);
    expect(d.repo.calls.single['lat'], 50.35);
  });

  testWidgets('zgoda udzielona wcześniej: używa GPS bez pytania', (
    tester,
  ) async {
    final d = await _pump(
      tester,
      results: [_yoga],
      gps: _FakeGps(permitted: true),
    );
    expect(find.text(UserLocation.gpsLabel), findsOneWidget);
    expect(d.gps.requests, 0);
    expect(d.repo.calls.single['lat'], 52.23);
  });

  testWidgets('ręczne wpisanie miejscowości (bez polskich znaków)', (
    tester,
  ) async {
    final d = await _pump(tester, results: [_yoga]);
    await tester.tap(find.text('Wybierz miejscowość'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'czel');
    await tester.pumpAndSettle();
    expect(find.text('Bytom'), findsNothing);
    await tester.tap(find.text('Czeladź'));
    await tester.pumpAndSettle();

    expect(find.text('Czeladź'), findsOneWidget); // w pasku lokalizacji
    expect(find.text('Joga poranna'), findsOneWidget);
    expect(d.prefs.stored?.label, 'Czeladź');
    expect(d.repo.calls.single['lat'], 50.32);
  });

  testWidgets('odmowa GPS w panelu: komunikat, panel zostaje otwarty', (
    tester,
  ) async {
    final d = await _pump(
      tester,
      gps: _FakeGps(failure: GpsFailure.deniedForever),
    );
    await tester.tap(find.text('Wybierz miejscowość'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Użyj mojej lokalizacji'));
    await tester.pumpAndSettle();

    expect(d.gps.requests, 1);
    expect(find.textContaining('włączyć w Ustawieniach'), findsOneWidget);
    expect(find.text('Ustawienia'), findsOneWidget);
    expect(
      find.text('Tarnowskie Góry'),
      findsOneWidget,
    ); // lista nadal dostępna
  });

  testWidgets('zmiana filtra ponawia wyszukiwanie', (tester) async {
    final d = await _pump(tester, results: [_yoga], saved: _bytom);
    expect(d.repo.calls, hasLength(1));
    await tester.tap(find.widgetWithText(FilterChip, 'Indywidualne'));
    await tester.pumpAndSettle();
    expect(d.repo.calls.last['format'], 'individual');
  });
}
