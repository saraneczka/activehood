-- Reguły RLS na `classes` sprawdzały `places.owner_id` bezpośrednio.
-- Po ukryciu tej kolumny przed anon/authenticated (20261124_public_read_access.sql)
-- każdy odczyt `classes` kończył się "permission denied for table places".
--
-- Rozwiązanie: sprawdzenie własności w funkcji SECURITY DEFINER.
-- Zwraca tylko true/false dla bieżącego użytkownika — nie ujawnia owner_id.

create or replace function public.is_place_owner(p_place_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.places
    where id = p_place_id and owner_id = auth.uid()
  );
$$;

revoke all on function public.is_place_owner(uuid) from public;
grant execute on function public.is_place_owner(uuid) to anon, authenticated;

alter policy "zajęcia: odczyt aktywnych lub własnych" on public.classes
  using (is_active or public.is_place_owner(place_id));

alter policy "zajęcia: zarządzanie przez właściciela" on public.classes
  using (public.is_place_owner(place_id))
  with check (public.is_place_owner(place_id));

-- Duplikaty istniejących reguł odczytu, dodane w poprzedniej migracji.
drop policy if exists "public read" on public.activity_types;
drop policy if exists "public read" on public.places;
drop policy if exists "public read" on public.classes;
