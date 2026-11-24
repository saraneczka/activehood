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
        'p_activity_type_id': activityTypeId,
        'p_level': level,
        'p_format': format,
      },
    ) as List<dynamic>;
    return rows
        .map((r) => ClassResult.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Zakłada kolumny `id` i `name` w tabeli activity_types.
  Future<List<ActivityType>> activityTypes() async {
    final rows = await _db
        .from('activity_types')
        .select('id, name')
        .order('name');
    return rows
        .map((r) => ActivityType(r['id'] as int, r['name'] as String))
        .toList();
  }
}

final classesRepositoryProvider = Provider<ClassesRepository>(
  (ref) => ClassesRepository(ref.watch(supabaseClientProvider)),
);
