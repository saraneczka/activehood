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
    final p = _toPlace(e as Map<String, dynamic>, city);
    if (p != null) places[p['osm_id'] as String] = p;
  }

  if (places.isEmpty) {
    stderr.writeln('Brak wyników — sprawdź pisownię miasta (np. "Kraków", "Łódź").');
    exit(1);
  }

  final byKind = <String, int>{};
  for (final p in places.values) {
    byKind.update(p['kind'] as String, (v) => v + 1, ifAbsent: () => 1);
  }
  stdout.writeln('Znaleziono ${places.length} miejsc:');
  for (final e in byKind.entries.toList()..sort((a, b) => b.value - a.value)) {
    stdout.writeln('  ${e.key.padRight(28)} ${e.value}');
  }

  final out = File('supabase/seed/osm_places_${_slug(city)}.sql');
  await out.create(recursive: true);
  await out.writeAsString(_toSql(places.values, city));
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

/// Siłownie plenerowe i osiedlowe place — nie prowadzą zajęć.
final _junkName = RegExp(
  r'plenerow|pod chmurk|street ?workout|calisthenics park|^oś\.|^osiedle\b',
  caseSensitive: false,
);

Map<String, Object?>? _toPlace(Map<String, dynamic> e, String city) {
  final tags = (e['tags'] as Map?)?.cast<String, String>() ?? {};
  final name = tags['name']?.trim();
  if (name == null || name.isEmpty) return null;
  if (_junkName.hasMatch(name) || tags['outdoor'] == 'yes') return null;

  final lat = (e['lat'] ?? e['center']?['lat']) as num?;
  final lng = (e['lon'] ?? e['center']?['lon']) as num?;
  if (lat == null || lng == null) return null;

  final street = tags['addr:street'] ?? tags['addr:place'];
  final number = tags['addr:housenumber'];

  return {
    'osm_id': '${e['type']}/${e['id']}',
    'name': name,
    'address': street == null ? null : (number != null ? '$street $number' : street),
    'city': tags['addr:city'] ?? city,
    'lat': lat.toDouble(),
    'lng': lng.toDouble(),
    'phone': tags['phone'] ?? tags['contact:phone'],
    'website': tags['website'] ?? tags['contact:website'],
    'kind': _kind(tags), // tylko do statystyk w konsoli
  };
}

String _kind(Map<String, String> t) {
  const leisure = {
    'fitness_centre', 'sports_centre', 'sports_hall',
    'dance', 'swimming_pool', 'ice_rink',
  };
  if (leisure.contains(t['leisure'])) return 'leisure=${t['leisure']}';
  if (t['amenity'] != null) return 'amenity=${t['amenity']}';
  return 'sport=${t['sport']}';
}

String _sql(Object? v) {
  if (v == null) return 'null';
  if (v is num) return v.toString();
  return "'${v.toString().replaceAll("'", "''")}'";
}

String _toSql(Iterable<Map<String, Object?>> places, String city) {
  final rows = places.map((p) => '  (${_sql(p['osm_id'])}, ${_sql(p['name'])}, '
      '${_sql(p['address'])}, ${_sql(p['city'])}, '
      "st_setsrid(st_makepoint(${p['lng']}, ${p['lat']}), 4326), "
      '${_sql(p['phone'])}, ${_sql(p['website'])})');

  return '''
-- Obiekty sportowe z OpenStreetMap: $city (${places.length} miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: ${DateTime.now().toIso8601String()}
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website)
values
${rows.join(',\n')}
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website
where places.status = 'unclaimed';
''';
}

String _slug(String s) {
  const map = {
    'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n',
    'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z',
  };
  return s
      .toLowerCase()
      .split('')
      .map((c) => map[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
