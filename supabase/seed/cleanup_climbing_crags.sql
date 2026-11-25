-- Usuwa skały wspinaczkowe i parki linowe zaimportowane wcześniej przez Overpass
-- (od teraz wykluczane w tool/osm_common.dart). Tylko nieprzejęte i bez zajęć.
delete from public.places p
where p.osm_id in ('way/676877983','way/676877984','way/676877989','way/676877990',
                   'node/9631460524','node/9631460525')
  and p.status = 'unclaimed'
  and not exists (select 1 from public.classes c where c.place_id = p.id);
