# ADM 2026 — Exam Case

## Introduction

In this exam case you will develop an Analytical Data Warehouse prototype for a Formula 1 analytics platform.

The objective is to demonstrate a disciplined analytical modelling process:

```text
Load → Staging → Intermediate Model → Star Model → Dashboard
```

You will be assigned one stakeholder.

Your stakeholder contains one user story with one predefined analytical question. You must define one additional analytical question derived from the same user story.

There is no single correct model. However, your modelling decisions must be justified and internally consistent.

## Report Expectations

The report (`report.md`) must be written in your own words and reflect your understanding of each phase.

Your explanations must demonstrate your grasp of the concepts, the decisions you made, and the reasoning behind them. A report that restates instructions or reads as generated text without evidence of personal understanding is not sufficient.

## Use of Generative AI

You may use Generative AI transparently and responsibly according to Saxion's Guide to AI Use for Students.

Your work must contain an account of the use of AI in your process according to APA guidelines. You always remain responsible for the content of your work. In case of doubt about the authenticity of your work, your teacher may schedule an additional interview with you or give you an additional assignment. The examination board may also be called in.

## Dataset Context

This exam case is a prototype.

The dataset contains historical Formula 1 race data for selected circuits:

- Baku (Azerbaijan)
- Monza (Italy)
- Zandvoort (Netherlands)

Data spans multiple seasons from 2018 to 2024, depending on circuit availability.

The prototype must:

- Work for any team
- Work for any driver
- Be adaptable for future races and seasons
- Be structurally reusable

You may derive additional contextual fields if justified in your report.

## Project Structure and Submission

You must work inside the provided `exam-case` project folder.

Raw data is located in:

```text
exam-case/raw/
```

All artefacts must be created inside the `exam-case` folder.

## Submission Requirements

Submit:

1. A zipped version of the complete `exam-case` folder.
   - Ensure `design.dbml` is complete and included.
   - Ensure `report.md` is complete and included.
2. A PDF export of your `report.md`.
3. A PDF export of your dashboard.
4. A screen recording, 2–5 minutes, demonstrating your dashboard.

## Screen Recording Requirements

Your screen recording must demonstrate:

- The dashboard loading from your fact tables.
- Filtering by team and filtering by circuit.
- Both the primary grain and roll-up grain views for each analytical question.
- A brief explanation of one insight the dashboard reveals for the stakeholder.

Audio explanation is optional but recommended.

# Phase 0 — Load to Raw

## Objective

Load all raw data into DuckDB using `load/load.py`.

## Expectations

- Similar file types must be consolidated into logical raw tables.
- File names may be used to derive contextual fields, for example year or circuit.
- No cleaning beyond structural necessity.
- No business logic.

## Artefacts

- `load/load.py`
- Raw tables stored in DuckDB

Briefly describe your loading approach in `report.md`.

# Phase 1 — Staging

## Objective

Prepare technically reliable data for analytical transformation.

Staging answers one question: is the data technically trustworthy?

## Expectations

Create staging models in `models/staging/`.

You must:

- Standardise naming conventions.
- Ensure correct data types.
- Remove or standardise raw import artefacts such as inconsistent naming, unused columns, or formatting inconsistencies.
- Correct structural data issues such as data type mismatches, date formatting, or improperly parsed numeric fields.
- Add appropriate data tests.
- Document staging models using `schema.yml`.

Business logic must **not** be introduced in staging.

Your stakeholder brief specifies domain-specific filtering criteria. Apply these at the appropriate layer.

## `schema.yml` Requirements

In `models/staging/schema.yml`:

- Provide a short description, 1–3 sentences, per staging model.
- Provide column descriptions for cleaned, renamed, or important fields.
- Add appropriate data tests.

Briefly describe your staging decisions in `report.md`.

# Phase 2 — Intermediate Model

> Design question: "What does your analytical foundation look like before any grouping?"

## Planning

Document the following in `report.md` before writing any SQL.

## Analytical Questions

- State the predefined analytical question from your stakeholder brief.
- Define your own additional analytical question derived from the user story. Your stakeholder brief specifies requirements for this question — ensure your question meets them.
- Briefly justify both.

## Foundation

- Identify which staging models are required.
- State the join keys used to combine them.
- List the base fields carried forward.

## Added Fields

For each field you add in the intermediate model:

- State the field name.
- Explain how it is derived or defined.
- Explain why it is needed to answer one or both analytical questions.

## Intermediate Model Design (DBML)

Design the intermediate model in `design.dbml` before writing any SQL.

Your design must:

- Show all base and added fields.
- Contain no aggregation.
- Serve as the analytical foundation for both questions.

The DBML must represent your planned design, not a reverse-engineered diagram.

## Implementation

Create your intermediate model in `models/intermediate/`.

- No aggregation.
- Must match your planned design.
- `dbt run` must succeed.

# Phase 3 — Star Model

> Design question: "What question does each fact table answer, and how does it answer it?"

## Planning

Document the following in `report.md` before writing any SQL.

## Analytical Questions

Restate both analytical questions. For each, identify which fact table pair it produces.

## Each Row Represents (Grain)

For each analytical question, define:

- A primary grain — write it as: "Each row represents one … in one …"
- A roll-up grain — a summarised version of the primary grain

Each grain produces one fact table. Two analytical questions produce four fact tables in total.

## Metrics

For each fact table, define your metrics:

| Metric name | Source field | Statistical operation | Justification |
| --- | --- | --- | --- |
|  |  |  |  |

The statistical operation must align with the grain and the analytical question. Justify why you chose that operation rather than an alternative.

## Star Model Design (DBML)

Extend `design.dbml` to include your full star model:

- Dimension tables, prefixed with `dim_`
- Fact tables, prefixed with `fct_`, one per grain
- Relationships between fact and dimension tables

Dimensions should be reused across fact tables where appropriate.

The DBML must represent your planned design, not a reverse-engineered diagram.

## Implementation

Create your mart models in `models/mart/`.

- Fact tables must respect defined grain.
- Dimensions must be correctly structured and joined.
- Layering discipline must be respected — no staging references in mart models.
- `dbt run` must succeed.

# Phase 4 — Dashboard

## Objective

Validate your modelling decisions through a working dashboard.

## Expectations

Create a dashboard connected to your fact tables.

The dashboard must:

- Demonstrate the primary grain for each analytical question.
- Demonstrate the roll-up grain for each analytical question.
- Allow filtering by team and by circuit.
- Demonstrate the value of the metrics you defined in Phase 3 — not just one metric per question.
- Clearly reflect your modelling decisions.

## Report

In `report.md`, explain:

- How grain affects interpretation.
- What insight the stakeholder gains from each part of the dashboard.

# Important

Justification matters more than format.

There is no single correct design.

However, there must be:

- Clear grain reasoning.
- Correct statistical logic.
- Clean layering.
- Meaningful dashboard validation.
