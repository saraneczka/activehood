// Pobiera obiekty sportowe z OpenStreetMap (Overpass API) dla wybranego miasta
// i generuje plik SQL, który wstawia je do tabeli public.places.
//
// Użycie:
//   dart run tool/import_osm.dart                 # Warszawa
//   dart run tool/import_osm.dart "Kraków"
//
// Wynik: supabase/seed/osm_places_<miasto>.sql — wklej w Supabase SQL Editor.
// Wymaga migracji supabase/migrations/20261122_places_osm_id.sql.
// Dane © OpenStreetMap contributors, licencja ODbL.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'osm_common.dart';

const _overpassUrls = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];
const _userAgent = 'Activehood-importer/1.0 (+https://activehood.pl)';

/// Tagi OSM oznaczające miejsca, w których mogą odbywać się zajęcia.
/// Wymagamy nazwy, żeby pominąć np. prywatne baseny i anonimowe boiska.
String _query(String city) => '''
[out:json][timeout:180];
area["name"="$city"]["boundary"="administrative"]["admin_level"~"^(6|7|8)\$"]->.a;
(
  nwr["leisure"="fitness_centre"]["name"](area.a);
  nwr["leisure"="sports_centre"]["name"](area.a);
  nwr["leisure"="sports_hall"]["name"](area.a);
  nwr["leisure"="dance"]["name"](area.a);
  nwr["amenity"="dojo"]["name"](area.a);
  nwr["amenity"="dancing_school"]["name"](area.a);
  nwr["leisure"="swimming_pool"]["access"!~"private|no"]["name"](area.a);
  nwr["leisure"="ice_rink"]["name"](area.a);
  nwr["sport"~"climbing|yoga|pilates|martial_arts|boxing|karate|judo|taekwondo|crossfit"]["name"](area.a);
);
out center tags;
''';

Future<void> main(List<String> args) async {
  final city = args.isNotEmpty ? args.first : 'Warszawa';
  stdout.writeln('Pobieram obiekty z OSM dla: $city ...');

  final elements = await _fetch(_query(city));
  final places = <String, Map<String, Object?>>{};
  for (final e in elements) {
    final m = e as Map<String, dynamic>;
    final tags = (m['tags'] as Map?)?.cast<String, String>() ?? {};
    final lat = (m['lat'] ?? m['center']?['lat']) as num?;
    final lng = (m['lon'] ?? m['center']?['lon']) as num?;
    if (lat == null || lng == null || !isClassPlace(tags)) continue;
    final p = toPlace(
      osmId: '${m['type']}/${m['id']}',
      tags: tags,
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      city: city,
    );
    places[p['osm_id'] as String] = p;
  }

  if (places.isEmpty) {
    stderr.writeln('Brak wyników — sprawdź pisownię miasta (np. "Kraków", "Łódź").');
    exit(1);
  }

  stdout.writeln('Znaleziono ${places.length} miejsc:');
  printStats(places.values);

  final out = File('supabase/seed/osm_places_${slug(city)}.sql');
  await out.create(recursive: true);
  await out.writeAsString(placesToSql(places.values, city));
  stdout.writeln('Zapisano: ${out.path}');
}

/// Ponawia zapytanie z rosnącym odstępem, na zmianę na kilku serwerach
/// (publiczne serwery Overpass bywają przeciążone).
Future<List<dynamic>> _fetch(String query) async {
  var delay = const Duration(seconds: 5);
  for (var attempt = 1;; attempt++) {
    final url = _overpassUrls[(attempt - 1) % _overpassUrls.length];
    try {
      return await _fetchOnce(url, query).timeout(const Duration(minutes: 4));
    } on Exception catch (e) {
      // TimeoutException też jest Exception — wtedy próbujemy kolejny serwer.
      if (attempt >= 8) rethrow;
      stderr.writeln('Próba $attempt nieudana ($url): ${e.toString().split('\n').first}');
      stderr.writeln('Ponawiam za ${delay.inSeconds} s ...');
      await Future<void>.delayed(delay);
      delay *= 2;
    }
  }
}

Future<List<dynamic>> _fetchOnce(String url, String query) async {
  final client = HttpClient()..userAgent = _userAgent;
  try {
    final req = await client.postUrl(Uri.parse(url));
    req.headers.contentType =
        ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
    req.write('data=${Uri.encodeQueryComponent(query)}');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw HttpException('Overpass HTTP ${res.statusCode}');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    // Przeciążony serwer potrafi zwrócić HTTP 200 z pustą listą i komunikatem
    // w polu "remark" (np. "runtime error: Query timed out") — traktujemy to jak błąd.
    final remark = json['remark'] as String?;
    if (remark != null && remark.contains('error')) {
      throw HttpException('Overpass remark: $remark');
    }
    return json['elements'] as List;
  } finally {
    client.close();
  }
}
