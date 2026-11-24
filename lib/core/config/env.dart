/// Konfiguracja przekazywana przy budowaniu:
///   flutter run --dart-define-from-file=config/dev.json
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void ensureConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Brak SUPABASE_URL / SUPABASE_ANON_KEY. '
        'Uruchom z --dart-define-from-file=config/dev.json '
        '(wzór: config/dev.example.json).',
      );
    }
  }
}
