-- Obiekty sportowe z OpenStreetMap: Czeladź (8 miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: 2026-11-23T09:20:37.446875
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website)
values
  ('node/4486195889', 'Millenium Centrum Sportu w Czeladzi', null, 'Czeladź', st_setsrid(st_makepoint(19.092861, 50.307311), 4326), null, 'https://www.millenium.info.pl/szkola-plywania,6'),
  ('node/7053277176', 'Lodowisko', null, 'Czeladź', st_setsrid(st_makepoint(19.0991348, 50.3013662), 4326), null, null),
  ('node/7234063712', 'Bawialnia Wesołe Safari', 'Sportowa 2', 'Czeladź', st_setsrid(st_makepoint(19.0674519, 50.3164566), 4326), null, null),
  ('node/7457909456', 'STRONG HOUSE Fitness&Fight Club', null, 'Czeladź', st_setsrid(st_makepoint(19.0720347, 50.3253301), 4326), null, null),
  ('way/142714332', 'Basen pływacki', null, 'Czeladź', st_setsrid(st_makepoint(19.0655996, 50.313402), 4326), null, null),
  ('way/938101193', 'Basen rekreacyjny', null, 'Czeladź', st_setsrid(st_makepoint(19.0653992, 50.3134714), 4326), null, null),
  ('way/938101194', 'Wodny plac zabaw', null, 'Czeladź', st_setsrid(st_makepoint(19.0651717, 50.3135483), 4326), null, null),
  ('way/938101195', 'Brodzik rekreacyjny', null, 'Czeladź', st_setsrid(st_makepoint(19.0654445, 50.3137502), 4326), null, null)
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website
where places.status = 'unclaimed';
