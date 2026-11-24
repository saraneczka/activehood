import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/classes_repository.dart';
import '../../location/application/location_providers.dart';
import '../domain/class_result.dart';

class SearchFilters {
  const SearchFilters({
    this.activityTypeId,
    this.level,
    this.format,
    this.radiusKm = 5,
  });

  final int? activityTypeId;
  final String? level;
  final String? format;
  final int radiusKm;

  static const radiusOptionsKm = [1, 3, 5, 10, 25];
}

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void setActivity(int? id) => state = SearchFilters(
    activityTypeId: id,
    level: state.level,
    format: state.format,
    radiusKm: state.radiusKm,
  );

  void setLevel(String? level) => state = SearchFilters(
    activityTypeId: state.activityTypeId,
    level: level,
    format: state.format,
    radiusKm: state.radiusKm,
  );

  void setFormat(String? format) => state = SearchFilters(
    activityTypeId: state.activityTypeId,
    level: state.level,
    format: format,
    radiusKm: state.radiusKm,
  );

  void setRadius(int km) => state = SearchFilters(
    activityTypeId: state.activityTypeId,
    level: state.level,
    format: state.format,
    radiusKm: km,
  );
}

final searchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, SearchFilters>(
      SearchFiltersNotifier.new,
    );

/// Typy aktywności do filtra; przy błędzie pusta lista (filtr bez opcji).
final activityTypesProvider = FutureProvider<List<ActivityType>>((ref) async {
  try {
    return await ref.watch(classesRepositoryProvider).activityTypes();
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
        activityTypeId: filters.activityTypeId,
        level: filters.level,
        format: filters.format,
      );
});
