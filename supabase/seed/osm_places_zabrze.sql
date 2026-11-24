-- Obiekty sportowe z OpenStreetMap: Zabrze (16 miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: 2026-11-23T08:22:20.290842
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website)
values
  ('node/1583890470', 'Teren sportowy', null, 'Zabrze', st_setsrid(st_makepoint(18.7763294, 50.3224977), 4326), null, null),
  ('node/2498634189', 'Fit&Fight Club', null, 'Zabrze', st_setsrid(st_makepoint(18.7779239, 50.2961188), 4326), null, null),
  ('node/2498634195', 'Studio Sportu i Rekreacji Activ', null, 'Zabrze', st_setsrid(st_makepoint(18.7756193, 50.3012214), 4326), null, null),
  ('node/7931868693', 'Smart Gym', 'Franklina Roosevelta 81', 'Zabrze', st_setsrid(st_makepoint(18.7696856, 50.2956019), 4326), '+48 12 200 28 00', 'https://smartgym.club/zabrze/'),
  ('node/9448663859', 'Xtreme Fitness', 'Aleja Szczęście Ludwika 2B', 'Zabrze', st_setsrid(st_makepoint(18.7868015, 50.3276301), 4326), null, null),
  ('node/10536312124', 'ReShape', null, 'Zabrze', st_setsrid(st_makepoint(18.7793432, 50.3037373), 4326), null, null),
  ('node/11879396270', 'SlimGym', null, 'Zabrze', st_setsrid(st_makepoint(18.7824994, 50.2974297), 4326), null, null),
  ('way/112979957', 'MKS Zabrze-Kończyce', null, 'Zabrze', st_setsrid(st_makepoint(18.7979321, 50.2768569), 4326), null, null),
  ('way/168448489', 'Orlik', null, 'Zabrze', st_setsrid(st_makepoint(18.7368554, 50.3089742), 4326), null, null),
  ('way/202692682', 'Hala Sportowa Pogoń Zabrze', 'Wolności 406', 'Zabrze', st_setsrid(st_makepoint(18.8058689, 50.2964505), 4326), null, null),
  ('way/202734307', 'Hala Widowiskowo-Sportowa MOSiR', 'Jana Matejki 6', 'Zabrze', st_setsrid(st_makepoint(18.7892206, 50.2920461), 4326), null, null),
  ('way/202806392', 'Miejski Zakład Kąpielowy', 'Plac Krakowski 10', 'Zabrze', st_setsrid(st_makepoint(18.7874128, 50.3020719), 4326), null, null),
  ('way/236011575', 'KS Koksownik', null, 'Zabrze', st_setsrid(st_makepoint(18.797851, 50.2949466), 4326), null, null),
  ('way/346043071', 'Orlik', null, 'Zabrze', st_setsrid(st_makepoint(18.7657011, 50.312926), 4326), null, null),
  ('way/1186081737', 'tor24.pl', null, 'Zabrze', st_setsrid(st_makepoint(18.7544202, 50.318452), 4326), null, 'https://tor24.pl/'),
  ('way/1434497147', 'Pogoń Zabrze', null, 'Zabrze', st_setsrid(st_makepoint(18.8209659, 50.29642), 4326), null, null)
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website
where places.status = 'unclaimed';
