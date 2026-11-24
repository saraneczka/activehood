-- Obiekty sportowe z OpenStreetMap: Bytom (24 miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: 2026-11-23T08:23:07.504270
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website)
values
  ('node/2035570980', 'Pływalnia kryta', null, 'Bytom', st_setsrid(st_makepoint(18.9135838, 50.3490188), 4326), '+48 32 281 27 70', 'https://osir.bytom.pl/nasze-obiekty/plywalnie/plywalnia-kryta/'),
  ('node/2035584674', 'Hala na skarpie', 'Andrzeja Frycza-Modrzewskiego 5a', 'Bytom', st_setsrid(st_makepoint(18.8975639, 50.3329395), 4326), '+48 601 141 111', 'https://skarpa.bytom.pl/'),
  ('node/2559719784', 'Siłownia Progress', null, 'Bytom', st_setsrid(st_makepoint(18.9191997, 50.3462193), 4326), null, null),
  ('node/3667698175', 'Siłownia', 'Jagiellońska 4', 'Bytom', st_setsrid(st_makepoint(18.9194685, 50.3461819), 4326), null, null),
  ('node/4723913290', 'Dynamic Gym', 'Alojzego Felińskiego 25a', 'Bytom', st_setsrid(st_makepoint(18.8458802, 50.365281), 4326), null, null),
  ('node/7503372500', 'justGYM', 'Gabriela Narutowicza 11g/6', 'Bytom', st_setsrid(st_makepoint(18.8783933, 50.3925512), 4326), '+48 690 020 320', null),
  ('node/8289096958', 'Well Fitness', null, 'Bytom', st_setsrid(st_makepoint(18.8964861, 50.3369313), 4326), null, 'https://wellfitness.pl/silownia/bytom'),
  ('node/8815465640', 'S-Kart', null, 'Bytom', st_setsrid(st_makepoint(18.8791899, 50.3509972), 4326), null, 'https://www.s-kart.pl/'),
  ('node/9592080167', 'strzelnica hokejowa Hattrick', 'Chorzowska 12', 'Bytom', st_setsrid(st_makepoint(18.9319574, 50.34158), 4326), null, null),
  ('node/11966781609', 'Future Sport Center', null, 'Bytom', st_setsrid(st_makepoint(18.9146349, 50.3471188), 4326), null, null),
  ('node/14058048235', 'Royal Bytom', 'Plac Kazimierza Kruczkowskiego 1', 'Bytom', st_setsrid(st_makepoint(18.9147414, 50.3477797), 4326), '+48 534 820 375', 'https://www.royalbytom.pl/'),
  ('way/48649005', 'Sport Dolina', null, 'Bytom', st_setsrid(st_makepoint(18.8580828, 50.4030074), 4326), null, 'https://sportdolina.pl/'),
  ('way/97247568', 'Hala sportowa OSiR Bytom', 'Kosynierów 15', 'Bytom', st_setsrid(st_makepoint(18.8824686, 50.3401744), 4326), null, null),
  ('way/135229159', 'Klub Sportowy Górnik Bytom', null, 'Bytom', st_setsrid(st_makepoint(18.906814, 50.3534927), 4326), null, 'https://www.ksgornik.bytom.pl/'),
  ('way/158007857', 'BTTS Silesia Miechowice', 'Józefa Nickla 143a', 'Bytom', st_setsrid(st_makepoint(18.8431337, 50.3648409), 4326), null, 'http://tenissilesia.miechowice.net'),
  ('way/167872372', 'GKS Rozbark', null, 'Bytom', st_setsrid(st_makepoint(18.9279433, 50.3364429), 4326), null, null),
  ('way/167872503', 'Maszynownia szybu Bończyk', 'Wojciecha Kilara 33', 'Bytom', st_setsrid(st_makepoint(18.9308986, 50.3427186), 4326), null, null),
  ('way/167904644', 'ŁKS Łagiewniki', null, 'Bytom', st_setsrid(st_makepoint(18.9336866, 50.3297596), 4326), null, null),
  ('way/169117944', 'Lodowisko im. Braci Nikodemowiczów', 'Kazimierza Pułaskiego 71', 'Bytom', st_setsrid(st_makepoint(18.8927399, 50.3484686), 4326), null, null),
  ('way/179997485', 'Xtreme Fitness Bytom', 'Krakowska 21', 'Bytom', st_setsrid(st_makepoint(18.9284512, 50.3460784), 4326), '+48728466853', 'http://xtremefitness.pl/bytom'),
  ('way/707057309', 'Zespół Boisk Piłkarskich OSiR', null, 'Bytom', st_setsrid(st_makepoint(18.9096629, 50.3265838), 4326), null, 'https://osir.bytom.pl/zespol-boisk-pilkarskich-ul-ostatnia-10/'),
  ('way/807954724', 'Centrum Sportów Wspinaczkowych i Siłowych Skarpa Bytom', null, 'Bytom', st_setsrid(st_makepoint(18.9292874, 50.3424253), 4326), null, null),
  ('way/1186493959', 'Emotion Karting', null, 'Bytom', st_setsrid(st_makepoint(18.8478498, 50.3473678), 4326), null, null),
  ('relation/450049', 'K.S. Czarni Sucha Góra', null, 'Bytom', st_setsrid(st_makepoint(18.8689538, 50.4005422), 4326), null, null)
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website
where places.status = 'unclaimed';
