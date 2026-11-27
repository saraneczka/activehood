-- Źródło wpisu w places: 'osm' (import z OpenStreetMap), 'manual' (lista własna),
-- później np. 'owner' (dodane przez właściciela w panelu).
alter table public.places
  add column if not exists source text;

update public.places set source = 'osm'    where source is null and osm_id is not null;
update public.places set source = 'manual' where source is null;

alter table public.places alter column source set default 'manual';
alter table public.places alter column source set not null;
