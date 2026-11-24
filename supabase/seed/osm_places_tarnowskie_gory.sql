-- Obiekty sportowe z OpenStreetMap: Tarnowskie Góry (14 miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: 2026-11-23T10:52:48.048803
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website)
values
  ('node/3681756354', 'MKS Skarbek', 'Stanisława Wyspiańskiego 3', 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8493452, 50.4436313), 4326), null, 'https://skarbek.tarnogorski.pl/'),
  ('node/3681760320', 'UKS Dwójka Tarnowskie Góry', 'Stanisława Wyspiańskiego 3', 'Tarnowskie Góry', st_setsrid(st_makepoint(18.849296, 50.4434976), 4326), '+48 606941957', 'https://judotg.pl/'),
  ('node/4419923709', 'Strefa Ruchu', null, 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8289912, 50.4437553), 4326), null, null),
  ('node/8599074124', 'Sala judo nr 2 Uczniowski Klub Sportowy "Dwójka"', 'Mieczysława Niedziałkowskiego 31', 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8235137, 50.4388383), 4326), null, null),
  ('node/9195950768', 'Tytan Gym&Fit', null, 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8271771, 50.4189118), 4326), null, null),
  ('node/9992436964', 'Atomic CrossBox', null, 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8705962, 50.4355771), 4326), '+48 698 971 285', null),
  ('node/13068217811', 'Xtreme Fitness Gyms', null, 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8812216, 50.4433321), 4326), null, 'https://www.xtremefitness.pl/'),
  ('node/13261356608', 'NavaYoga Studio', 'Księdza Henryka Renka 11F', 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8151172, 50.4166347), 4326), '+48 698 439 299', 'https://navayoga.eu/'),
  ('node/13261359131', 'Fudoshinkan', 'Księdza Henryka Renka 11F', 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8151338, 50.4166913), 4326), '+48 602 144 447', 'https://kendo-iaido.eu/'),
  ('way/110002655', 'Rockets Center', null, 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8551141, 50.4523584), 4326), null, null),
  ('way/110003661', 'Xtreme Fitness', null, 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8556134, 50.4523123), 4326), null, null),
  ('way/110004057', 'Altis', 'Jana Styczyńskiego 18', 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8629215, 50.4496279), 4326), null, null),
  ('way/239301376', 'Hala Sportowa', null, 'Tarnowskie Góry', st_setsrid(st_makepoint(18.8392713, 50.4381743), 4326), null, null),
  ('way/1374954494', 'KS Górnik Bobrowniki Śląskie', 'Piotra Skargi 15', 'Tarnowskie Góry', st_setsrid(st_makepoint(18.876576, 50.4246643), 4326), null, null)
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website
where places.status = 'unclaimed';
