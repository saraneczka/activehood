import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/application/location_providers.dart';
import '../../location/presentation/location_bar.dart';
import '../../location/presentation/location_picker_sheet.dart';
import '../application/search_providers.dart';
import 'widgets/class_tile.dart';
import 'widgets/search_filters_bar.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zajęcia w okolicy')),
      body: const Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: LocationBar(),
          ),
          SearchFiltersBar(),
          Divider(height: 1),
          Expanded(child: _Results()),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationControllerProvider);
    if (location case AsyncData(value: null)) return const _ChooseLocation();

    final results = ref.watch(searchResultsProvider);
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nie udało się pobrać zajęć.\n$e',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(searchResultsProvider),
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'Brak zajęć spełniających kryteria.\nSpróbuj zwiększyć promień.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(searchResultsProvider.future),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ClassTile(items[i]),
          ),
        );
      },
    );
  }
}

/// Stan startowy, gdy nie ma ani zapamiętanej miejscowości, ani zgody na GPS.
class _ChooseLocation extends StatelessWidget {
  const _ChooseLocation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Gdzie szukać zajęć?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Wpisz miejscowość albo pozwól aplikacji użyć Twojej lokalizacji.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => showLocationPicker(context),
              icon: const Icon(Icons.search),
              label: const Text('Wybierz miejscowość'),
            ),
          ],
        ),
      ),
    );
  }
}
