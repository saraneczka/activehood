enum LocationSource { gps, city }

/// Punkt, wokół którego szukamy zajęć.
class UserLocation {
  const UserLocation({
    required this.lat,
    required this.lng,
    required this.label,
    required this.source,
  });

  final double lat;
  final double lng;

  /// Tekst do wyświetlenia, np. „Bytom” albo „Twoja lokalizacja”.
  final String label;
  final LocationSource source;

  static const gpsLabel = 'Twoja lokalizacja';
}

/// Miejscowość z bazy (wynik RPC `list_cities`).
class CityOption {
  const CityOption({
    required this.name,
    required this.lat,
    required this.lng,
    required this.placesCount,
  });

  final String name;
  final double lat;
  final double lng;
  final int placesCount;

  factory CityOption.fromMap(Map<String, dynamic> m) => CityOption(
    name: m['city'] as String,
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    placesCount: (m['places_count'] as num).toInt(),
  );

  UserLocation toLocation() => UserLocation(
    lat: lat,
    lng: lng,
    label: name,
    source: LocationSource.city,
  );
}

/// Usuwa polskie znaki i wielkie litery — do wyszukiwania „lodz” → „Łódź”.
String normalizeForSearch(String s) {
  const map = {
    'ą': 'a',
    'ć': 'c',
    'ę': 'e',
    'ł': 'l',
    'ń': 'n',
    'ó': 'o',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
  };
  final lower = s.toLowerCase().trim();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(map[ch] ?? ch);
  }
  return buf.toString();
}

/// Miejscowości pasujące do [query]: najpierw zaczynające się od frazy,
/// potem zawierające ją w środku. Pusta fraza → wszystkie.
List<CityOption> filterCities(List<CityOption> cities, String query) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return cities;
  final starts = <CityOption>[];
  final contains = <CityOption>[];
  for (final c in cities) {
    final n = normalizeForSearch(c.name);
    if (n.startsWith(q)) {
      starts.add(c);
    } else if (n.contains(q)) {
      contains.add(c);
    }
  }
  return [...starts, ...contains];
}
