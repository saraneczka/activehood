import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/application/location_providers.dart';
import '../data/classes_repository.dart';
import '../domain/class_result.dart';

class SearchFilters {
  const SearchFilters({
    this.categoryId,
    this.activityTypeId,
    this.level,
    this.format,
    this.radiusKm = 5,
  });

  /// Kategoria (np. Taniec); null = wszystkie.
  final int? categoryId;

  /// Rodzaj w obrębie kategorii (np. Salsa / bachata); null = cała kategoria.
  final int? activityTypeId;
  final String? level;
  final String? format;
  final int radiusKm;

  static const radiusOptionsKm = [1, 3, 5, 10, 25];
}

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  SearchFilters _copy({
    int? Function()? categoryId,
    int? Function()? activityTypeId,
    String? Function()? level,
    String? Function()? format,
    int? radiusKm,
  }) => SearchFilters(
    categoryId: categoryId != null ? categoryId() : state.categoryId,
    activityTypeId: activityTypeId != null
        ? activityTypeId()
        : state.activityTypeId,
    level: level != null ? level() : state.level,
    format: format != null ? format() : state.format,
    radiusKm: radiusKm ?? state.radiusKm,
  );

  /// Zmiana kategorii zawsze czyści wybrany rodzaj.
  void setCategory(int? id) =>
      state = _copy(categoryId: () => id, activityTypeId: () => null);

  void setActivityType(int? id) => state = _copy(activityTypeId: () => id);

  /// Wybór z wyszukiwarki: kategoria i (opcjonalnie) konkretny rodzaj.
  void selectActivity({required int? categoryId, int? activityTypeId}) =>
      state = _copy(
        categoryId: () => categoryId,
        activityTypeId: () => activityTypeId,
      );

  void setLevel(String? level) => state = _copy(level: () => level);

  void setFormat(String? format) => state = _copy(format: () => format);

  void setRadius(int km) => state = _copy(radiusKm: km);
}

final searchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, SearchFilters>(
      SearchFiltersNotifier.new,
    );

/// Kategorie z rodzajami do filtra; przy błędzie pusta lista (filtr bez opcji).
final activityCatalogProvider = FutureProvider<List<ActivityCategory>>((
  ref,
) async {
  try {
    return await ref.watch(classesRepositoryProvider).activityCatalog();
  } catch (_) {
    return const [];
  }
});

/// Wyniki wyszukiwania — przeliczane przy zmianie filtrów lub lokalizacji.
/// Bez wybranej lokalizacji: pusta lista (ekran pokazuje wtedy zachętę do wyboru).
final searchResultsProvider = FutureProvider<List<ClassResult>>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  final location = await ref.watch(locationControllerProvider.future);
  if (location == null) return const [];
  return ref
      .watch(classesRepositoryProvider)
      .searchNearby(
        lat: location.lat,
        lng: location.lng,
        radiusM: filters.radiusKm * 1000,
        categoryId: filters.categoryId,
        activityTypeId: filters.activityTypeId,
        level: filters.level,
        format: filters.format,
      );
});
