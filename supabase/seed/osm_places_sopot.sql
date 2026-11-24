-- Obiekty sportowe z OpenStreetMap: Sopot (6 miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: 2026-11-24T19:56:01.562109
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website)
values
  ('node/6422780900', 'Kręgielnia Aquapark Sopot', null, 'Sopot', st_setsrid(st_makepoint(18.5573492, 54.4596873), 4326), null, null),
  ('node/8926448805', 'Zdrofit', null, 'Sopot', st_setsrid(st_makepoint(18.5623256, 54.4411946), 4326), '+48 531 492 190', null),
  ('node/12197759323', 'KartCenter Sopot', '3 Maja 69C', 'Sopot', st_setsrid(st_makepoint(18.5633144, 54.4339686), 4326), '+48 692 277 978', 'https://kartcenter.pl/'),
  ('node/13096418858', 'Pit Gym', null, 'Sopot', st_setsrid(st_makepoint(18.5352688, 54.4572645), 4326), null, null),
  ('way/350468797', 'Hipodrom Sopot', 'Władysława Łokietka 1', 'Sopot', st_setsrid(st_makepoint(18.5709696, 54.4275624), 4326), null, null),
  ('way/697088824', 'Miejski Ośrodek Sportu i Rekreacji w Sopocie', 'Bitwy pod Płowcami 67C', 'Sopot', st_setsrid(st_makepoint(18.5859368, 54.4327484), 4326), null, null)
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website
where places.status = 'unclaimed';
