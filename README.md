
# ADM 2026 — Workspace

This workspace contains everything you need for the Advanced Data Management course: gatekeeper exercises, a loading exercise, the exam case, and the machine learning teaser.

## Contents

* [Getting Started](https://claude.ai/chat/8469ab26-49db-4eca-888b-a95e4d3426fd#getting-started)
* [Helpers](https://claude.ai/chat/8469ab26-49db-4eca-888b-a95e4d3426fd#helpers)
* [Gates, Exercises &amp; Teaser](https://claude.ai/chat/8469ab26-49db-4eca-888b-a95e4d3426fd#gates-exercises--teaser)
* [Exam Case](https://claude.ai/chat/8469ab26-49db-4eca-888b-a95e4d3426fd#exam-case)
* [Troubleshooting](https://claude.ai/chat/8469ab26-49db-4eca-888b-a95e4d3426fd#troubleshooting)

---

## Getting Started

### Prerequisites

Before you begin, make sure you have the following installed:

* **Docker Desktop** (version 4.0.0 or higher) — [download](https://www.docker.com/products/docker-desktop/)
* **Visual Studio Code** (version 1.56.0 or higher) — [download](https://code.visualstudio.com/)
* **VS Code Extension: Dev Containers** — install from the Extensions panel in VS Code (search `ms-vscode-remote.remote-containers`)

Docker Desktop must be **running** before you open the workspace.

### Opening the Container

1. Open this folder in VS Code.
2. VS Code will detect the `.devcontainer` folder and show a notification:  **"Reopen in Container"** . Click it.
   * If the notification doesn't appear, press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac), type `Dev Containers: Reopen in Container`, and select it.
3. The first time you open the container, Docker will pull the course image (`teachercraig/adm-course:2026.2`). This may take a few minutes depending on your connection.
4. Once running, the VS Code terminal is inside the container. The workspace is mounted at `/adm-workspace`.

### Workspace Structure

```
adm-workspace/
├── .devcontainer/                  ← Container configuration (do not modify)
├── gatekeepers/                    ← Gatekeeper exercises (Sprint 1, 2 & 3)
│   ├── gate-a-pizza/               ← Gate A: Normalization (SQLite)
│   ├── gate-a-stackexchange/       ← Gate A: Optimization (SQLite)
│   ├── gate-a-answersheet.md       ← Your Gate A answers (submit this as PDF)
│   ├── gate-b-dogs/                ← Gate B: Staging with dbt (DuckDB)
│   ├── gate-b-answersheet.md       ← Your Gate B answers (submit this as PDF)
│   ├── gate-bc-student-enrolment/  ← Gate B/C: Planning, modelling & dashboard (DuckDB)
│   └── gate-c-answersheet.md       ← Your Gate C answers (submit this as PDF)
├── exercises/
│   └── load/                       ← Loading tutorial (Lesson 4, self-study)
├── exam-case/                      ← Your exam case project (DuckDB + dbt)
│   ├── raw/                        ← F1 race data files (do not modify)
│   ├── load/                       ← Your loading script (load.py)
│   ├── models/                     ← Your dbt models (staging, intermediate, mart)
│   ├── design.dbml                 ← Your DBML design file (required for submission)
│   ├── report.md                   ← Your report (required for submission)
│   ├── dbt_project.yml             ← dbt project configuration
│   └── profiles.yml                ← dbt connection profile (points to f1.duckdb)
├── ml_teaser/                      ← Machine learning teaser exercise
├── problems-solutions.md           ← Common issues and fixes
└── README.md                       ← This file
```

---

## Helpers

### Pasting Screenshots into Markdown

The **Paste Image** extension is pre-configured. Take a screenshot, copy it to your clipboard, place your cursor in the markdown file where you want the image, then press `Ctrl+Alt+V` (or `Cmd+Alt+V` on Mac). The image is saved and inserted automatically.

### Exporting to PDF

Use the **Markdown PDF** extension to export any answer sheet or report:

1. Open the markdown file.
2. Press `Ctrl+Shift+P`, type `Markdown PDF: Export (pdf)`, and select it.
3. Wait 15–30 seconds — PDF generation uses Chromium in the background. Watch for the notification in the bottom right confirming it is complete.
4. The PDF is saved in the same folder as the markdown file. Open it from the Explorer panel to verify before submitting.

---

## Gates, Exercises & Teaser

### Gate A — Pizza & StackExchange (SQLite)

Gate A uses SQLite databases. Connect with DBCode, write SQL queries, and record your answers in `gate-a-answersheet.md`.

**Connect to a database:**
Open DBCode in the sidebar and create a connection using the path to the file:

```
/adm-workspace/gatekeepers/gate-a-pizza/pizza.db
```

**Visualise a DBML diagram:**
Open any `.dbml` file — the dbdiagram preview panel opens alongside it automatically.

When complete, paste your screenshots into the answer sheet, export to PDF, and submit to Brightspace.

### Gate B — Dogs (dbt + DuckDB)

Data is pre-loaded. Navigate to the project and run dbt:

```bash
cd /adm-workspace/gatekeepers/gate-b-dogs
dbt run
dbt test
```

To view documentation:

```bash
dbt docs generate
dbt docs serve --port 8888
```

Then open `http://localhost:8888` in your browser.

Record answers in `gate-b-answersheet.md`, export to PDF, and submit to Brightspace.

### Gate B/C — Student Enrolment (dbt + DuckDB)

This exercise spans Gate B (Phase 2) and Gate C (Phase 3 + dashboard).

```bash
cd /adm-workspace/gatekeepers/gate-bc-student-enrolment
cd load && python load.py && cd ..
dbt run
dbt test
```

Gate B answers go in `gate-b-answersheet.md`. Gate C answers go in `gate-c-answersheet.md`. Export each to PDF and submit to Brightspace when complete.

### Loading Exercise (Lesson 4, Self-Study)

A guided tutorial teaching you how to load CSV, JSON, and TXT files into DuckDB using Python and pandas. The skills you practise here are used directly in Phase 0 of the exam case.

```bash
cd /adm-workspace/exercises/load/scripts
python load_dog_breeds_csvs.py
```

Connect DBCode to `exercises/load/db/dogs.duckdb` to explore the results. This exercise is not submitted.

### ML Teaser

Completed during Lesson 11. Follow the instructions in `ml_teaser_qp.md` and record your results in `ml_teaser_answer_sheet.md`.

```bash
cd /adm-workspace/ml_teaser
dbt run
```

Export `ml_teaser_answer_sheet.md` to PDF and submit to Brightspace.

---

## Exam Case

Raw F1 data is in `exam-case/raw/`. Work through the phases in order.

```bash
cd /adm-workspace/exam-case
```

**Phase 0 — Load:**

```bash
cd load && python load.py && cd ..
```

**Phase 1–3 — Run dbt:**

```bash
dbt run
dbt test
```

**Documentation:**

```bash
dbt docs generate
dbt docs serve --port 8888
```

**Query your database** by connecting DBCode to `exam-case/f1.duckdb`.

**Key files you must complete:**

| File                          | Purpose                                          |
| ----------------------------- | ------------------------------------------------ |
| `load/load.py`              | Loading script (Phase 0)                         |
| `models/staging/*.sql`      | Staging models (Phase 1)                         |
| `models/staging/schema.yml` | Documentation and tests (Phase 1)                |
| `models/intermediate/*.sql` | Intermediate model (Phase 2)                     |
| `models/mart/*.sql`         | Dimension and fact tables (Phase 3)              |
| `design.dbml`               | DBML design — intermediate model and star model |
| `report.md`                 | Your report — decisions for each phase          |

Export `report.md` to PDF before submitting. See submission requirements on Brightspace.

Metabase is **not** included in this workspace — it runs separately on your local machine. See the Metabase Setup Guide on Brightspace → Getting Started.

---

## Troubleshooting

**Container won't start** — make sure Docker Desktop is running. Try `Ctrl+Shift+P` → `Dev Containers: Rebuild Container`.

**`dbt run` says "Could not find profile"** — check you are in the correct project folder. Each project has its own `profiles.yml`.

**`dbt run` says database is locked** — close any open DBCode connections to the DuckDB file, then retry. DuckDB allows only one write connection at a time.

**PDF generation appears to do nothing** — it is working. Chromium takes 15–30 seconds. Wait for the notification in the bottom right before looking for the output file.

**Port 8888 already in use** — use a different port: `dbt docs serve --port 9999`.

**Python script fails with "module not found"** — install inside the container: `pip install package_name --break-system-packages`.

**Extensions not loading** — reload the window: `Ctrl+Shift+P` → `Developer: Reload Window`.

For additional issues, check `problems-solutions.md`.
