// Wspólna logika importu z OpenStreetMap — używana przez:
//   tool/import_osm.dart      (Overpass API, jedno miasto)
//   tool/import_osm_pbf.dart  (plik .osm.pbf z Geofabrik, całe województwo)
//
// Dane © OpenStreetMap contributors, licencja ODbL.

import 'dart:io';

const _leisure = {
  'fitness_centre', 'sports_centre', 'sports_hall',
  'dance', 'swimming_pool', 'ice_rink',
};
const _amenity = {'dojo', 'dancing_school'};
final _sport = RegExp(
    r'climbing|yoga|pilates|martial_arts|boxing|karate|judo|taekwondo|crossfit');

/// Siłownie plenerowe i osiedlowe place — nie prowadzą zajęć.
final _junkName = RegExp(
  r'plenerow|pod chmurk|street ?workout|calisthenics park|^oś\.|^osiedle\b',
  caseSensitive: false,
);

/// Czy obiekt o tych tagach to miejsce, w którym mogą odbywać się zajęcia.
/// Ten sam zestaw reguł co zapytanie Overpass w import_osm.dart.
bool isClassPlace(Map<String, String> t) {
  final name = t['name']?.trim();
  if (name == null || name.isEmpty) return false;
  if (_junkName.hasMatch(name) || t['outdoor'] == 'yes') return false;
  // Skały i ściany wspinaczkowe (np. Jura: natural=bare_rock/cliff + sport=climbing),
  // place zabaw i parki linowe — to nie są miejsca z zajęciami.
  if (t['natural'] != null) return false;
  if (const {'playground', 'high_ropes_course', 'climbing'}.contains(t['leisure']) &&
      !_leisure.contains(t['leisure'])) {
    return false;
  }
  if (t['leisure'] == 'swimming_pool' &&
      (t['access'] == 'private' || t['access'] == 'no')) {
    return false;
  }
  return _leisure.contains(t['leisure']) ||
      _amenity.contains(t['amenity']) ||
      (t['sport'] != null && _sport.hasMatch(t['sport']!));
}

/// Wiersz do tabeli places. [city] — gdy obiekt nie ma tagu addr:city.
Map<String, Object?> toPlace({
  required String osmId,
  required Map<String, String> tags,
  required double lat,
  required double lng,
  required String? city,
}) {
  final street = tags['addr:street'] ?? tags['addr:place'];
  final number = tags['addr:housenumber'];
  return {
    'osm_id': osmId,
    'name': tags['name']!.trim(),
    'address':
        street == null ? null : (number != null ? '$street $number' : street),
    'city': tags['addr:city'] ?? city,
    'lat': lat,
    'lng': lng,
    'phone': tags['phone'] ?? tags['contact:phone'],
    'website': tags['website'] ?? tags['contact:website'],
    'kind': kindOf(tags), // tylko do statystyk w konsoli
  };
}

String kindOf(Map<String, String> t) {
  if (_leisure.contains(t['leisure'])) return 'leisure=${t['leisure']}';
  if (_amenity.contains(t['amenity'])) return 'amenity=${t['amenity']}';
  return 'sport=${t['sport']}';
}

String _sql(Object? v) {
  if (v == null) return 'null';
  if (v is num) return v.toString();
  return "'${v.toString().replaceAll("'", "''")}'";
}

/// Upsert do public.places po osm_id. Nie nadpisuje miejsc przejętych
/// przez właścicieli (status <> 'unclaimed').
String placesToSql(Iterable<Map<String, Object?>> places, String label) {
  final rows = places.map((p) => '  (${_sql(p['osm_id'])}, ${_sql(p['name'])}, '
      '${_sql(p['address'])}, ${_sql(p['city'])}, '
      "st_setsrid(st_makepoint(${p['lng']}, ${p['lat']}), 4326), "
      '${_sql(p['phone'])}, ${_sql(p['website'])}, \'osm\')');

  return '''
-- Obiekty sportowe z OpenStreetMap: $label (${places.length} miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: ${DateTime.now().toIso8601String()}
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website, source)
values
${rows.join(',\n')}
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website,
  source   = 'osm'
where places.status = 'unclaimed';
''';
}

void printStats(Iterable<Map<String, Object?>> places,
    {String key = 'kind', int limit = 1000}) {
  final counts = <String, int>{};
  for (final p in places) {
    counts.update('${p[key]}', (v) => v + 1, ifAbsent: () => 1);
  }
  for (final e in (counts.entries.toList()..sort((a, b) => b.value - a.value))
      .take(limit)) {
    stdout.writeln('  ${e.key.padRight(28)} ${e.value}');
  }
}

String slug(String s) {
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
