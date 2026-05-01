---
title: Resume Match
emoji: 📄
colorFrom: blue
colorTo: indigo
sdk: docker
pinned: false
---

<p align="center">
  <h1 align="center">ResumeMatch</h1>
  <p align="center">
    <strong>AI-powered resume-to-job matching built on Canadian open labour-market data</strong>
  </p>
  <p align="center">
    <a href="#features">Features</a> · <a href="#design-philosophy">Design</a> · <a href="#architecture">Architecture</a> · <a href="#live-demo">Live Demo</a> · <a href="#getting-started">Setup</a>
  </p>
</p>

---

## 🚀 Live Demo

- **Frontend (Web App):** [nlp-resume-matcher-eta.vercel.app](https://nlp-resume-matcher-eta.vercel.app/)
- **Backend (API Docs):** [osele1-nlp-resume-matcher.hf.space/docs](https://osele1-nlp-resume-matcher.hf.space/docs)

---

## Overview

ResumeMatch is a full-stack application that ingests thousands of live Canadian job postings, enriches them with NOC (National Occupational Classification) and OaSIS competency metadata, and uses a multi-signal NLP pipeline to score and rank resumes against those positions.

Users can upload a PDF or DOCX resume and instantly see how well they match any job in the corpus — or rank their resume against the entire database, filtered by province, city, or occupation category.

---

## Features

| Capability | Description |
|---|---|
| **Single JD Analysis** | Paste a resume and a job description to get a detailed section-by-section breakdown — skills, experience, education, and preferred qualifications — with a weighted overall score. |
| **Corpus Ranking** | Rank your resume against the full enriched job database, filtered by province, city, job title keyword, or NOC broad category. |
| **Bulk / Leaderboard** | Upload up to 20 resumes, select up to 50 jobs, and generate a resume × job score matrix with an interactive leaderboard. |
| **Job Search & Browse** | Browse and search the job corpus with paginated results, then hand-pick specific postings for bulk matching. |
| **PDF & DOCX Upload** | Drag-and-drop or click-to-upload PDF and DOCX resumes; text is extracted server-side with `pdfplumber` and `python-docx`. |
| **Rewrite Suggestions** | Word2Vec-powered suggestions for rephrasing missing skills using terminology that better aligns with the job description. |
| **Experience Matching** | Intelligent years-of-experience extraction from JDs matched against estimated tenure from resume date ranges. |

---

## Design Philosophy

The UI design follows a clean, modern aesthetic focusing on clarity and data density for complex job matching scenarios:

- **Minimalist Slate/Blue Layout:** A neutral slate palette accented with vibrant blues, providing high-contrast readability without overwhelming the user.
- **Dynamic Dark/Light Mode:** Full theming support across the entire app built natively via CSS variables and Tailwind CSS.
- **Glassmorphism & Micro-animations:** Soft bordered panels, backdrop blurs, and localized loading spinners built directly in React 19.

---

## Data Sources

The matching engine is powered by authentic Canadian labor market data sourced sequentially using the custom Python `job-pipeline`:

1. **Job Bank (CKAN):** Downloading live, raw CSV and XLSX postings across the country.
2. **NOC (National Occupational Classification):** Applying standard structure and occupation categorization identifiers.
3. **OaSIS:** Using Open Architecture for Skills and Information Systems logic to enrich standard job postings with precise competency metrics.
4. **Resume Corpus:** (Optional) Augmenting Word2Vec training with professional resume datasets to bridge the gap between "recruiter-speak" and "candidate-speak."

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Next.js Frontend                         │
│   Home · Results · Job Search · Leaderboard · About             │
│   React 19 · TypeScript · Tailwind CSS v4                       │
└──────────────────┬───────────────────────────────────────────────┘
                   │  HTTP (JSON)
┌──────────────────▼───────────────────────────────────────────────┐
│                        FastAPI Backend                           │
│   /api/analyze · /api/rank-jobs · /api/bulk-match               │
│   /api/upload-resume · /api/jobs/search · /api/health           │
├─────────────────────────────────────────────────────────────────-┤
│  NLP Pipeline                                                   │
│  ┌────────────┐ ┌──────────────┐ ┌────────────┐ ┌────────────┐ │
│  │  Section   │ │   Entity     │ │  TF-IDF /  │ │  Word2Vec  │ │
│  │  Parser    │ │  Extractor   │ │  Semantic  │ │  Expander  │ │
│  │  (Heuristic)│ │  (Certs+)   │ │ (Corpus)   │ │ (Combined) │ │
│  └────────────┘ └──────────────┘ └────────────┘ └────────────┘ │
└──────────────────┬───────────────────────────────────────────────┘
                   │  SQLite
┌──────────────────▼───────────────────────────────────────────────┐
│                     Job Pipeline (Python)                        │
│   Ingest → Transform → Enrich → Synthesize → Load → Validate   │
│   Data sources: Job Bank (CKAN), NOC structure, OaSIS           │
└──────────────────────────────────────────────────────────────────┘
```

### Scoring Methodology

The matcher produces a **weighted composite score (0–100)** from five dimensions:

| Dimension | Weight | Method |
|---|---|---|
| Skills | 40% | Entity extraction (150+ skills) + keyword overlap + semantic similarity + W2V fallback |
| Experience | 25% | Section-parsed responsibility matching + Years-of-experience validation |
| Education | 15% | Degree-level and field-of-study matching with fuzzy normalization |
| Preferred | 10% | Same pipeline applied to preferred/nice-to-have qualifications |
| Semantic | 10% | Full-document `all-MiniLM-L6-v2` cosine similarity with corpus-fitted TF-IDF |

Each dimension classifies items as **matched**, **partial**, or **missing**, producing per-section scores that roll up into the final weighted result.

### Performance & Optimization

- **Response Caching:** Heavy NLP operations are cached via SHA-256 hashing. Repeated analysis of the same Resume/JD pair (common in leaderboards) is served in O(1) time.
- **Corpus-Fitted TF-IDF:** The vectorizer is pre-fitted on 5,000+ job descriptions at startup, ensuring IDF weights reflect real-world term importance.
- **NLP Load Modeling:** The FastAPI server pre-loads SentenceBERT and Gensim models on startup to prevent cold-start latency. 

---

## Getting Started

### Prerequisites

- **Python 3.10+** (backend & pipeline)
- **Node.js 18+** and **npm** (frontend)

### 1 — Build the Job Database

The data pipeline downloads Canadian open data and produces a SQLite database used by the backend.

```bash
cd job-pipeline
python -m venv venv
# On Windows: venv\Scripts\activate
# On macOS/Linux: source venv/bin/activate
pip install -r requirements.txt
python scripts/run_all.py
```

This creates `job-pipeline/data/jobs.db`. See [`job-pipeline/README.md`](job-pipeline/README.md) for individual step details and configuration options.

### 2 — Start the Backend

```bash
cd backend
python -m venv venv
# On Windows: venv\Scripts\activate
# On macOS/Linux: source venv/bin/activate
pip install -r requirements.txt
python run.py
```

The API server starts at **`http://localhost:8000`**. On first launch it will download NLTK data and the `en_core_web_sm` spaCy model automatically.

> **Optional:** If you ran `python scripts/07_train_word2vec.py` during the pipeline, the backend will also load a domain-specific Word2Vec model for improved skill-expansion and rewrite suggestions.

### 3 — Start the Frontend

```bash
# From the project root
npm install
npm run dev
```

Open **`http://localhost:3000`** in your browser.

---


---

## Customization

- **Adjust Matching Weights:** Open `backend/app/nlp/matcher.py` to change the hardcoded weighting scale (e.g. `skills: 0.40`, `education: 0.15`).
- **Scrape Limits:** By default, the Python pipeline grabs the two most recent Job Bank resources. Override `JOB_BANK_RESOURCE_LIMIT` in the pipeline config if you want to ingest older datasets.
- **Color Modification:** Open `src/app/globals.css` and use the CSS custom properties block to entirely transform the UI color scheme in under 30 seconds.

---

## API Reference

All endpoints are prefixed with `/api`. The backend serves interactive docs at [`http://localhost:8000/docs`](http://localhost:8000/docs).

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/health` | Health check |
| `POST` | `/api/upload-resume` | Upload a PDF or DOCX and extract text |
| `POST` | `/api/analyze` | Analyze a resume against a single job description |
| `POST` | `/api/rank-jobs` | Rank a resume against the enriched job corpus |
| `POST` | `/api/jobs/search` | Search and filter jobs with pagination |
| `POST` | `/api/bulk-match` | Match multiple resumes against multiple jobs (leaderboard matrix) |

---

## Project Structure

```
resume-match/
├── backend/                  # FastAPI application
│   ├── app/
│   │   ├── api/routes.py     # Route definitions
│   │   ├── jobs/             # Job ranking & repository (SQLite queries)
│   │   ├── models/           # Pydantic schemas
│   │   ├── nlp/              # NLP pipeline modules
│   │   │   ├── entity_extractor.py
│   │   │   ├── keyword_extractor.py
│   │   │   ├── matcher.py            # Orchestrator — runs full pipeline
│   │   │   ├── preprocessor.py
│   │   │   ├── section_parser.py
│   │   │   ├── similarity.py
│   │   │   └── word2vec_expander.py
│   │   └── main.py           # App factory, model preloading
│   ├── tests/                # pytest test suite
│   ├── requirements.txt
│   └── run.py                # Uvicorn entry point
│
├── job-pipeline/             # Data engineering pipeline
│   ├── scripts/
│   │   ├── 01_ingest.py      # Download raw CKAN + CSV/XLSX sources
│   │   ├── 02_transform.py   # Normalize postings + reference files
│   │   ├── 03_enrich.py      # Join to NOC/OaSIS competencies
│   │   ├── 04_synthesize.py  # Assemble synthetic JD text
│   │   ├── 05_load.py        # Write to SQLite
│   │   ├── 06_validate.py    # Verify row counts and outputs
│   │   ├── 07_train_word2vec.py  # Train domain Word2Vec model
│   │   ├── _common.py        # Shared utilities
│   │   └── run_all.py        # Run the full pipeline end-to-end
│   └── requirements.txt
│
├── src/                      # Next.js frontend (App Router)
│   ├── app/
│   │   ├── page.tsx          # Home — upload resume, choose mode
│   │   ├── results/          # Single-JD & rank results display
│   │   ├── jobs/             # Searchable job corpus browser
│   │   ├── leaderboard/      # Bulk match score matrix
│   │   └── about/            # About page
│   ├── components/           # Shared UI components
│   └── providers/            # Theme provider
│
├── package.json
├── tsconfig.json
└── next.config.ts
```

---

## Tech Stack

| Layer | Technologies |
|---|---|
| **Frontend** | Next.js 16, React 19, TypeScript, Tailwind CSS v4, Lucide React |
| **Backend** | FastAPI, Uvicorn, Pydantic v2 |
| **NLP** | spaCy, NLTK, sentence-transformers (`all-MiniLM-L6-v2`), Gensim Word2Vec, scikit-learn |
| **Data** | pandas, SQLite, requests, pdfplumber, python-docx |
| **Testing** | pytest, httpx |

---

## Running Tests

```bash
cd backend
pytest tests/ -v
```

---

---

## 🛠️ Self-Hosting & Deployment

The live version is hosted on **Hugging Face (Backend)** and **Vercel (Frontend)**. If you wish to replicate the deployment:

### Backend (Hugging Face Spaces)
1. Create a new Space with the **Docker** SDK and the **Blank** template.
2. Connect your repository; the `Dockerfile` in the root will handle the build.
3. Ensure Git LFS is enabled for `jobs.db` and the Word2Vec model.

### Frontend (Vercel)
1. Import the repository.
2. Set `NEXT_PUBLIC_API_BASE_URL` to your Hugging Face Space URL plus `/api`.

---

## License

This project is for educational and portfolio purposes.

---

## Author

- **Osele Adeoye** — [GitHub](https://github.com/Oseleadeoye) | [LinkedIn](https://www.linkedin.com/in/oseleadeoye/)
