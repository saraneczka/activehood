import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/search_providers.dart';
import '../../domain/class_result.dart';
import 'category_icons.dart';

Future<void> showActivityPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.9,
      child: ActivityPickerSheet(),
    ),
  );
}

/// Wyszukiwarka aktywności: jedno pole przeszukuje kategorie (np. „Taniec”)
/// i rodzaje (np. „Salsa / bachata”). Bez frazy — lista kategorii.
class ActivityPickerSheet extends ConsumerStatefulWidget {
  const ActivityPickerSheet({super.key});

  @override
  ConsumerState<ActivityPickerSheet> createState() =>
      _ActivityPickerSheetState();
}

class _ActivityPickerSheetState extends ConsumerState<ActivityPickerSheet> {
  final _query = TextEditingController();

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

  void _select({int? categoryId, int? typeId}) {
    ref
        .read(searchFiltersProvider.notifier)
        .selectActivity(categoryId: categoryId, activityTypeId: typeId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = ref.watch(activityCatalogProvider);
    final filters = ref.watch(searchFiltersProvider);
    final hasQuery = _query.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('Jaka aktywność?', style: theme.textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Szukaj, np. joga, salsa, boks',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasQuery
                  ? IconButton(
                      tooltip: 'Wyczyść',
                      icon: const Icon(Icons.close),
                      onPressed: _query.clear,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: catalog.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const SizedBox.shrink(), // provider zwraca [] przy błędzie
            data: (all) {
              final r = searchActivities(all, _query.text);
              if (r.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nie znaleziono takiej aktywności.\n'
                    'Spróbuj innej nazwy albo wybierz kategorię.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (!hasQuery)
                    ListTile(
                      leading: const Icon(Icons.apps),
                      title: const Text('Wszystkie aktywności'),
                      selected: filters.categoryId == null,
                      onTap: () => _select(),
                    ),
                  if (hasQuery && r.categories.isNotEmpty)
                    const _SectionHeader('Kategorie'),
                  for (final c in r.categories)
                    ListTile(
                      leading: Icon(categoryIcon(c.slug)),
                      title: Text(c.name),
                      subtitle: Text(_typesLabel(c.types.length)),
                      selected:
                          filters.categoryId == c.id &&
                          filters.activityTypeId == null,
                      onTap: () => _select(categoryId: c.id),
                    ),
                  if (r.types.isNotEmpty) const _SectionHeader('Rodzaje zajęć'),
                  for (final (c, t) in r.types)
                    ListTile(
                      leading: Icon(categoryIcon(c.slug)),
                      title: Text(t.name),
                      subtitle: Text(c.name),
                      selected: filters.activityTypeId == t.id,
                      onTap: () => _select(categoryId: c.id, typeId: t.id),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// „1 rodzaj”, „3 rodzaje”, „5 rodzajów”, „22 rodzaje”.
String _typesLabel(int n) {
  final mod10 = n % 10, mod100 = n % 100;
  if (n == 1) return '1 rodzaj';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return '$n rodzaje';
  }
  return '$n rodzajów';
}
