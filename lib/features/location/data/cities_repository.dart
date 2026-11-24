import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../domain/user_location.dart';

class CitiesRepository {
  CitiesRepository(this._db);

  final SupabaseClient _db;

  Future<List<CityOption>> listCities() async {
    final rows = await _db.rpc('list_cities') as List<dynamic>;
    return rows
        .map((r) => CityOption.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}

final citiesRepositoryProvider = Provider<CitiesRepository>(
  (ref) => CitiesRepository(ref.watch(supabaseClientProvider)),
);
