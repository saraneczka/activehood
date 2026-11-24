import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/location_providers.dart';
import '../domain/user_location.dart';
import 'location_picker_sheet.dart';

/// Pasek „📍 Bytom ▾” — otwiera wybór lokalizacji.
class LocationBar extends ConsumerWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = ref.watch(locationControllerProvider);
    final value = loc.value;
    final label = switch (loc) {
      AsyncLoading() when value == null => 'Ustalam lokalizację…',
      _ => value?.label ?? 'Wybierz lokalizację',
    };

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => showLocationPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                value?.source == LocationSource.gps
                    ? Icons.my_location
                    : Icons.place_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Zmień',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
