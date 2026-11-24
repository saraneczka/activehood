import 'package:flutter_test/flutter_test.dart';

import 'package:activehood/features/search/domain/class_result.dart';

void main() {
  test('ClassResult parses RPC row', () {
    final c = ClassResult.fromMap({
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
      'place_lat': 52.23,
      'place_lng': 21.01,
      'distance_m': 1530.4,
    });
    expect(c.title, 'Joga poranna');
    expect(c.distanceLabel, '1.5 km');
  });
}
