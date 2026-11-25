// Import obiektów sportowych z całego województwa — z pliku Geofabrik,
// bez odpytywania (często przeciążonego) Overpass API.
//
// Wymaga: brew install osmium-tool
//
// Użycie:
//   dart run tool/import_osm_pbf.dart slaskie
//   dart run tool/import_osm_pbf.dart pomorskie
//
// Nazwa województwa jak na https://download.geofabrik.de/europe/poland.html
// (bez polskich znaków: slaskie, pomorskie, malopolskie, lodzkie, ...).
//
// Kroki:
//   1. pobiera <woj>-latest.osm.pbf do .osm_cache/ (pomija, jeśli plik ma < 7 dni),
//   2. osmium: wycina obiekty sportowe i granice administracyjne do GeoJSON,
//   3. przypisuje miasto: tag addr:city, a gdy go brak — miejscowość/gmina,
//      w której granicach leży punkt,
//   4. zapisuje supabase/seed/osm_places_woj_<woj>.sql (upsert po osm_id).
//
// Dane © OpenStreetMap contributors, licencja ODbL.

import 'dart:convert';
import 'dart:io';

import 'osm_common.dart';

const _userAgent = 'Activehood-importer/1.0 (+https://activehood.pl)';
const _cacheDir = '.osm_cache';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Podaj województwo, np.: dart run tool/import_osm_pbf.dart slaskie');
    exit(64);
  }
  final region = args.first.toLowerCase();
  await Directory(_cacheDir).create(recursive: true);

  final pbf = await _download(region);

  stdout.writeln('Filtruję dane (osmium) ...');
  final sportFile = await _extract(pbf, '${region}_sport', [
    'nwr/leisure=fitness_centre,sports_centre,sports_hall,dance,swimming_pool,ice_rink',
    'nwr/amenity=dojo,dancing_school',
    'nwr/sport',
  ]);
  final adminFile =
      await _extract(pbf, '${region}_admin', ['r/boundary=administrative']);

  final boundaries = await _loadBoundaries(adminFile);
  stdout.writeln('Granice administracyjne: ${boundaries.length}');

  final places = <String, Map<String, Object?>>{};
  await for (final f in _features(sportFile)) {
    final tags = _tags(f);
    if (!isClassPlace(tags)) continue;
    final osmId = _osmId(f['id'] as String);
    final center = _center(f['geometry'] as Map<String, dynamic>);
    if (osmId == null || center == null) continue;
    final (lng, lat) = center;
    places[osmId] = toPlace(
      osmId: osmId,
      tags: tags,
      lat: lat,
      lng: lng,
      city: tags['addr:city'] == null ? _cityAt(boundaries, lng, lat) : null,
    );
  }

  stdout.writeln('Znaleziono ${places.length} miejsc:');
  printStats(places.values);
  final noCity = places.values.where((p) => p['city'] == null).length;
  if (noCity > 0) stdout.writeln('  (bez przypisanego miasta: $noCity)');
  stdout.writeln('Najwięcej miejsc (top 40 miejscowości):');
  printStats(places.values, key: 'city', limit: 40);

  final out = File('supabase/seed/osm_places_woj_${slug(region)}.sql');
  await out.create(recursive: true);
  await out.writeAsString(placesToSql(places.values, 'województwo $region'));
  stdout.writeln('Zapisano: ${out.path}');
}

// ---------------------------------------------------------------- pobieranie

Future<File> _download(String region) async {
  final file = File('$_cacheDir/$region-latest.osm.pbf');
  if (await file.exists() &&
      DateTime.now().difference(await file.lastModified()).inDays < 7) {
    stdout.writeln('Używam pobranego pliku: ${file.path}');
    return file;
  }
  final url = 'https://download.geofabrik.de/europe/poland/$region-latest.osm.pbf';
  stdout.writeln('Pobieram $url ...');
  final client = HttpClient()..userAgent = _userAgent;
  try {
    final res = await (await client.getUrl(Uri.parse(url))).close();
    if (res.statusCode != 200) {
      throw HttpException('Geofabrik HTTP ${res.statusCode} — sprawdź nazwę województwa');
    }
    final tmp = File('${file.path}.part');
    await res.pipe(tmp.openWrite());
    await tmp.rename(file.path);
  } finally {
    client.close();
  }
  return file;
}

Future<File> _extract(File pbf, String name, List<String> filters) async {
  final filtered = '$_cacheDir/$name.osm.pbf';
  final geojson = '$_cacheDir/$name.geojsonseq';
  await _run('osmium', ['tags-filter', '-O', '-o', filtered, pbf.path, ...filters]);
  await _run('osmium', [
    'export', '-O', '-f', 'geojsonseq', '-u', 'type_id', '-o', geojson, filtered,
  ]);
  return File(geojson);
}

