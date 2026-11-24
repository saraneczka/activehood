-- Lista miejscowości, w których są miejsca, ze środkiem (średnia współrzędnych).
-- Używana w aplikacji do ręcznego wyboru lokalizacji zamiast GPS.
-- SECURITY INVOKER: czyta tylko publiczne kolumny places (city, location).

create or replace function public.list_cities()
returns table(city text, lat double precision, lng double precision, places_count bigint)
language sql
stable
set search_path to 'public', 'extensions'
as $$
  select
    p.city,
    avg(st_y(p.location::geometry)),
    avg(st_x(p.location::geometry)),
    count(*)
  from places p
  where p.city is not null and p.city <> '' and p.location is not null
  group by p.city
  order by p.city;
$$;

grant execute on function public.list_cities() to anon, authenticated;
