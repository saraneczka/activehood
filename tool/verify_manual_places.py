"""Weryfikacja i import własnej listy obiektów (supabase/seed/raw/obiekty_wlasne.csv).

Etapy (wyniki cache'owane w .osm_cache/, można przerywać i wznawiać):
  1. geocode  – współrzędne z adresu przez Nominatim (OSM), max 1 zapytanie/s
  2. web      – czy strona www działa; czy jest na niej telefon / ulica / nazwa
  3. report   – dopasowanie do istniejących miejsc w bazie, klasyfikacja,
                plik SQL + raport CSV z obiektami do ręcznej weryfikacji

Użycie:
  python3 tool/verify_manual_places.py geocode
  python3 tool/verify_manual_places.py web
  python3 tool/verify_manual_places.py report

Zasady:
  * telefon/www trafiają do bazy TYLKO jeśli zostały potwierdzone na działającej
    stronie obiektu (numer widoczny na stronie); inaczej zostają puste,
  * obiekt nowy jest importowany tylko gdy adres znaleziono z dokładnością do
    budynku ORAZ strona potwierdza obiekt (telefon albo ulica na stronie),
  * obiekt pasujący do istniejącego miejsca (≤150 m, podobna nazwa) nie jest
    dodawany ponownie – co najwyżej uzupełniamy puste pola.
"""

import csv
import difflib
import html
import json
import math
import re
import ssl
import sys
import time
import unicodedata
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "supabase/seed/raw/obiekty_wlasne.csv"
CACHE = ROOT / ".osm_cache"
GEO_CACHE = CACHE / "manual_geocode.json"
WEB_CACHE = CACHE / "manual_web.json"
DB_SNAPSHOT = CACHE / "db_places.tsv"
OUT_SQL = ROOT / "supabase/seed/manual_places.sql"
OUT_REPORT = ROOT / "supabase/seed/raw/manual_places_report.csv"
UA = "Activehood-importer/1.0 (+https://activehood.pl)"


# ------------------------------------------------------------------ wspólne

def load_rows():
    with SRC.open(encoding="utf-8") as f:
        rows = list(csv.DictReader(f, delimiter=";"))
    out, seen = [], set()
    for r in rows:
        name = (r.get("Nazwa") or "").strip()
        if not name:
            continue
        key = (norm(name), norm(r.get("Adres") or ""))
        if key in seen:  # duplikaty wewnątrz pliku
            continue
        seen.add(key)
        web = (r.get("Strona WWW") or "").strip()
        if not web.startswith("http"):
            web = ""
        out.append({
            "key": f"{name}|{r.get('Adres', '').strip()}",
            "category": (r.get("Kategoria") or "").strip(),
            "name": name,
            "city": (r.get("Miejscowość") or "").strip(),
            "address_raw": (r.get("Adres") or "").strip(),
            "phone": (r.get("Telefon") or "").strip(),
            "website": web,
        })
    return out


def norm(s):
    s = unicodedata.normalize("NFKD", s.lower())
    s = "".join(c for c in s if not unicodedata.combining(c)).replace("ł", "l")
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def street_part(address_raw):
    """'ul. Rynek 12, 40-003 Katowice' -> ('Rynek 12', '40-003')"""
    first = address_raw.split(",")[0].strip()
    first = re.sub(r"^(ul\.|al\.|pl\.|os\.|aleja|plac)\s+", "", first, flags=re.I)
    m = re.search(r"\b\d{2}-\d{3}\b", address_raw)
    return first, (m.group(0) if m else None)


def street_name_only(street):
    return re.sub(r"\s+\d+[a-zA-Z]?([/-]\S*)?.*$", "", street).strip()


def digits(s):
    return re.sub(r"\D", "", s)


def load_json(p):
    return json.loads(p.read_text()) if p.exists() else {}


def save_json(p, d):
    p.write_text(json.dumps(d, ensure_ascii=False, indent=1))


# ------------------------------------------------------------------ 1. geocode