Future<void> _run(String cmd, List<String> args) async {
  final ProcessResult r;
  try {
    r = await Process.run(cmd, args);
  } on ProcessException {
    stderr.writeln('Brak programu "$cmd". Zainstaluj: brew install osmium-tool');
    exit(69);
  }
  if (r.exitCode != 0) {
    throw ProcessException(cmd, args, '${r.stderr}', r.exitCode);
  }
}

// ---------------------------------------------------------------- GeoJSON

Stream<Map<String, dynamic>> _features(File f) => f
    .openRead()
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .map((l) => l.replaceAll('\x1e', '').trim()) // separator rekordów RFC 8142
    .where((l) => l.isNotEmpty)
    .map((l) => jsonDecode(l) as Map<String, dynamic>);

Map<String, String> _tags(Map<String, dynamic> f) =>
    ((f['properties'] as Map?) ?? {}).map((k, v) => MapEntry('$k', '$v'));

/// Identyfikatory osmium (-u type_id) → format Overpass używany w places.osm_id.
/// Obszary ("a") mają id = 2*way_id albo 2*relation_id + 1.
String? _osmId(String id) {
  final n = int.tryParse(id.substring(1));
  if (n == null) return null;
  return switch (id[0]) {
    'n' => 'node/$n',
    'w' => 'way/$n',
    'r' => 'relation/$n',
    'a' => n.isEven ? 'way/${n ~/ 2}' : 'relation/${n ~/ 2}',
    _ => null,
  };
}

/// Środek obiektu: punkt, albo średnia wierzchołków zewnętrznego obrysu
/// (dla budynków i terenów sportowych wystarczająco dokładne).
(double, double)? _center(Map<String, dynamic> g) {
  final List<dynamic> pts = switch (g['type']) {
    'Point' => [g['coordinates']],
    'LineString' => g['coordinates'] as List,
    'Polygon' => (g['coordinates'] as List).first as List,
    'MultiPolygon' => ((g['coordinates'] as List).first as List).first as List,
    _ => const [],
  };
  if (pts.isEmpty) return null;
  var x = 0.0, y = 0.0;
  for (final p in pts) {
    x += (p as List)[0] as num;
    y += p[1] as num;
  }
  return (x / pts.length, y / pts.length);
}

// ---------------------------------------------------------------- granice

class _Boundary {
  _Boundary(this.name, this.level, this.rings) {
    for (final r in rings) {
      for (final (x, y) in r) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  final String name;
  final int level;
  final List<List<(double, double)>> rings;
  double minX = 180, maxX = -180, minY = 90, maxY = -90;

  /// Parzystość przecięć po wszystkich pierścieniach — obsługuje też dziury.
  bool contains(double x, double y) {
    if (x < minX || x > maxX || y < minY || y > maxY) return false;
    var inside = false;
    for (final r in rings) {
      for (var i = 0, j = r.length - 1; i < r.length; j = i++) {
        final (xi, yi) = r[i];
        final (xj, yj) = r[j];
        if ((yi > y) != (yj > y) &&
            x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
          inside = !inside;
        }
      }
    }
    return inside;
  }
}

/// Polska w OSM: 6 = powiat / miasto na prawach powiatu, 7 = gmina,
/// 8 = miejscowość (miasto lub wieś w gminie).
Future<List<_Boundary>> _loadBoundaries(File f) async {
  final out = <_Boundary>[];
  await for (final feat in _features(f)) {
    final id = feat['id'] as String;
    if (!id.startsWith('a')) continue;
    final t = _tags(feat);
    final level = int.tryParse(t['admin_level'] ?? '');
    final name = t['name'];
    if (name == null || level == null || level < 6 || level > 8) continue;
    final g = feat['geometry'] as Map<String, dynamic>;
    final polys = g['type'] == 'Polygon'
        ? [g['coordinates'] as List]
        : g['coordinates'] as List;
    final rings = [
      for (final poly in polys)
        for (final ring in poly as List)
          [
            for (final p in ring as List)
              (((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())
          ]
    ];
    out.add(_Boundary(name, level, rings));
  }
  // najpierw najdrobniejsze jednostki
  out.sort((a, b) => b.level - a.level);
  return out;
}

/// Miejscowość (8), a gdy jej brak — gmina (7) lub miasto na prawach
/// powiatu (6). Z nazw gmin usuwamy przedrostek "gmina ".
String? _cityAt(List<_Boundary> bs, double x, double y) {
  for (final b in bs) {
    if (b.level == 6 && !b.name.startsWith(RegExp(r'[A-ZŁŚŻŹĆ]'))) continue;
    if (b.contains(x, y)) {
      if (b.level == 6 && b.name.startsWith('powiat')) continue;
      return b.name.replaceFirst(RegExp(r'^gmina ', caseSensitive: false), '');
    }
  }
  return null;
}
