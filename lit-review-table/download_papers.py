# -*- coding: utf-8 -*-
"""download_papers.py - OPTIONAL. Download PDFs for the curated papers into a folder.
Only run this when the user asks for it in a given run.

Strategy per paper: try each URL in `pdf_candidates` in order (OpenAlex lists the best
open-access version first, then any other location - so the published OA version is tried
before working-paper/repository copies). If none yields a PDF, try Unpaywall by DOI (free,
needs an email). If still nothing, mark the paper "not available" in the manifest.

Usage:
  python download_papers.py papers.json --dir papers_<topic>            # downloads + manifest
  python download_papers.py papers.json --dir papers_<topic> --email you@example.com
"""
import sys, os, re, json, time, argparse, urllib.request, urllib.parse

UA = {"User-Agent": "Mozilla/5.0 (lit-review-table)"}

def slug(r, i):
    a = (r.get("authors") or ["NA"])[0].split()[-1]
    t = re.sub(r"[^A-Za-z0-9]+", "_", (r.get("title") or "paper")).strip("_")[:40]
    return f"{i:02d}_{a}_{r.get('year','')}_{t}.pdf"

def try_pdf(url, path):
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=60) as resp:
            head = resp.read(1024)
            ct = (resp.headers.get("Content-Type") or "").lower()
            if b"%PDF" not in head[:8] and "pdf" not in ct:
                return False
            with open(path, "wb") as f:
                f.write(head)
                while True:
                    chunk = resp.read(65536)
                    if not chunk:
                        break
                    f.write(chunk)
        return os.path.getsize(path) > 4096
    except Exception:
        if os.path.exists(path):
            os.remove(path)
        return False

def unpaywall_pdf(doi, email):
    if not doi or not email:
        return None
    try:
        url = f"https://api.unpaywall.org/v2/{urllib.parse.quote(doi)}?email={urllib.parse.quote(email)}"
        with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40) as r:
            d = json.loads(r.read().decode("utf-8"))
        loc = d.get("best_oa_location") or {}
        return loc.get("url_for_pdf")
    except Exception:
        return None

def run(records, outdir, email):
    os.makedirs(outdir, exist_ok=True)
    manifest = []
    for i, r in enumerate(records, 1):
        fn = slug(r, i); path = os.path.join(outdir, fn)
        status, used = "not available", None
        urls = list(r.get("pdf_candidates") or [])
        up = unpaywall_pdf(r.get("doi"), email)
        if up and up not in urls:
            urls.append(up)
        for u in urls:
            if try_pdf(u, path):
                status, used = "downloaded", u
                break
            time.sleep(0.4)
        manifest.append({"n": i, "title": r.get("title"), "year": r.get("year"),
                         "status": status, "file": fn if status == "downloaded" else None,
                         "source_url": used, "doi": r.get("doi")})
        sys.stderr.write(f"  [{i:02d}] {status:14s} {(r.get('title') or '')[:60]}\n")
    json.dump(manifest, open(os.path.join(outdir, "download_manifest.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    n_ok = sum(m["status"] == "downloaded" for m in manifest)
    sys.stderr.write(f"\nDownloaded {n_ok}/{len(manifest)} PDFs to {outdir} (see download_manifest.json)\n")
    return manifest

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("json_file")
    ap.add_argument("--dir", required=True, help="output folder for PDFs")
    ap.add_argument("--email", default=None, help="email for the Unpaywall fallback (optional)")
    a = ap.parse_args()
    run(json.load(open(a.json_file, encoding="utf-8")), a.dir, a.email)
