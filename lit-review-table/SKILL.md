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
version: 1.1.0
---

# Literature Review -> Excel Table

Turns a topic into a curated, formatted Excel table of papers, and optionally downloads the
PDFs and fills method/detail columns from their full text. Helper scripts in this skill dir do
the mechanical work; **you** drive the search and curation in between. Papers default to
**economics** journals + economics-adjacent working papers unless the user says otherwise.

**Interpreter:** these scripts need Python with `openpyxl` (and `pypdf` for the full-text
extractor - `python -m pip install pypdf` once). On this machine Python is
`C:/Users/Admin/anaconda3/python.exe` (the default `python` is a broken Store stub). Examples
below use it directly. Write `candidates.json` / `papers.json` to a scratch location and put the
final `.xlsx` + any `papers/` folder in the user's working directory.

## Workflow

1. **Scope the run.** Confirm: topic/question; any field scope (default economics + adjacent
   working papers); year range; roughly how many papers; and **any custom columns** for this
   run (e.g. "method", "identification strategy", "relevance to my project"). Ask whether they
   want the **PDFs downloaded** (default: no).

2. **Search.** OpenAlex is the backbone; widen with the other helpers + `WebSearch`, pull more
   than you need, then cut.
   ```bash
   PY="C:/Users/Admin/anaconda3/python.exe"; SK=".claude/skills/lit-review-table"
   "$PY" $SK/openalex_search.py "<topic>" -n 40 -o candidates.json
   #   options: --from-year 2010  --to-year 2024  --min-cites 20  --no-econ-filter
   #   fetch a SPECIFIC known paper precisely:  openalex_search.py "<exact title>" --by-title
   "$PY" $SK/search_more.py "<topic>" -n 25 -o more.json   # arXiv + Semantic Scholar (preprints, SSRN, NBER)
   ```
   Each record has authors, year, title, journal, paper_type, doi, link, keywords, abstract,
   citation_count, oa_status, and `pdf_candidates` (used by the downloader).
   - **Beyond these APIs:** for specific econ working-paper series (IZA, CEPR, SSRN, recent NBER)
     that none index well, use **`WebSearch`** with the series name in the query, then verify
     each hit by fetching its PDF directly. RePEc/IDEAS and EconPapers have **no usable API**
     (their search URLs return a homepage to a fetcher), so don't rely on them programmatically.
     Merge all sources and de-dup by normalized title.

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
   Re-running after adding papers renames files by position - clear the folder first (or prune
   to the manifest) to avoid stale duplicates.

6. **(Optional) Fill detail columns from full text.** Abstracts rarely state the exact model,
   number of runs/iterations, or prompt. After downloading, read the PDFs and write the verified
   values into your records, then rebuild.
   ```bash
   "$PY" $SK/extract_pdf_text.py papers_<topic>/ --methods   # method/model sentences per PDF
   ```
   Update the relevant record keys (e.g. `model`, `n_runs`, `prompt`) and re-run `build_xlsx.py`.

7. **Report** to the user: the xlsx path, paper count, field/year scope, and (if downloaded)
   how many PDFs landed vs were unavailable.

## Verified commands

All run on this machine:
- `openalex_search.py "AI in hiring and recruitment" -n 8 --min-cites 30` -> 8 full records (abstracts reconstructed, OA pdf links).
- `openalex_search.py "Hiring as Exploration" --by-title` -> the exact NBER 2020 paper.
- `search_more.py "GPT resume screening bias" -n 5 --no-s2` -> arXiv records in the OpenAlex shape.
- `build_xlsx.py papers.json -o table.xlsx` -> formatted sheet; AEA citations; clickable links; custom columns; provenance keys (`source`/`fields`) excluded.
- `download_papers.py papers.json --dir papers` -> arXiv/NBER PDFs fetched; publisher-gated URLs marked `not available` in the manifest. (Used at 55-paper scale: 35/55 downloaded.)
- `extract_pdf_text.py papers/x.pdf --methods` -> pulls model/iteration/prompt sentences from full text.

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
- **Semantic Scholar rate-limits hard** (HTTP 429) without a key - `search_more.py` retries with
  backoff but still often returns partial; run it again or split into fewer queries.
- **RePEc / IDEAS / EconPapers have no usable search API** - their search URLs serve a homepage
  to a fetcher. Use `WebSearch` for econ working-paper series instead, then fetch each PDF.
- **`--by-title` (filter=title.search) beats the relevance `search`** for pulling a *specific*
  known paper; the plain search ranks broadly and often misses the exact one.
- **Stale download files:** filenames are numbered by position, so re-running after re-sorting
  the list leaves duplicates. Clear the `papers/` dir (or prune to the manifest) before a re-run.
- **Curated CS/preprint records** carry a `source`/`fields` key for provenance; `build_xlsx.py`
  excludes those from the table automatically (don't promote them to columns).
- **Git Bash path mangling:** pass *relative* output filenames (`-o candidates.json`), not
  `/tmp/...`, or MSYS rewrites the path. Inside `python -c`, build paths with `os.path.join`, not
  raw backslash strings (they break the shell quote).
- **No API key needed** (OpenAlex, arXiv, Semantic Scholar, Unpaywall are free; Unpaywall just
  wants an email).

## Files

- `openalex_search.py` - topic -> candidate records (JSON); `--by-title` for a specific paper.
- `search_more.py` - arXiv + Semantic Scholar search (preprints/SSRN/NBER), same record shape.
- `build_xlsx.py` - curated records (JSON) -> formatted .xlsx (AEA citations, custom columns).
- `download_papers.py` - optional PDF downloads + manifest.
- `extract_pdf_text.py` - read downloaded PDFs (full text / `--methods`) to fill detail columns.
