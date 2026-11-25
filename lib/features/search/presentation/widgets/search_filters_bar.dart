import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/search_providers.dart';
import '../../domain/class_result.dart';
import 'activity_picker_sheet.dart';
import 'category_icons.dart';

class SearchFiltersBar extends ConsumerWidget {
  const SearchFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);
    final notifier = ref.read(searchFiltersProvider.notifier);
    final catalog = ref.watch(activityCatalogProvider).value ?? const [];
    final selectedCategory = catalog
        .where((c) => c.id == filters.categoryId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActivityField(
                    category: selectedCategory,
                    typeName: selectedCategory?.types
                        .where((t) => t.id == filters.activityTypeId)
                        .firstOrNull
                        ?.name,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: filters.level,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Poziom'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Dowolny'),
                      ),
                      for (final e in levelLabels.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: notifier.setLevel,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: selectedCategory == null || selectedCategory.types.isEmpty
                ? const SizedBox(width: double.infinity)
                : _TypeChips(
                    category: selectedCategory,
                    selectedTypeId: filters.activityTypeId,
                    onSelected: notifier.setActivityType,
                  ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
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
          ),
        ],
      ),
    );
  }
}

/// Pole „Aktywność” — otwiera wyszukiwarkę kategorii i rodzajów.
class _ActivityField extends StatelessWidget {
  const _ActivityField({required this.category, required this.typeName});

  final ActivityCategory? category;
  final String? typeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = category;
    return InkWell(
      onTap: () => showActivityPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Aktywność',
          suffixIcon: Icon(Icons.search),
        ),
        child: Row(
          children: [
            if (c != null) ...[
              Icon(
                categoryIcon(c.slug),
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                typeName ?? c?.name ?? 'Wszystkie',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Druga lista wyboru: rodzaje w wybranej kategorii (przewijana poziomo).
/// Wybrany rodzaj (np. z wyszukiwarki) jest przewijany do widoku.
class _TypeChips extends StatefulWidget {
  const _TypeChips({
    required this.category,
    required this.selectedTypeId,
    required this.onSelected,
  });

  final ActivityCategory category;
  final int? selectedTypeId;
  final ValueChanged<int?> onSelected;

  @override
  State<_TypeChips> createState() => _TypeChipsState();
}

class _TypeChipsState extends State<_TypeChips> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(_TypeChips old) {
    super.didUpdateWidget(old);
    if (old.selectedTypeId != widget.selectedTypeId ||
        old.category.id != widget.category.id) {
      _revealSelected();
    }
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final options = <(int?, String)>[
      (null, 'Wszystkie: ${category.name.toLowerCase()}'),
      for (final t in category.types) (t.id, t.name),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        key: PageStorageKey('types-${category.id}'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final (id, label) in options)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: widget.selectedTypeId == id ? _selectedKey : null,
                  label: Text(label),
                  selected: widget.selectedTypeId == id,
                  onSelected: (_) => widget.onSelected(id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
