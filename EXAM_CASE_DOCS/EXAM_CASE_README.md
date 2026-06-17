Your Exam Case — Stakeholder A

You have been assigned Stakeholder A. Your entire exam case — analytical questions, modelling decisions, and dashboard — must be grounded in this stakeholder's context and needs.

State your stakeholder in your report. Write which stakeholder you were assigned on the first page of your report.md. The rubric is assessed against your stakeholder's specific context.
Your Documents

Stakeholder brief: stakeholder_a_26_en.pdf — read this first. It contains your context, user story, predefined analytical question, and requirements for your own additional question.
Question paper: question_paper_26_en.pdf— read alongside the brief. Describes all phases, artefacts, and submission requirements.
Rubric: rubrics_2026_en.html — review before submitting. Describes what is expected at each performance level.
What You Are Building

You will design and implement a full analytical data warehouse prototype for your stakeholder, following the ADM pipeline:

Phase 0 — Load

Load raw F1 data into DuckDB using load/load.py. No transformation at this stage.

Phase 1 — Staging

Clean, rename, and type-correct the raw data. Add tests and documentation. Is the data technically trustworthy?

Phase 2 — Intermediate Model

Join sources, add calculated and categorical fields. Document your foundation and DBML design before writing SQL.

Phase 3 — Star Model

Define grain, metrics, and dimensions. Build dim_ and fct_ tables in dbt. Two analytical questions → four fact tables.

Phase 4 — Dashboard

Build a Metabase dashboard connected to your fact tables. Show both grain levels and filter by team and circuit.

What to Submit

Zipped exam-case folder (all dbt models, load/load.py, design.dbml, report.md)
PDF export of report.md
PDF export of your Metabase dashboard
Screen recording — 2–5 minutes demonstrating your dashboard (Mp4 File)