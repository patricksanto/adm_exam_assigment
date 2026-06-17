
Name: `<insert here>`
Class: `<insert here>`
Teacher: `<insert here>`

---

# Phase 0 — Load to Raw

<!-- Briefly describe your loading approach: how you consolidated files, what contextual fields you derived from filenames, and any decisions you made. -->

---

# Phase 1 — Staging

<!-- Describe your staging decisions: what you renamed, what data types you corrected, what structural issues you fixed, and what tests you added. Explain why. -->

---

# Phase 2 — Intermediate Model

## Analytical Questions

<!-- State the predefined analytical question. State your additional analytical question. Briefly justify both. -->

## Foundation

<!-- Which staging models are required? What join keys combine them? What base fields are carried forward? -->

## Added Fields

<!-- For each field you added: name, how it is derived or defined, and why it is needed. -->

## Intermediate Model Design

<!-- Describe your intermediate model design. The DBML diagram in design.dbml must match this section. -->

---

# Phase 3 — Star Model

## Analytical Questions

<!-- Restate both analytical questions. For each, identify which fact table pair it produces. -->

## Each Row Represents (Grain)

<!-- For each fact table, write: "Each row represents one … in one …" -->

## Metrics

<!-- For each fact table, define metrics using the table format:
| Metric name | Source field | Statistical operation | Justification |
-->

## Star Model Design

<!-- Describe your star model design: dimensions, fact tables, and how they connect. The DBML diagram in design.dbml must match this section. -->

---

# Phase 4 — Dashboard

<!-- Explain: How does grain affect interpretation? What insight does the stakeholder gain from each part of the dashboard? -->

---

# Use of Generative AI

<!-- Account for your use of AI in this project according to APA guidelines. -->
