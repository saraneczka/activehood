import 'package:flutter/material.dart';

/// Ikona kategorii po jej `slug` z bazy. Nieznana kategoria → ikona ogólna.
IconData categoryIcon(String slug) => switch (slug) {
  'silownia' => Icons.fitness_center,
  'fitness' => Icons.sports_gymnastics,
  'cardio' => Icons.directions_bike,
  'joga' => Icons.self_improvement,
  'taniec' => Icons.nightlife,
  'sztuki_walki' => Icons.sports_martial_arts,
  'samoobrona' => Icons.shield_outlined,
  'bron' => Icons.sports_kabaddi,
  'woda' => Icons.pool,
  'sporty_zespolowe' => Icons.sports_tennis,
  'specjalne' => Icons.diversity_3,
  'zdrowie' => Icons.spa_outlined,
  _ => Icons.interests_outlined,
};
