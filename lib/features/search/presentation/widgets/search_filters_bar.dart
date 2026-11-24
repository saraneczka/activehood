import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/search_providers.dart';
import '../../domain/class_result.dart';

class SearchFiltersBar extends ConsumerWidget {
  const SearchFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);
    final notifier = ref.read(searchFiltersProvider.notifier);
    final activityTypes = ref.watch(activityTypesProvider).value ?? const [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  // key wymusza odświeżenie, gdy dociągną się typy aktywności
                  key: ValueKey(activityTypes.length),
                  initialValue: filters.activityTypeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Aktywność'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    for (final t in activityTypes)
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: notifier.setActivity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: filters.level,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Poziom'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Dowolny')),
                    for (final e in levelLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: notifier.setLevel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final e in formatLabels.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: filters.format == e.key,
                  onSelected: (sel) => notifier.setFormat(sel ? e.key : null),
                ),
              DropdownButton<int>(
                value: filters.radiusKm,
                underline: const SizedBox.shrink(),
                items: [
                  for (final km in SearchFilters.radiusOptionsKm)
                    DropdownMenuItem(value: km, child: Text('do $km km')),
                ],
                onChanged: (v) => notifier.setRadius(v!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
