-- Obiekty sportowe z OpenStreetMap: Chorzów (26 miejsc)
-- Dane © OpenStreetMap contributors, ODbL 1.0
-- Wygenerowano: 2026-11-23T08:23:43.057668
--
-- Ponowne uruchomienie aktualizuje istniejące wiersze po osm_id,
-- ale NIE nadpisuje miejsc przejętych przez właścicieli (status <> 'unclaimed').

insert into public.places (osm_id, name, address, city, location, phone, website)
values
  ('node/1940473939', 'Basen KS Hajduki', 'Graniczna 92', 'Chorzów', st_setsrid(st_makepoint(18.9273294, 50.2743831), 4326), null, null),
  ('node/2478273060', 'Golden Fit', null, 'Chorzów', st_setsrid(st_makepoint(18.927834, 50.2738889), 4326), null, 'https://goldenfit.pl/'),
  ('node/2807582761', 'Body Fit Studio', 'Boczna 12', 'Chorzów', st_setsrid(st_makepoint(18.9358025, 50.2976153), 4326), '+48 32 307 71 00', 'http://www.bodystudio.biz/'),
  ('node/3511696835', 'Strzelnica EMJOT', 'Aleja Harcerska 3b', 'Chorzów', st_setsrid(st_makepoint(18.9750457, 50.2919283), 4326), null, 'https://www.strzelnica.com.pl/1,4,kontakt.html'),
  ('node/5282185321', 'Fitnes w terenie', null, 'Chorzów', st_setsrid(st_makepoint(18.9368057, 50.3010314), 4326), null, null),
  ('node/5282302621', 'BASEN  MOSIR', null, 'Chorzów', st_setsrid(st_makepoint(18.9498778, 50.3018077), 4326), '+48 32 241 30 67', null),
  ('node/9354092870', 'xtreme fitness', 'Księdza Jana Gałeczki 30', 'Chorzów', st_setsrid(st_makepoint(18.9579854, 50.2869029), 4326), '+48538385110', 'https://xfg.pl/chorzow'),
  ('node/9402215754', 'Lodowisko – KS Hajduki', null, 'Chorzów', st_setsrid(st_makepoint(18.9285925, 50.2743466), 4326), null, null),
  ('node/10267682973', 'Saturn Fitness', 'Katowicka 47', 'Chorzów', st_setsrid(st_makepoint(18.9595704, 50.2910301), 4326), '+48 570 963 687', 'https://chorzow.saturn-fitness.pl/'),
  ('node/12192593895', 'Tańcówka Art Studio Filia 2', null, 'Chorzów', st_setsrid(st_makepoint(18.9586147, 50.2870601), 4326), '+48 507 321 955; +48 790 656 523', 'https://tancowka-artstudio.pl/'),
  ('node/13596394897', 'Strzelnica Hajduki', 'Stalowa 17/Budynek 43', 'Chorzów', st_setsrid(st_makepoint(18.937014, 50.2800639), 4326), null, 'https://strzelnicahajduki.pl/'),
  ('node/14008422647', 'Strength Body', null, 'Chorzów', st_setsrid(st_makepoint(18.9525942, 50.2700856), 4326), null, 'https://sbody.pl/'),
  ('way/38892781', 'Kąpielisko Fala', null, 'Chorzów', st_setsrid(st_makepoint(18.985881, 50.2858267), 4326), null, 'https://parkslaski.pl/kapielisko-fala'),
  ('way/38892811', 'Korty tenisowe', null, 'Chorzów', st_setsrid(st_makepoint(18.9840307, 50.2794191), 4326), null, null),
  ('way/128886863', 'Basen Skałka', null, 'Chorzów', st_setsrid(st_makepoint(18.9253566, 50.2988865), 4326), null, null),
  ('way/174747044', 'Interfit', '3 Maja 169', 'Chorzów', st_setsrid(st_makepoint(18.9250156, 50.3034653), 4326), null, null),
  ('way/182947079', 'freestyle park', 'Stalowa 25', 'Chorzów', st_setsrid(st_makepoint(18.9379191, 50.27926), 4326), null, 'https://park.freestylepark.pl/'),
  ('way/183637254', 'Kompleks Sportowy Hajduki', 'Graniczna 92', 'Chorzów', st_setsrid(st_makepoint(18.9274285, 50.2746398), 4326), '+48 32 246 77 62', 'https://www.moris.chorzow.pl/'),
  ('way/183637277', 'MORiS Chorzów', 'Generała Henryka Dąbrowskiego 113', 'Chorzów', st_setsrid(st_makepoint(18.9419999, 50.283996), 4326), '+48 32 241 70 50; +48 32 241 70 55', 'https://www.moris.chorzow.pl/'),
  ('way/245759924', 'Zdrofit', 'Stefana Batorego 29A', 'Chorzów', st_setsrid(st_makepoint(18.9402483, 50.2716174), 4326), '+48880766643', null),
  ('way/275703445', 'Tor Kolarski', null, 'Chorzów', st_setsrid(st_makepoint(18.9803086, 50.296205), 4326), null, null),
  ('way/500256943', 'Orlik', null, 'Chorzów', st_setsrid(st_makepoint(18.9636674, 50.2981401), 4326), null, 'https://moris.chorzow.pl/obiekty/orlik-kosciuszki/'),
  ('way/517039191', 'CityFit', null, 'Chorzów', st_setsrid(st_makepoint(18.9658252, 50.2909219), 4326), null, 'https://cityfit.pl/kluby/chorzow-aks/'),
  ('way/781953984', 'Gym&Fitness Maximus', 'Volkmara Meitzena 3', 'Chorzów', st_setsrid(st_makepoint(18.9554676, 50.2989743), 4326), null, null),
  ('way/1090764881', 'E1Gokart Chorzów', 'Gabriela Narutowicza 9', 'Chorzów', st_setsrid(st_makepoint(18.9722031, 50.3132851), 4326), null, 'https://chorzow.e1gokart.pl/'),
  ('way/1108311236', 'Kompleks Sportowy Kresy', null, 'Chorzów', st_setsrid(st_makepoint(18.9381721, 50.2846631), 4326), null, null)
on conflict (osm_id) do update set
  name     = excluded.name,
  address  = excluded.address,
  city     = excluded.city,
  location = excluded.location,
  phone    = excluded.phone,
  website  = excluded.website
where places.status = 'unclaimed';
