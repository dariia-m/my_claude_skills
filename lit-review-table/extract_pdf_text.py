# -*- coding: utf-8 -*-
"""extract_pdf_text.py - read a downloaded PDF to fill custom/detail columns from FULL TEXT
(e.g. exact model, number of runs/iterations, prompt strategy, sample size). Needs pypdf
(`python -m pip install pypdf`).

Usage:
  python extract_pdf_text.py paper.pdf                 # dump text (first 14 pages)
  python extract_pdf_text.py paper.pdf --methods       # only sentences with method/model details
  python extract_pdf_text.py papers/ --methods         # every PDF in a folder

The --methods filter surfaces lines mentioning models (GPT-4o, Llama, Mistral, BERT,
embeddings...), temperature, iterations/runs/trials, zero/few-shot, prompts, and sample sizes -
the things abstracts usually omit. Read those, then write the verified values into your records
and rebuild with build_xlsx.py.
"""
import sys, re, os, glob, argparse, warnings
warnings.filterwarnings("ignore")
try:
    from pypdf import PdfReader
except ImportError:
    sys.exit("pypdf not installed -> run: python -m pip install pypdf")
def w(s): sys.stdout.buffer.write((s + "\n").encode("utf-8", "replace"))

MODEL = (r"GPT-?4o|GPT-?4V|GPT-?4|GPT-?3\.5|GPT-?5|ChatGPT|o1|o3|Llama-?\d?|Mistral|Mixtral|Claude|"
         r"Gemini|Gemma|Qwen\d?|DeepSeek|BERT|RoBERTa|MTEB|text-embedding|e5|all-MiniLM|sentence-?transformer|"
         r"random forest|gradient boost|LASSO|logistic|neural")
METH = re.compile(r"(temperature|iterat|repeated|self-consist|zero-shot|few-shot|one-shot|chain[- ]of[- ]thought|"
                  r"\bCoT\b|system prompt|prompt template|few-shot example|calibration example|"
                  r"\bn\s*=\s*[\d,]+|\bN\s*=\s*[\d,]+|\d+\s*(?:times|runs|iterations|trials|resumes|candidates|"
                  r"participants|essays|prompts|models|examples)|we (?:prompt|use|ran|run|sample|train|score|"
                  r"instruct|evaluate)|" + MODEL + r")", re.I)

def methods(path, pages=14):
    rd = PdfReader(path)
    txt = re.sub(r"\s+", " ", " ".join((p.extract_text() or "") for p in rd.pages[:pages]))
    seen, out = set(), []
    for s in re.split(r"(?<=[.!?])\s+", txt):
        s = s.strip()
        if 25 < len(s) < 300 and METH.search(s):
            k = s[:50].lower()
            if k not in seen:
                seen.add(k); out.append(s)
    return out

def full(path, pages=14):
    rd = PdfReader(path)
    return "\n".join((p.extract_text() or "") for p in rd.pages[:pages])

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("path", help="a .pdf file or a folder of PDFs")
    ap.add_argument("--methods", action="store_true", help="print only method/model sentences")
    ap.add_argument("--pages", type=int, default=14)
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(a.path, "*.pdf"))) if os.path.isdir(a.path) else [a.path]
    for f in files:
        w("\n#### " + os.path.basename(f) + " ####")
        try:
            if a.methods:
                for s in methods(f, a.pages)[:16]: w("  - " + s)
            else:
                w(full(f, a.pages))
        except Exception as e:
            w("  ! error: " + str(e)[:120])
