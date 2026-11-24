-- Identyfikator obiektu w OpenStreetMap (np. 'node/123', 'way/456').
-- Pozwala ponownie importować dane z OSM bez tworzenia duplikatów.
-- Miejsca dodane ręcznie / przez właścicieli mają osm_id = null.
alter table public.places
  add column if not exists osm_id text unique;
