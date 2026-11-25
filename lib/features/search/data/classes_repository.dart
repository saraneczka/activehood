import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../domain/class_result.dart';

class ClassesRepository {
  ClassesRepository([SupabaseClient? client])
    : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  Future<List<ClassResult>> searchNearby({
    required double lat,
    required double lng,
    required int radiusM,
    int? categoryId,
    int? activityTypeId,
    String? level,
    String? format,
  }) async {
    final rows = await _db.rpc(
      'search_classes_nearby',
      params: {
        'lat': lat,
        'lng': lng,
        'radius_m': radiusM,
        'p_category_id': categoryId,
        'p_activity_type_id': activityTypeId,
        'p_level': level,
        'p_format': format,
      },
    ) as List<dynamic>;
    return rows
        .map((r) => ClassResult.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Kategorie z rodzajami (podkategoriami), w kolejności `sort_order`.
  Future<List<ActivityCategory>> activityCatalog() async {
    final rows = await _db
        .from('activity_categories')
        .select('id, slug, name, activity_types(id, name)')
        // uwaga: w supabase-dart domyślnie ascending = false
        .order('sort_order', ascending: true);
    return rows.map(ActivityCategory.fromMap).toList();
  }
}

final classesRepositoryProvider = Provider<ClassesRepository>(
  (ref) => ClassesRepository(ref.watch(supabaseClientProvider)),
);
