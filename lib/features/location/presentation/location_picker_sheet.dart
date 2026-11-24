import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/location_providers.dart';
import '../data/location_service.dart';
import '../domain/user_location.dart';

Future<void> showLocationPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.9,
      child: LocationPickerSheet(),
    ),
  );
}

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final _query = TextEditingController();
  bool _locating = false;
  GpsFailure? _gpsFailure;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _gpsFailure = null;
    });
    final failure = await ref
        .read(locationControllerProvider.notifier)
        .useGps();
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _locating = false;
        _gpsFailure = failure;
      });
    }
  }

  Future<void> _pickCity(CityOption city) async {
    await ref.read(locationControllerProvider.notifier).selectCity(city);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cities = ref.watch(citiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('Gdzie szukać zajęć?', style: theme.textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Wpisz miejscowość',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Wyczyść',
                      icon: const Icon(Icons.close),
                      onPressed: _query.clear,
                    ),
            ),
            onSubmitted: (_) {
              final matches = filterCities(
                cities.value ?? const [],
                _query.text,
              );
              if (matches.length == 1) _pickCity(matches.first);
            },
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: _locating
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.my_location, color: theme.colorScheme.primary),
          title: const Text('Użyj mojej lokalizacji'),
          subtitle: _gpsFailure == null
              ? null
              : Text(_failureMessage(_gpsFailure!)),
          onTap: _locating ? null : _useGps,
          trailing:
              _gpsFailure == GpsFailure.deniedForever ||
                  _gpsFailure == GpsFailure.serviceDisabled
              ? TextButton(
                  onPressed: () =>
                      ref.read(locationServiceProvider).openSettings(),
                  child: const Text('Ustawienia'),
                )
              : null,
        ),
        const Divider(),
        Expanded(
          child: cities.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message(
              'Nie udało się pobrać listy miejscowości.',
              action: TextButton(
                onPressed: () => ref.invalidate(citiesProvider),
                child: const Text('Spróbuj ponownie'),
              ),
            ),
            data: (all) {
              final matches = filterCities(all, _query.text);
              if (matches.isEmpty) {
                return const _Message(
                  'Nie mamy jeszcze miejsc w tej miejscowości.\n'
                  'Spróbuj pobliskiego większego miasta.',
                );
              }
              return ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: matches.length,
                itemBuilder: (_, i) {
                  final c = matches[i];
                  return ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: Text(c.name),
                    subtitle: Text(_placesLabel(c.placesCount)),
                    onTap: () => _pickCity(c),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Text(text, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );
}

String _failureMessage(GpsFailure f) => switch (f) {
  GpsFailure.serviceDisabled => 'Usługi lokalizacji są wyłączone. Włącz je w Ustawieniach albo wybierz miejscowość.',
  GpsFailure.denied =>
    'Bez zgody na lokalizację — wybierz miejscowość z listy.',
  GpsFailure.deniedForever =>
    'Dostęp do lokalizacji jest wyłączony. Możesz go włączyć w Ustawieniach.',
  GpsFailure.unavailable => 'Nie udało się ustalić położenia. Spróbuj ponownie albo wybierz miejscowość.',
};

/// „1 miejsce”, „3 miejsca”, „5 miejsc”, „22 miejsca”.
String _placesLabel(int n) {
  final mod10 = n % 10, mod100 = n % 100;
  if (n == 1) return '1 miejsce';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return '$n miejsca';
  }
  return '$n miejsc';
}
