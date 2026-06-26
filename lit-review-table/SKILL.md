---
name: lit-review-table
description: >
  Build an Excel literature table on a topic. Searches economics journals and working
  papers (via OpenAlex) and compiles a formatted .xlsx with columns: authors, year, title,
  journal, full citation (AEA), keywords, abstract, citation count, paper type, OA status,
  link - plus any custom columns the user asks for in that run. Optionally downloads the
  papers' PDFs to a folder (open-access/working-paper version, else marks "not available").
  Use when the user asks to make a literature table or spreadsheet of papers, do a lit
  search into Excel, build a bibliography table, or collect/download papers on a topic.
  Complements (does not replace) lit-review-assistant, which is for synthesis prose.
version: 1.0.0
---

# Literature Review -> Excel Table

Turns a topic into a curated, formatted Excel table of papers, and optionally downloads the
PDFs. Three helper scripts in this skill dir do the mechanical work; **you** drive the search
and curation in between. Papers default to **economics** journals + economics-adjacent working
papers unless the user says otherwise.

**Interpreter:** these scripts need Python with `openpyxl` (stdlib otherwise). On this machine
that is `C:/Users/Admin/anaconda3/python.exe` (the default `python` is a broken Store stub).
Examples below use it directly. Write `candidates.json` / `papers.json` to a scratch location
and put the final `.xlsx` + any `papers/` folder in the user's working directory.

## Workflow

1. **Scope the run.** Confirm: topic/question; any field scope (default economics + adjacent
   working papers); year range; roughly how many papers; and **any custom columns** for this
   run (e.g. "method", "identification strategy", "relevance to my project"). Ask whether they
   want the **PDFs downloaded** (default: no).

2. **Search (OpenAlex backbone).** Run the search helper, then add to it with your own
   judgement + `WebSearch` for anything it missed (Google Scholar has no API; OpenAlex +
   your knowledge is the reliable substitute). Pull more than you need, then cut.
   ```bash
   PY="C:/Users/Admin/anaconda3/python.exe"
   "$PY" .claude/skills/lit-review-table/openalex_search.py "<topic>" -n 40 -o candidates.json
   # options: --from-year 2010  --to-year 2024  --min-cites 20  --no-econ-filter
   ```
   Each record has authors, year, title, journal, paper_type, doi, link, keywords, abstract,
   citation_count, is_oa/oa_status, and `pdf_candidates` (used by the downloader).

3. **Curate** - this is the part only you can do. Read `candidates.json` and:
   - drop off-topic hits, duplicates, and non-economics noise (keep economics-adjacent working
     papers if relevant);
   - add the papers OpenAlex missed (from `WebSearch` / your knowledge), as records with the
     same fields - fill what you can, leave unknowns blank;
   - add the run's **custom columns** by writing an extra key onto every record (e.g.
     `"identification": "DiD"`); any non-standard key becomes its own column automatically;
   - you may overwrite `full_citation` with a hand-checked AEA string; otherwise the builder
     constructs one from the fields. Save the curated list as `papers.json`.

4. **Build the table.**
   ```bash
   "$PY" .claude/skills/lit-review-table/build_xlsx.py papers.json -o literature_<topic>.xlsx
   ```
   Columns, in order: authors, year, title, journal, full_citation, keywords, abstract,
   citation_count, paper_type, oa_status, link, then any custom columns. Header is frozen +
   auto-filtered; `link` cells are clickable.

5. **(Optional) Download PDFs** - only if the user asked.
   ```bash
   "$PY" .claude/skills/lit-review-table/download_papers.py papers.json --dir papers_<topic> --email <user-email>
   ```
   Tries each paper's open-access / working-paper URLs in turn; writes the PDFs plus a
   `download_manifest.json` recording, per paper, `downloaded` (+ file) or `not available`.

6. **Report** to the user: the xlsx path, paper count, field/year scope, and (if downloaded)
   how many PDFs landed vs were unavailable.

## Verified commands

All three were run on this machine while authoring the skill:
- `openalex_search.py "AI in hiring and recruitment" -n 8 --min-cites 30 -o cand.json` -> 8 full records (authors, journal, abstract reconstructed, OA pdf links).
- `build_xlsx.py cand.json -o test.xlsx` -> 9x12 sheet; AEA citation `Chen, Zhisheng. 2023. "..."`; clickable links; custom column appended.
- `download_papers.py sub.json --dir test_papers` -> arXiv PDF fetched (5.2 MB); publisher-gated URLs correctly marked `not available`.

## Gotchas

- **Publisher PDFs often block bots.** A "gold OA" Nature/Elsevier link can be a 303 redirect
  to a consent page - the downloader detects the non-PDF and marks it `not available` rather
  than saving HTML. Papers that have an arXiv / NBER-open / institutional-repository copy
  download fine (those URLs are in `pdf_candidates`). For the rest, fetch manually or accept
  the gap; the manifest tells you which.
- **Abstracts** come from OpenAlex's inverted index and are reconstructed by the script; a few
  papers (esp. older ones) have none -> blank cell.
- **Economics filter** is OpenAlex concept `C162324750`. It is broad but can miss adjacent
  working papers; use `--no-econ-filter` and curate manually when the topic is cross-field.
- **OpenAlex `keywords`** can be thin/auto-generated; it falls back to top concepts. Tidy them
  during curation if the user cares about keyword quality.
- **Git Bash path mangling:** pass *relative* output filenames (`-o candidates.json`), not
  `/tmp/...`, or MSYS rewrites the path.
- **No API key needed** (OpenAlex + Unpaywall are free; Unpaywall fallback just wants an email).

## Files

- `openalex_search.py` - topic -> candidate records (JSON).
- `build_xlsx.py` - curated records (JSON) -> formatted .xlsx (AEA citations, custom columns).
- `download_papers.py` - optional PDF downloads + manifest.
