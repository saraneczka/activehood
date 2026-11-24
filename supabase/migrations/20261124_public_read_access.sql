-- Publiczny odczyt katalogu dla aplikacji (klucz publishable → rola anon).
-- Tylko SELECT i tylko wskazane kolumny; zapisy pozostają zablokowane.
--
-- Uwaga: przy uprawnieniach na poziomie kolumn zapytania typu `select *`
-- zwrócą "permission denied" — aplikacja musi wymieniać kolumny jawnie.

grant usage on schema public to anon, authenticated;

-- Najpierw zdejmujemy ewentualne uprawnienia do całych tabel,
-- inaczej grant na kolumny nic by nie ograniczał.
revoke select on public.places, public.classes, public.activity_types
  from anon, authenticated;

-- places: kolumny publiczne + id (potrzebne do łączenia z classes i ekranu szczegółów)
grant select (id, name, description, address, city, location, phone, website)
  on public.places to anon, authenticated;

-- classes: kolumny publiczne + klucze (id, miejsce, typ aktywności — do filtrów)
-- is_active: i tak widać tylko aktywne (polityka niżej), a funkcje wyszukiwania
-- mogą po niej filtrować.
grant select (id, place_id, activity_type_id, is_active,
              title, description, level, format, price_pln, schedule_note)
  on public.classes to anon, authenticated;

-- activity_types: słownik do filtra
grant select (id, name) on public.activity_types to anon, authenticated;

-- RLS: wiersze widoczne dla wszystkich (kolumny ogranicza grant powyżej)
alter table public.activity_types enable row level security;
alter table public.places         enable row level security;
alter table public.classes        enable row level security;

-- Reguły odczytu już istnieją ("... odczyt dla wszystkich", "zajęcia: odczyt aktywnych lub własnych").

grant execute on function public.search_classes_nearby to anon, authenticated;
