import '../../../core/text/search_normalize.dart';

/// Jeden wiersz zwracany przez RPC `search_classes_nearby`.
class ClassResult {
  final String classId;
  final String title;
  final String activity;

  /// Kategoria aktywności (np. „Taniec”); null dla starszej wersji RPC.
  final String? category;
  final String level;
  final String format;
  final num? pricePln;
  final String? scheduleNote;
  final String placeId;
  final String placeName;
  final String? address;
  final double placeLat;
  final double placeLng;
  final double distanceM;

  const ClassResult({
    required this.classId,
    required this.title,
    required this.activity,
    this.category,
    required this.level,
    required this.format,
    required this.pricePln,
    required this.scheduleNote,
    required this.placeId,
    required this.placeName,
    required this.address,
    required this.placeLat,
    required this.placeLng,
    required this.distanceM,
  });

  factory ClassResult.fromMap(Map<String, dynamic> m) => ClassResult(
    classId: m['class_id'].toString(),
    title: m['title'] as String? ?? '',
    activity: m['activity'] as String? ?? '',
    level: m['level'] as String? ?? '',
    format: m['format'] as String? ?? '',
    pricePln: m['price_pln'] as num?,
    scheduleNote: m['schedule_note'] as String?,
    placeId: m['place_id'].toString(),
    placeName: m['place_name'] as String? ?? '',
    address: m['address'] as String?,
    placeLat: (m['place_lat'] as num).toDouble(),
    placeLng: (m['place_lng'] as num).toDouble(),
    distanceM: (m['distance_m'] as num).toDouble(),
  );

  String get distanceLabel => distanceM < 1000
      ? '${distanceM.round()} m'
      : '${(distanceM / 1000).toStringAsFixed(1)} km';
}

/// Rodzaj aktywności (podkategoria), np. „Salsa / bachata”.
class ActivityType {
  final int id;
  final String name;
  const ActivityType(this.id, this.name);
}

/// Kategoria aktywności, np. „Taniec”, z rodzajami w środku.
class ActivityCategory {
  const ActivityCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.types,
  });

  final int id;

  /// Stały identyfikator (np. `taniec`) — do ikon w aplikacji.
  final String slug;
  final String name;
  final List<ActivityType> types;

  factory ActivityCategory.fromMap(Map<String, dynamic> m) {
    final types = [
      for (final t in (m['activity_types'] as List<dynamic>? ?? const []))
        ActivityType(
          (t as Map<String, dynamic>)['id'] as int,
          t['name'] as String,
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return ActivityCategory(
      id: m['id'] as int,
      slug: m['slug'] as String,
      name: m['name'] as String,
      types: types,
    );
  }
}

/// Wynik wyszukiwania aktywności: pasujące kategorie i pasujące rodzaje
/// (każdy z kategorią, do której należy).
class ActivitySearchResult {
  const ActivitySearchResult(this.categories, this.types);
  final List<ActivityCategory> categories;
  final List<(ActivityCategory, ActivityType)> types;

  bool get isEmpty => categories.isEmpty && types.isEmpty;
}

/// Szuka [query] w nazwach kategorii i rodzajów (bez polskich znaków).
/// Pusta fraza → same kategorie.
ActivitySearchResult searchActivities(
  List<ActivityCategory> catalog,
  String query,
) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return ActivitySearchResult(catalog, const []);
  return ActivitySearchResult(
    [
      for (final c in catalog)
        if (matchesQuery(c.name, q)) c,
    ],
    [
      for (final c in catalog)
        for (final t in c.types)
          if (matchesQuery(t.name, q)) (c, t),
    ],
  );
}

/// Wartości muszą odpowiadać tym w bazie.
const levelLabels = {
  'beginner': 'Początkujący',
  'intermediate': 'Średniozaawansowany',
  'advanced': 'Zaawansowany',
  'all_levels': 'Wszystkie poziomy',
};

const formatLabels = {'group': 'Grupowe', 'individual': 'Indywidualne'};
