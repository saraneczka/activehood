import 'package:activehood/features/search/application/search_providers.dart';
import 'package:activehood/features/search/domain/class_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  searchTests();

  test('zmiana kategorii czyści wybrany rodzaj, reszta filtrów zostaje', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(searchFiltersProvider.notifier);

    n.setCategory(5);
    n.setActivityType(51);
    n.setLevel('beginner');
    n.setRadius(10);
    n.setCategory(6);

    final f = c.read(searchFiltersProvider);
    expect(f.categoryId, 6);
    expect(f.activityTypeId, isNull);
    expect(f.level, 'beginner');
    expect(f.radiusKm, 10);
  });

  test('ActivityCategory.fromMap sortuje rodzaje alfabetycznie', () {
    final cat = ActivityCategory.fromMap({
      'id': 5,
      'slug': 'taniec',
      'name': 'Taniec',
      'activity_types': [
        {'id': 52, 'name': 'Zumba'},
        {'id': 51, 'name': 'Hip-hop'},
      ],
    });
    expect(cat.types.map((t) => t.name), ['Hip-hop', 'Zumba']);
  });
}

const _catalog = [
  ActivityCategory(
    id: 5,
    slug: 'taniec',
    name: 'Taniec',
    types: [
      ActivityType(51, 'Salsa / bachata'),
      ActivityType(53, 'Taniec towarzyski'),
    ],
  ),
  ActivityCategory(
    id: 6,
    slug: 'sztuki_walki',
    name: 'Sztuki walki',
    types: [
      ActivityType(61, 'Brazylijskie jiu-jitsu (BJJ)'),
      ActivityType(62, 'Kung fu / Wushu'),
    ],
  ),
];

void searchTests() {
  test('pusta fraza zwraca same kategorie', () {
    final r = searchActivities(_catalog, ' ');
    expect(r.categories, hasLength(2));
    expect(r.types, isEmpty);
  });

  test('fraza trafia w kategorię i w rodzaje (początek słowa)', () {
    final r = searchActivities(_catalog, 'tan');
    expect(r.categories.map((c) => c.name), ['Taniec']);
    expect(r.types.map((e) => e.$2.name), ['Taniec towarzyski']);
  });

  test('bez polskich znaków i w środku nazwy po słowie', () {
    expect(searchActivities(_catalog, 'wushu').types.single.$2.id, 62);
    expect(searchActivities(_catalog, 'bjj').types.single.$1.id, 6);
    expect(searchActivities(_catalog, 'sztuki').categories.single.id, 6);
    expect(
      searchActivities(_catalog, 'ana').isEmpty,
      isTrue,
    ); // nie „w środku słowa”
  });
}
