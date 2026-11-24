# Activehood

Wyszukiwarka zajęć sportowych w okolicy (Flutter + Supabase). Priorytet: iOS.

## Uruchomienie

1. `cp config/dev.example.json config/dev.json` i uzupełnij `SUPABASE_URL` oraz `SUPABASE_ANON_KEY`
   (klucz publiczny z Supabase → Project Settings → API). Plik jest w `.gitignore`.
2. `flutter run --dart-define-from-file=config/dev.json`
   (w VS Code: konfiguracja „activehood (dev)”).

`.env` (`SUPABASE_DB_URL`) służy tylko narzędziom w `tool/` — nie trafia do aplikacji.

## Struktura `lib/`

```
lib/
  main.dart, app.dart          # start, ProviderScope, MaterialApp.router
  core/                        # wspólne: config, supabase, router, theme, widgets
  features/<funkcja>/
    domain/                    # modele
    data/                      # repozytoria, serwisy (Supabase, GPS)
    application/               # stan (Riverpod providers/notifiers)
    presentation/              # ekrany i widgety
```

Stan: `flutter_riverpod`, nawigacja: `go_router`, UI: Material 3 (`core/theme`).

## Dane

Miejsca pochodzą z OpenStreetMap (`tool/import_osm.dart`), © OpenStreetMap contributors, ODbL.
