# -*- coding: utf-8 -*-
"""search_more.py - search BEYOND OpenAlex for a topic: arXiv (preprints) + Semantic Scholar
(indexes SSRN, NBER, ACL, many preprints OpenAlex misses). Emits records in the same shape as
openalex_search.py so build_xlsx / download_papers consume them directly.

Usage:
  python search_more.py "large language model resume screening" -n 25 -o more.json
  python search_more.py "<topic>" --arxiv-cat cs.CL,econ.GN          # restrict arXiv categories
  python search_more.py "<topic>" --no-s2          # arXiv only (skip Semantic Scholar)

Notes / gotchas:
  - Semantic Scholar rate-limits hard (HTTP 429) without an API key; this retries with backoff
    and still often returns partial - run it a few times or pass fewer queries.
  - For specific econ working-paper series (NBER/IZA/CEPR/SSRN) that none of these APIs index
    well, use the WebSearch tool with the series name in the query, then verify each PDF
    directly (RePEc/IDEAS and EconPapers have no clean API - their search URLs return a homepage).
"""
import sys, json, re, time, argparse, urllib.request, urllib.parse
import xml.etree.ElementTree as ET
def w(s): sys.stderr.write(s + "\n")

def get(url, hdr=None, tries=4):
    for k in range(tries):
        try:
            req = urllib.request.Request(url, headers=hdr or {"User-Agent": "lit-review-table/1.0"})
            with urllib.request.urlopen(req, timeout=45) as r:
                return r.read()
        except Exception as e:
            if k == tries - 1:
                w("  ! " + str(e)[:90]); return None
            time.sleep(2 * (k + 1))

def norm(t): return re.sub(r"[^a-z0-9]", "", (t or "").lower())[:55]

def arxiv(query, n, cats):
    # AND the individual terms (an exact-phrase query on a long string matches almost nothing)
    terms = " AND ".join(f"all:{t}" for t in query.split())
    cat_q = (" AND (" + " OR ".join("cat:" + c for c in cats) + ")") if cats else ""
    url = ("http://export.arxiv.org/api/query?search_query=" +
           urllib.parse.quote(terms + cat_q) + f"&start=0&max_results={n}&sortBy=relevance")
    data = get(url)
    if not data: return []
    ns = {"a": "http://www.w3.org/2005/Atom"}
    out = []
    for e in ET.fromstring(data).findall("a:entry", ns):
        aid = e.find("a:id", ns).text
        out.append({"source": "arXiv", "title": " ".join((e.find("a:title", ns).text or "").split()),
            "authors": [a.find("a:name", ns).text for a in e.findall("a:author", ns)],
            "year": int((e.find("a:published", ns).text or "0")[:4]),
            "journal": "arXiv preprint", "paper_type": "working paper / preprint", "oa_status": "green",
            "abstract": " ".join((e.find("a:summary", ns).text or "").split()),
            "link": aid, "doi": None, "citation_count": None,
            "pdf_candidates": [aid.replace("/abs/", "/pdf/")]})
    return out

def semscholar(query, n):
    url = ("https://api.semanticscholar.org/graph/v1/paper/search?query=" + urllib.parse.quote(query) +
           f"&limit={n}&fields=title,abstract,year,authors,venue,externalIds,citationCount,openAccessPdf,publicationTypes,fieldsOfStudy")
    data = get(url)
    if not data: return []
    try: js = json.loads(data)
    except Exception: return []
    out = []
    for p in js.get("data", []) or []:
        ext = p.get("externalIds") or {}
        oa = (p.get("openAccessPdf") or {}).get("url")
        is_journal = (p.get("publicationTypes") or [""])[0] == "JournalArticle"
        link = ("https://doi.org/" + ext["DOI"]) if ext.get("DOI") else \
               (oa or (("https://arxiv.org/abs/" + ext["ArXiv"]) if ext.get("ArXiv") else None))
        out.append({"source": "S2", "title": p.get("title") or "",
            "authors": [a.get("name") for a in (p.get("authors") or [])], "year": p.get("year"),
            "journal": p.get("venue") or None,
            "paper_type": "journal article" if is_journal else "working paper / preprint",
            "abstract": p.get("abstract") or "", "doi": ext.get("DOI"), "link": link,
            "citation_count": p.get("citationCount"), "fields": p.get("fieldsOfStudy"),
            "pdf_candidates": [oa] if oa else []})
    return out

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("query")
    ap.add_argument("-n", type=int, default=25)
    ap.add_argument("-o", "--out", default=None)
    ap.add_argument("--no-arxiv", action="store_true")
    ap.add_argument("--no-s2", action="store_true")
    ap.add_argument("--arxiv-cat", default=None, help="comma-separated arXiv categories e.g. cs.CL,econ.GN")
    a = ap.parse_args()
    recs, seen = [], set()
    for src in ([] if a.no_arxiv else arxiv(a.query, a.n, a.arxiv_cat.split(",") if a.arxiv_cat else None)) + \
               ([] if a.no_s2 else semscholar(a.query, a.n)):
        if src.get("title") and norm(src["title"]) not in seen:
            seen.add(norm(src["title"])); recs.append(src)
    txt = json.dumps(recs, ensure_ascii=False, indent=2)
    if a.out:
        open(a.out, "w", encoding="utf-8").write(txt); w(f"Wrote {len(recs)} records to {a.out}")
    else:
        sys.stdout.buffer.write(txt.encode("utf-8"))