def nominatim(params):
    q = urllib.parse.urlencode({**params, "format": "jsonv2", "countrycodes": "pl",
                                "limit": 1, "addressdetails": 1})
    req = urllib.request.Request(f"https://nominatim.openstreetmap.org/search?{q}",
                                 headers={"User-Agent": UA, "Accept-Language": "pl"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def geocode():
    cache = load_json(GEO_CACHE)
    rows = load_rows()
    todo = [r for r in rows if r["key"] not in cache]
    print(f"Do geokodowania: {len(todo)} z {len(rows)}")
    for i, r in enumerate(todo, 1):
        street, postcode = street_part(r["address_raw"])
        attempts = [{"street": street, "city": r["city"], **({"postalcode": postcode} if postcode else {})},
                    {"street": street, "city": r["city"]},
                    {"q": f"{r['name']}, {r['city']}"}]
        result = None
        for params in attempts:
            try:
                res = nominatim(params)
            except Exception as e:  # noqa: BLE001
                print(f"  błąd: {e}; czekam 10 s"); time.sleep(10); res = []
            time.sleep(1.1)  # polityka Nominatim: max 1 zapytanie/s
            if res:
                h = res[0]
                result = {"lat": float(h["lat"]), "lng": float(h["lon"]),
                          "type": h.get("addresstype") or h.get("type"),
                          "has_house": "house_number" in (h.get("address") or {}),
                          "by": "name" if "q" in params else "address",
                          "display": h.get("display_name")}
                break
        cache[r["key"]] = result
        if i % 25 == 0:
            save_json(GEO_CACHE, cache)
            print(f"  {i}/{len(todo)}")
    save_json(GEO_CACHE, cache)
    found = sum(1 for r in rows if cache.get(r["key"]))
    print(f"Gotowe: znaleziono {found}/{len(rows)}")


# ------------------------------------------------------------------ 2. web

CTX = ssl.create_default_context()


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (compatible; " + UA + ")"})
    try:
        with urllib.request.urlopen(req, timeout=15, context=CTX) as r:
            body = r.read(1_500_000).decode("utf-8", "replace")
            return {"ok": True, "status": r.status, "final": r.geturl(), "body": body}
    except urllib.error.HTTPError as e:
        return {"ok": False, "status": e.code, "error": f"HTTP {e.code}"}
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "status": None, "error": type(e).__name__ + ": " + str(e)[:120]}


def web():
    cache = load_json(WEB_CACHE)
    rows = load_rows()
    urls = sorted({r["website"] for r in rows if r["website"]} - set(cache))
    print(f"Strony do sprawdzenia: {len(urls)}")

    def work(u):
        res = fetch(u)
        if res.get("ok"):
            text = html.unescape(re.sub(r"<[^>]+>", " ", res.pop("body")))
            res["text_norm"] = norm(text)[:400_000]
            res["digits"] = digits(text)[:400_000]
        return u, res

    with ThreadPoolExecutor(max_workers=12) as ex:
        for i, (u, res) in enumerate(ex.map(work, urls), 1):
            cache[u] = res
            if i % 25 == 0:
                save_json(WEB_CACHE, cache)
                print(f"  {i}/{len(urls)}")
    save_json(WEB_CACHE, cache)
    ok = sum(1 for u in {r['website'] for r in rows if r['website']} if cache.get(u, {}).get("ok"))
    print(f"Gotowe: działających stron {ok}")


# ------------------------------------------------------------------ 2b. deep

DEEP_CACHE = CACHE / "manual_deep.json"
PAGE_HINTS = ("klub", "silown", "lokaliz", "studio", "obiekt", "kontakt", "contact", "adres",
              "gdzie", "club", "gym", "locat", "oddzia", "placow", "basen", "plywal", "lodowis",
              "kort", "salon", "sala", "filia", "punkt")


def domain_of(url):
    return urllib.parse.urlparse(url).netloc.lower().removeprefix("www.")


def slug(s):
    return norm(s).replace(" ", "-")


def sitemap_urls(domain, limit_maps=25):
    seen_maps, pages = set(), set()
    queue = []
    rb = fetch(f"https://{domain}/robots.txt")
    if rb.get("ok"):
        queue += re.findall(r"(?im)^sitemap:\s*(\S+)", rb["body"])
    queue += [f"https://{domain}/sitemap.xml", f"https://{domain}/sitemap_index.xml",
              f"https://{domain}/wp-sitemap.xml"]
    while queue and len(seen_maps) < limit_maps:
        u = queue.pop(0)
        if u in seen_maps:
            continue
        seen_maps.add(u)
        res = fetch(u)
        if not res.get("ok"):
            continue
        locs = re.findall(r"<loc>\s*([^<\s]+)\s*</loc>", res["body"])
        for loc in locs:
            loc = html.unescape(loc)
            if loc.endswith(".xml") or ("sitemap" in loc.lower() and loc not in seen_maps):
                queue.append(loc)
            else:
                pages.add(loc)
    return pages


def homepage_links(domain):
    res = fetch(f"https://{domain}/")
    if not res.get("ok"):
        return set()
    base = res["final"]
    out = set()
    for href in re.findall(r'href=["\']([^"\'#]+)', res["body"]):
        u = urllib.parse.urljoin(base, html.unescape(href))
        if domain_of(u) == domain and u.startswith("http"):
            out.add(u.split("?")[0])
    return out


def crawl_domain(domain, rows_here):
    """Zwraca {row_key: {"by": "site", "url": ..., "phone_ok": bool}}"""
    cities = {slug(r["city"]) for r in rows_here}
    cand = sitemap_urls(domain) | homepage_links(domain)
    cand |= {f"https://{domain}/kontakt", f"https://{domain}/kontakt/", f"https://{domain}/contact"}
    cand |= {r["website"] for r in rows_here if r["website"]}

    def score(u):
        path = norm(urllib.parse.urlparse(u).path).replace(" ", "-")
        return (any(c and c in path for c in cities) * 2 + any(h in path for h in PAGE_HINTS))

    ranked = sorted((u for u in cand if score(u) > 0), key=score, reverse=True)[:250]
    found = {}

    def check(u):
        res = fetch(u)
        if not res.get("ok"):
            return u, None, None
        text = html.unescape(re.sub(r"<[^>]+>", " ", res["body"]))
        return u, norm(text), digits(text)

    with ThreadPoolExecutor(max_workers=8) as ex:
        for u, tn, dg in ex.map(check, ranked):
            if not tn:
                continue
            path = norm(urllib.parse.urlparse(u).path)
            for r in rows_here:
                street, _ = street_part(r["address_raw"])
                sname = norm(street_name_only(street))
                num = re.search(r"\d+[a-z]?", norm(street))
                if len(sname) < 4 or sname not in tn:
                    continue
                # ulica + numer domu (jeśli jest) + miasto na stronie lub w adresie URL
                if num and not re.search(rf"\b{re.escape(sname)}\s+{re.escape(num.group(0))}\b", tn):
                    continue
                if norm(r["city"]) not in tn and slug(r["city"]) not in path.replace(" ", "-"):
                    continue
                ph = digits(r["phone"])[-9:]
                hit = {"by": "site", "url": u, "phone_ok": len(ph) == 9 and ph in dg}
                prev = found.get(r["key"])
                # wolimy podstronę z nazwą miasta w adresie, potem z telefonem
                rank = (slug(r["city"]) in path.replace(" ", "-"), hit["phone_ok"])
                if not prev or rank > prev[0]:
                    found[r["key"]] = (rank, hit)
    return {k: v[1] for k, v in found.items()}


def osm_lookup(r, g):
    queries = [f"{r['name']}, {r['city']}"]
    short = re.sub(r"\(.*?\)", "", r["name"]).strip()
    if short != r["name"]:
        queries.append(f"{short}, {r['city']}")
    for q in queries:
        try:
            res = nominatim({"q": q, "extratags": 1})
        except Exception:  # noqa: BLE001
            res = []
        time.sleep(1.1)
        if not res:
            continue
        h = res[0]
        if h.get("category") in ("highway", "place", "boundary", "landuse", "railway"):
            continue
        lat, lng = float(h["lat"]), float(h["lon"])
        if g and haversine(g["lat"], g["lng"], lat, lng) > 200:
            continue
        addr = h.get("address") or {}
        city_ok = norm(r["city"]) in norm(" ".join(str(v) for v in addr.values()))
        if not g and not city_ok:
            continue
        ex = h.get("extratags") or {}
        return {"by": "osm", "lat": lat, "lng": lng,
                "osm_id": f"{h['osm_type']}/{h['osm_id']}",
                "osm_name": h.get("name"), "category": f"{h.get('category')}={h.get('type')}",
                "phone": ex.get("phone") or ex.get("contact:phone"),
                "website": ex.get("website") or ex.get("contact:website")}
    return None


def deep():
    rows, geo, webc = load_rows(), load_json(GEO_CACHE), load_json(WEB_CACHE)
    cache = load_json(DEEP_CACHE)
    pending = []
    for r in rows:
        w = webc.get(r["website"]) if r["website"] else None
        street, _ = street_part(r["address_raw"])
        sname = norm(street_name_only(street))
        ph = digits(r["phone"])[-9:]
        ok = bool(w and w.get("ok")) and ((len(ph) == 9 and ph in w.get("digits", ""))
                                          or (len(sname) > 3 and sname in w.get("text_norm", "")))
        g = geo.get(r["key"])
        if not ok or not (g and g["has_house"]):
            pending.append(r)
    print(f"Do pogłębionej weryfikacji: {len(pending)}")

    # A) strony domen
    by_domain = {}
    for r in pending:
        if r["website"]:
            by_domain.setdefault(domain_of(r["website"]), []).append(r)
    done_domains = set(cache.get("_domains", []))
    for i, (dom, rs) in enumerate(sorted(by_domain.items(), key=lambda kv: -len(kv[1])), 1):
        if dom in done_domains:
            continue
        hits = crawl_domain(dom, rs)
        for k, v in hits.items():
            cache[k] = v
        done_domains.add(dom)
        cache["_domains"] = sorted(done_domains)
        save_json(DEEP_CACHE, cache)
        print(f"  [{i}/{len(by_domain)}] {dom}: potwierdzono {len(hits)}/{len(rs)}")

    # B) OpenStreetMap po nazwie
    rest = [r for r in pending if r["key"] not in cache]
    done_osm = set(cache.get("_osm_checked", []))
    print(f"Szukam w OSM po nazwie: {len([r for r in rest if r['key'] not in done_osm])}")
    for i, r in enumerate(rest, 1):
        if r["key"] in done_osm:
            continue
        hit = osm_lookup(r, geo.get(r["key"]))
        if hit:
            cache[r["key"]] = hit
        done_osm.add(r["key"])
        if i % 20 == 0:
            cache["_osm_checked"] = sorted(done_osm)
            save_json(DEEP_CACHE, cache)
    cache["_osm_checked"] = sorted(done_osm)
    save_json(DEEP_CACHE, cache)
    print(f"Gotowe. Potwierdzono łącznie: {sum(1 for k in cache if not k.startswith('_'))}")


# ------------------------------------------------------------------ 3. report

def haversine(a_lat, a_lng, b_lat, b_lng):
    r = 6371000
    p1, p2 = math.radians(a_lat), math.radians(b_lat)
    dp, dl = p2 - p1, math.radians(b_lng - a_lng)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


GENERIC = {norm(w)[:6] for w in """
    studio szkoła szkola tańca tanca dance club klub fitness gym siłownia silownia
    centrum center sport sportu sportowe sportowy basen pływalnia plywalnia kryta
    aquapark park wodny korty kort tenisowe tenis tennis squash padel joga jogi yoga
    pilates reformer ems trening treningu lodowisko wspinaczkowe wspinaczkowa ściana
    sciana ścianka boulder bouldering arena hala fight team mma bjj boks boxing
    akademia pole the and mosir osir posir gos ucsir galeria ul al
    kąpielisko kapielisko ks cos ii iii ośrodek osrodek obiekt kompleks tor city miejski miejskie
""".split()}


def tokens(s, city=""):
    city_t = {t[:6] for t in norm(city).split()}
    return {t[:6] for t in norm(s).split() if len(t) > 1} - city_t


def tokens_ordered(s, city=""):
    city_t = {t[:6] for t in norm(city).split()}
    return [t[:6] for t in norm(s).split() if len(t) > 1 and t[:6] not in city_t]


def name_sim(a, b, city=""):
    """(specyficzne, pełne): podobieństwo bez ogólnych słów i nazw miast / ze wszystkimi."""
    ta, tb = tokens(a, city), tokens(b, city)
    full = len(ta & tb) / max(1, min(len(ta), len(tb)))
    sa, sb = ta - GENERIC, tb - GENERIC
    spec = len(sa & sb) / max(1, min(len(sa), len(sb))) if sa and sb else 0.0
    # wspólne słowo musi być "marką": pierwszym charakterystycznym słowem którejś nazwy
    # (inaczej np. "Well Fitness Wilanów" pasowałoby do "Stajnia Wilanów")
    first = {next((t for t in tokens_ordered(x, city) if t not in GENERIC), None) for x in (a, b)}
    if not (sa & sb & first):
        spec = 0.0
    ratio = difflib.SequenceMatcher(None, norm(a), norm(b)).ratio()
    # wspólne tylko ogólne słowa (np. "fitness") nie wystarczą
    return spec, ratio if not spec else max(full, ratio)


def load_db():
    out = []
    with DB_SNAPSHOT.open(encoding="utf-8") as f:
        for line in f:
            p = line.rstrip("\n").split("\t")
            out.append({"id": p[0], "name": p[1], "address": p[2], "city": p[3],
                        "lat": float(p[4]), "lng": float(p[5]), "phone": p[6],
                        "website": p[7], "osm_id": p[8], "status": p[9]})
    return out


def sql(v):
    return "null" if v in (None, "") else "'" + str(v).replace("'", "''") + "'"


def report():
    rows, geo, webc, db = load_rows(), load_json(GEO_CACHE), load_json(WEB_CACHE), load_db()
    deepc = load_json(DEEP_CACHE)
    db_osm = {p["osm_id"]: p for p in db if p["osm_id"]}
    results, inserts, updates = [], [], []
    taken = set()
    for r in rows:
        g = geo.get(r["key"])
        w = webc.get(r["website"]) if r["website"] else None
        street, _ = street_part(r["address_raw"])
        sname = norm(street_name_only(street))
        web_ok = bool(w and w.get("ok"))
        ph = digits(r["phone"])[-9:]
        phone_on_site = web_ok and len(ph) == 9 and ph in w.get("digits", "")
        street_on_site = web_ok and len(sname) > 3 and sname in w.get("text_norm", "")
        name_on_site = web_ok and any(t in w.get("text_norm", "") for t in norm(r["name"]).split()
                                      if len(t) > 4)

        dp = deepc.get(r["key"])
        via = "strona" if (phone_on_site or street_on_site) else ""
        osm_hit = None
        if dp and dp["by"] == "site" and not (phone_on_site or street_on_site):
            street_on_site, via = True, "podstrona: " + dp["url"]
            phone_on_site = phone_on_site or dp["phone_ok"]
        elif dp and dp["by"] == "osm" and not (phone_on_site or street_on_site):
            osm_hit, via = dp, f"OSM: {dp['osm_name']} ({dp['category']})"
            if not (g and g["has_house"] and g["by"] == "address"):
                g = {"lat": dp["lat"], "lng": dp["lng"], "has_house": True, "by": "address",
                     "type": "osm"}

        match = None
        if osm_hit and osm_hit["osm_id"] in db_osm:
            p0 = db_osm[osm_hit["osm_id"]]
            match = (1.0, p0, haversine(g["lat"], g["lng"], p0["lat"], p0["lng"]), 1.0)
        if g and not match:
            best = None
            for p in db:
                d = haversine(g["lat"], g["lng"], p["lat"], p["lng"])
                if d > 250:
                    continue
                spec, full = name_sim(r["name"], p["name"], r["city"])
                s = max(spec, full)
                # ta sama marka/nazwa w pobliżu, albo prawie ten sam punkt i podobna nazwa
                if (d <= 150 and spec >= 0.5) or (d <= 25 and full >= 0.5):
                    score = s - d / 1000
                    if not best or score > best[0]:
                        best = (score, p, d, s)
            if best:
                match = best

        verified_phone = r["phone"] if phone_on_site else None
        verified_web = r["website"] if (phone_on_site or street_on_site) else None
        if dp and dp["by"] == "site" and via.startswith("podstrona"):
            verified_web = dp["url"]
        if osm_hit:
            verified_phone, verified_web = osm_hit.get("phone"), osm_hit.get("website")
        house_level = bool(g and g["has_house"] and g["by"] == "address")

        if match:
            p, d = match[1], match[2]
            status = "istnieje w bazie"
            if p["status"] == "unclaimed" and p["id"] not in taken and (
                    (verified_phone and not p["phone"]) or (verified_web and not p["website"])):
                updates.append((p["id"], verified_phone, verified_web))
                status = "istnieje – uzupełniono kontakt"
            taken.add(p["id"])
            note = f"{p['name']} ({round(d)} m)"
        elif not g:
            status, note = "do weryfikacji", "nie znaleziono adresu"
        elif not house_level:
            status, note = "do weryfikacji", f"adres przybliżony ({g['type']})"
        elif not (phone_on_site or street_on_site or osm_hit):
            why = ("brak strony" if not r["website"] else
                   "strona nie działa" if not web_ok else
                   "strona nie potwierdza adresu ani telefonu")
            status, note = "do weryfikacji", why
        elif norm(r["name"]).startswith("fitness platinium"):
            status, note = "do weryfikacji", "nieaktualna marka (kluby Fitness Platinium działają dziś jako Zdrofit)"
        elif dup := next((x for x in inserts
                          if norm(street_part(x[0]["address_raw"])[0]) == norm(street)
                          and norm(x[0]["city"]) == norm(r["city"])
                          and name_sim(x[0]["name"], r["name"], r["city"])[0] > 0), None):
            status, note = "duplikat w pliku", f"ten sam obiekt co: {dup[0]['name']}"
        else:
            status = "nowy – import"
            note = via or ("telefon na stronie" if phone_on_site else "ulica na stronie")
            addr = street
            inserts.append((r, g, addr, verified_phone, verified_web,
                            osm_hit["osm_id"] if osm_hit else None))

        results.append({
            "status": status, "kategoria": r["category"], "nazwa": r["name"],
            "miasto": r["city"], "adres": r["address_raw"], "uwagi": note,
            "telefon_z_pliku": r["phone"], "telefon_potwierdzony": "tak" if phone_on_site else "nie",
            "www_z_pliku": r["website"],
            "www_dziala": "tak" if web_ok else ("—" if not r["website"] else "nie"),
            "nazwa_na_stronie": "tak" if name_on_site else "nie",
        })

    # raport
    OUT_REPORT.parent.mkdir(parents=True, exist_ok=True)
    with OUT_REPORT.open("w", encoding="utf-8", newline="") as f:
        wr = csv.DictWriter(f, fieldnames=list(results[0]), delimiter=";")
        wr.writeheader()
        wr.writerows(sorted(results, key=lambda x: (x["status"], x["miasto"], x["nazwa"])))

    # SQL
    lines = [
        "-- Import własnej listy obiektów (zweryfikowane automatycznie, tool/verify_manual_places.py)",
        "-- Telefon/www tylko gdy potwierdzone na działającej stronie obiektu.",
        "-- Wymaga migracji 20261126_places_source.sql.",
        "",
    ]
    if inserts:
        lines.append("insert into public.places (name, address, city, location, phone, website, source, osm_id)\nvalues")
        vals = [f"  ({sql(r['name'])}, {sql(a)}, {sql(r['city'])}, "
                f"st_setsrid(st_makepoint({g['lng']}, {g['lat']}), 4326), "
                f"{sql(ph)}, {sql(wb)}, 'manual', {sql(oid)})" for r, g, a, ph, wb, oid in inserts]
        lines.append(",\n".join(vals) + "\non conflict (osm_id) do nothing;")
        lines.append("")
    for pid, ph, wb in updates:
        lines.append(f"update public.places set phone = coalesce(phone, {sql(ph)}), "
                     f"website = coalesce(website, {sql(wb)}) "
                     f"where id = '{pid}' and status = 'unclaimed';")
    OUT_SQL.write_text("\n".join(lines) + "\n", encoding="utf-8")

    counts = {}
    for x in results:
        counts[x["status"]] = counts.get(x["status"], 0) + 1
    print("Podsumowanie:")
    for k, v in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"  {k:32} {v}")
    print(f"Zapisano: {OUT_SQL.relative_to(ROOT)} i {OUT_REPORT.relative_to(ROOT)}")


if __name__ == "__main__":
    {"geocode": geocode, "web": web, "deep": deep, "report": report}[sys.argv[1]]()
