# -*- coding: utf-8 -*-
"""openalex_search.py - find economics papers on a topic via the OpenAlex API (free, no key)
and emit structured JSON records the table/download helpers consume.

Usage:
  python openalex_search.py "minimum wage employment" -n 40 -o candidates.json
  python openalex_search.py "AI hiring discrimination" -n 30 --from-year 2015 --min-cites 20
  python openalex_search.py "<topic>" --no-econ-filter        # drop the economics-concept filter

Each record has: authors[], year, title, journal, source_type, paper_type, doi, link,
keywords[], abstract, citation_count, is_oa, oa_status, type, volume, issue, pages,
pdf_candidates[] (ordered URLs to try for download). Review/curate before building the table.
"""
import sys, json, argparse, time, urllib.request, urllib.parse

ECON_CONCEPT = "C162324750"                     # OpenAlex "Economics" concept
BASE = "https://api.openalex.org/works"
MAILTO = "dashamyh@gmail.com"                    # polite pool; replace if you like

def reconstruct_abstract(inv):
    if not inv:
        return ""
    pos = {}
    for word, idxs in inv.items():
        for i in idxs:
            pos[i] = word
    return " ".join(pos[i] for i in sorted(pos))

def get_json(url, tries=4):
    for k in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "lit-review-table/1.0"})
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception as e:
            if k == tries - 1:
                raise
            time.sleep(1.5 * (k + 1))

def parse_work(w):
    authors = [a["author"]["display_name"] for a in w.get("authorships", []) if a.get("author")]
    loc = w.get("primary_location") or {}
    src = loc.get("source") or {}
    journal = src.get("display_name")
    src_type = src.get("type")                  # journal / repository / conference / ...
    wtype = w.get("type")
    if wtype == "article" and src_type == "journal":
        paper_type = "journal article"
    elif wtype in ("preprint",) or src_type in ("repository",):
        paper_type = "working paper / preprint"
    else:
        paper_type = wtype or "other"
    # pdf candidates: best OA first, then every location that exposes a pdf
    pdfs = []
    best = w.get("best_oa_location") or {}
    if best.get("pdf_url"):
        pdfs.append(best["pdf_url"])
    for l in (w.get("locations") or []):
        u = l.get("pdf_url")
        if u and u not in pdfs:
            pdfs.append(u)
    kws = [k["display_name"] for k in (w.get("keywords") or [])]
    if not kws:
        kws = [c["display_name"] for c in (w.get("concepts") or [])[:6]]
    bib = w.get("biblio") or {}
    pages = "-".join([p for p in (bib.get("first_page"), bib.get("last_page")) if p]) or None
    oa = w.get("open_access") or {}
    return {
        "authors": authors,
        "year": w.get("publication_year"),
        "title": w.get("title"),
        "journal": journal,
        "source_type": src_type,
        "paper_type": paper_type,
        "doi": (w.get("doi") or "").replace("https://doi.org/", "") or None,
        "link": w.get("doi") or loc.get("landing_page_url"),
        "keywords": kws,
        "abstract": reconstruct_abstract(w.get("abstract_inverted_index")),
        "citation_count": w.get("cited_by_count"),
        "is_oa": oa.get("is_oa"),
        "oa_status": oa.get("oa_status"),
        "type": wtype,
        "volume": bib.get("volume"),
        "issue": bib.get("issue"),
        "pages": pages,
        "pdf_candidates": pdfs,
    }

def by_title(title, n=3):
    """Fetch a specific known paper by title (filter=title.search is far more precise than
    the relevance `search` param). Returns the top matches as parsed records."""
    f = urllib.parse.quote(title)
    d = get_json(f"{BASE}?filter=title.search:{f}&per-page={n}&mailto={MAILTO}")
    return [parse_work(w) for w in d.get("results", [])]

def search(query, n, econ_only, from_year, to_year, min_cites):
    filters = ["type:article|preprint|report"]
    if econ_only:
        filters.append(f"concepts.id:{ECON_CONCEPT}")
    if from_year:
        filters.append(f"from_publication_date:{from_year}-01-01")
    if to_year:
        filters.append(f"to_publication_date:{to_year}-12-31")
    if min_cites:
        filters.append(f"cited_by_count:>{int(min_cites) - 1}")
    out, cursor = [], "*"
    while len(out) < n and cursor:
        params = {"search": query, "filter": ",".join(filters),
                  "per-page": min(200, n - len(out)), "cursor": cursor,
                  "sort": "relevance_score:desc", "mailto": MAILTO}
        d = get_json(BASE + "?" + urllib.parse.urlencode(params))
        for w in d.get("results", []):
            out.append(parse_work(w))
        cursor = (d.get("meta") or {}).get("next_cursor")
        if not d.get("results"):
            break
        time.sleep(0.3)
    return out[:n]

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("query")
    ap.add_argument("-n", type=int, default=30, help="max papers (default 30)")
    ap.add_argument("-o", "--out", default=None, help="output JSON file (default: stdout)")
    ap.add_argument("--from-year", type=int, default=None)
    ap.add_argument("--to-year", type=int, default=None)
    ap.add_argument("--min-cites", type=int, default=None)
    ap.add_argument("--no-econ-filter", action="store_true",
                    help="drop the economics-concept filter (broader / adjacent fields)")
    ap.add_argument("--by-title", action="store_true",
                    help="treat the query as an exact paper title and fetch it (filter=title.search)")
    a = ap.parse_args()
    recs = by_title(a.query, a.n) if a.by_title else \
        search(a.query, a.n, not a.no_econ_filter, a.from_year, a.to_year, a.min_cites)
    txt = json.dumps(recs, ensure_ascii=False, indent=2)
    if a.out:
        open(a.out, "w", encoding="utf-8").write(txt)
        sys.stderr.write(f"Wrote {len(recs)} records to {a.out}\n")
    else:
        sys.stdout.buffer.write(txt.encode("utf-8"))
