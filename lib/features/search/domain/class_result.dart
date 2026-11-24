/// Jeden wiersz zwracany przez RPC `search_classes_nearby`.
class ClassResult {
  final String classId;
  final String title;
  final String activity;
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

class ActivityType {
  final int id;
  final String name;
  const ActivityType(this.id, this.name);
}

/// Wartości muszą odpowiadać tym w bazie.
const levelLabels = {
  'beginner': 'Początkujący',
  'intermediate': 'Średniozaawansowany',
  'advanced': 'Zaawansowany',
  'all_levels': 'Wszystkie poziomy',
};

const formatLabels = {'group': 'Grupowe', 'individual': 'Indywidualne'};
