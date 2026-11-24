import 'package:flutter/material.dart';

/// Wspólny motyw Material 3 (jasny i ciemny z jednego koloru bazowego).
abstract final class AppTheme {
  static const _seed = Colors.teal;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 1,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
