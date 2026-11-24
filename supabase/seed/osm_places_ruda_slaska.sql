-- Obiekty sportowe z OpenStreetMap: Ruda Śląska (37 miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: 2026-11-23T08:30:40.791936
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website)
values
  ('node/1760047538', 'Klub Sportowy Zgoda Bielszowice', 'Sportowców 10', 'Ruda Śląska', st_setsrid(st_makepoint(18.840938, 50.2709596), 4326), null, 'https://www.zgoda-rudaslaska.com.pl/'),
  ('node/1779050027', 'Basen Kryty MOSIR', 'Chryzantem 10', 'Ruda Śląska', st_setsrid(st_makepoint(18.8467475, 50.3034055), 4326), null, 'https://mosir.rsl.pl/index.php?s=basen_ruda'),
  ('node/1779069856', 'Basen kryty MOSIR', 'Oświęcimska 90', 'Ruda Śląska', st_setsrid(st_makepoint(18.9099525, 50.2523744), 4326), null, 'https://mosir.rsl.pl/index.php?s=basen_kochlowice'),
  ('node/1779104702', 'Hala Widowiskowo-Sportowa im. Rudzkich Olimpijczyków', 'Kłodnicka 95', 'Ruda Śląska', st_setsrid(st_makepoint(18.8439886, 50.2424532), 4326), null, 'https://mosir.rsl.pl/index.php?s=hala_halemba'),
  ('node/6264755883', 'Hermes', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8673703, 50.270712), 4326), null, null),
  ('node/6317014944', 'SmartGym Aquadrom', 'Kłodnicka', 'Ruda Śląska', st_setsrid(st_makepoint(18.844432, 50.2414473), 4326), null, null),
  ('node/6317014945', 'Maximus Gym&Fitness', 'Kłodnicka', 'Ruda Śląska', st_setsrid(st_makepoint(18.8437493, 50.2423772), 4326), null, null),
  ('node/7536808148', 'PROFORMA', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8568846, 50.3102376), 4326), null, null),
  ('node/8463505468', 'Maximus Gym & Fitness', 'Bukowa 9', 'Ruda Śląska', st_setsrid(st_makepoint(18.8523238, 50.2823792), 4326), null, null),
  ('node/9631460524', 'Mini Park Linowy', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8523648, 50.2681689), 4326), null, null),
  ('node/9631460525', 'Tyrolka', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8528944, 50.2681261), 4326), null, null),
  ('node/10202395181', 'Xtreme Fitness', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8857065, 50.2698163), 4326), null, null),
  ('node/10205237266', 'Synergia', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8537452, 50.312779), 4326), null, null),
  ('node/10712493994', 'KTJ MMA Team', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8520444, 50.3128233), 4326), null, null),
  ('node/12170401205', 'Fioletova', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8560029, 50.3116093), 4326), null, null),
  ('node/12248603990', 'Just GYM', '1 Maja 383', 'Ruda Śląska', st_setsrid(st_makepoint(18.8533761, 50.2973414), 4326), '+48 732 660 430', 'https://justgym.pl/silownie/ruda-slaska/ruda/'),
  ('node/12897013576', 'body in motion', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8497382, 50.2515476), 4326), '+48 514 785 051', 'https://bodyinmotion.pl/'),
  ('node/12897013577', 'traning dla kobiet', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.849799, 50.2516129), 4326), '+48 514 785 051', 'https://studio.treningdlakobiet.pl/'),
  ('node/13296731120', 'Studio Figura', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8892472, 50.3180566), 4326), '+48 453 382 820', null),
  ('way/131347861', 'Lodowisko Burloch Arena', 'Bytomska 15', 'Ruda Śląska', st_setsrid(st_makepoint(18.876879, 50.3176249), 4326), null, null),
  ('way/167190077', 'Ścianka wspinaczkowa "Bunkier"', 'Obrońców Westerplatte 11e', 'Ruda Śląska', st_setsrid(st_makepoint(18.8737419, 50.2729889), 4326), null, 'https://wskale.pl/'),
  ('way/167603433', 'Studio Energia. Klub fitness', 'Obrońców Westerplatte 36', 'Ruda Śląska', st_setsrid(st_makepoint(18.8655372, 50.2767654), 4326), null, null),
  ('way/167642548', 'GKS Wawel Wirek', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.865148, 50.2711015), 4326), null, null),
  ('way/168768959', 'Fabryka Formy Ruda Śląska', 'Obrońców Westerplatte 29', 'Ruda Śląska', st_setsrid(st_makepoint(18.8684973, 50.2752385), 4326), null, 'https://fabryka-formy.pl/'),
  ('way/168873355', 'Hala Widowiskowo-Sportowa MOSIR', 'Generała Józefa Hallera 16b', 'Ruda Śląska', st_setsrid(st_makepoint(18.8701111, 50.2897016), 4326), null, 'https://mosir.rsl.pl/index.php?s=hala_nowy_bytom'),
  ('way/168873357', 'Sala Gimnastyczna Zespołu Szkół nr 5', 'Generała Józefa Hallera 14', 'Ruda Śląska', st_setsrid(st_makepoint(18.8709545, 50.2886404), 4326), null, null),
  ('way/179361505', 'Sala Gimnastyczna Szkoły Podstawowej nr 1', 'Objazdowa', 'Ruda Śląska', st_setsrid(st_makepoint(18.8720505, 50.2879442), 4326), null, null),
  ('way/205271296', 'Hala Sportowa KS Zgoda Bielszowice', 'Sportowców 10', 'Ruda Śląska', st_setsrid(st_makepoint(18.8406744, 50.2708355), 4326), null, null),
  ('way/205645414', 'Hala zapaśnicza im. Tadeusza Kuchara', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8787484, 50.3189241), 4326), null, null),
  ('way/205650139', 'Tytan', 'Bytomska 1a', 'Ruda Śląska', st_setsrid(st_makepoint(18.8838192, 50.3185343), 4326), null, null),
  ('way/206399486', 'Hala Tenisowa TKS Slavia', 'Pawła 3a', 'Ruda Śląska', st_setsrid(st_makepoint(18.8762652, 50.3058722), 4326), null, 'http://slavia.org.pl/'),
  ('way/231120520', 'Hala sportowa SP 14', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8540457, 50.2763182), 4326), null, null),
  ('way/307675136', 'DOJO Rudzki Klub Karate Kyokyushin', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8841212, 50.2824471), 4326), null, null),
  ('way/583712267', 'Basen kryty MOSIR', 'Pokoju 13', 'Ruda Śląska', st_setsrid(st_makepoint(18.8825358, 50.2861022), 4326), null, 'https://mosir.rsl.pl/obiekty-mosir/basen-kryty-nowy-bytom'),
  ('way/701401776', 'Całoroczne hale piłkarskie', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.8604972, 50.2813775), 4326), null, null),
  ('way/1307678300', 'Slavia Ruda Śląska', null, 'Ruda Śląska', st_setsrid(st_makepoint(18.841838, 50.3189811), 4326), null, null),
  ('way/1426714871', 'Hala Zapaśnicza K.S. Pogoń', 'Jadwigi Markowej 20A', 'Ruda Śląska', st_setsrid(st_makepoint(18.8728483, 50.2876858), 4326), null, null)
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website
where places.status = 'unclaimed';
