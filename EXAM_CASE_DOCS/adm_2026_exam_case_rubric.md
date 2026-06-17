# ADM 2026 - Exam Case Rubric

**Course:** Advanced Data Management - L.29114  
**Course year:** 2025-2026  
**Quarter:** 4

Each criterion is assessed across five levels: **Insufficient**, **Poor**, **Sufficient**, **Good**, and **Excellent**.

- **Insufficient**, **Sufficient**, and **Excellent** are described in full.
- **Poor** falls between Insufficient and Sufficient.
- **Good** falls between Sufficient and Excellent.
- Teacher comments provide specific feedback at Poor and Good levels.

## Learning Outcomes Assessed

LOs assessed in this exam case. LOs not listed, **LO1**, **LO3**, **LO6**, and **LO8**, are assessed through Gatekeeper exercises and do not contribute to the final grade.

| Learning Outcome | Description | Weight |
|---|---|---:|
| LO2 | Design and implement an OLAP data warehouse | 45% |
| LO4 | Clean and prepare data for further processing | 30% |
| LO5 | Import data from multiple sources in an automated way | 10% |
| LO7 | Visualize information in a way that provides relevant insights to stakeholders | 15% |

## Grade Distribution by Phase

| Phase | Weight |
|---|---:|
| Phase 0 - Load | 5% |
| Phase 1 - Staging | 20% |
| Phase 2 - Intermediate Model | 20% |
| Phase 3 - Star Model | 40% |
| Phase 4 - Dashboard | 15% |
| **Total** | **100%** |

## LO Distribution Across Phases

| LO | Weight | Contributing phases |
|---|---:|---|
| LO2 | 45% | Phase 2 - Business Understanding & Analytical Questions, 10%; Phase 3 - Grain Reasoning & Metrics, 18%; Phase 3 - Star Model Design & Implementation, 17% |
| LO4 | 30% | Phase 1 - Staging, 20%; Phase 2 - Intermediate Model Planning & Implementation, 10% |
| LO5 | 10% | Phase 0 - Load, 5%; Phase 3 - Layer Discipline & dbt Execution, 5% |
| LO7 | 15% | Phase 4 - Dashboard, 15% |

---

# Phase 0 - Load to Raw

**Total:** 5 marks  
**Learning Outcome:** LO5

| Criterion | Insufficient | Poor | Sufficient | Good | Excellent |
|---|---|---|---|---|---|
| **Load to Raw** / 5 marks | Data not loaded or major sources missing. Business logic introduced at load stage. **0** | Data partially loaded but some sources missing or consolidation incomplete. **2** | All data loaded correctly into DuckDB. Files consolidated logically. No business logic introduced. **3** | All data loaded with clear consolidation. Report explains loading decisions. **4** | Efficient and well-structured loading. Clear consolidation strategy. Contextual fields correctly derived from filenames where applicable. **5** |

---

# Phase 1 - Staging

**Total:** 20 marks  
**Learning Outcome:** LO4

| Criterion | Insufficient | Poor | Sufficient | Good | Excellent |
|---|---|---|---|---|---|
| **Staging Models, Tests & Documentation** / 20 marks | Staging incomplete or inconsistent. Data types incorrect. Tests missing or inappropriate. `schema.yml` missing or inadequate. **0** | Core staging present but with gaps, for example data types partially corrected, some tests added but coverage incomplete, or documentation missing for key columns. **6** | Staging models clean and consistent. Data types correct. Appropriate tests added. `schema.yml` includes concise model and key column descriptions. Business logic not introduced. **12** | All Sufficient elements present. Tests are well-chosen with clear purpose. Documentation covers all relevant columns. Structural issues in raw data identified and corrected. **16** | Strong technical discipline throughout. Structural defects in raw data identified and fixed with clear justification. Tests are well-chosen and meaningful, not just defaults. Documentation is precise and complete. **20** |

---

# Phase 2 - Intermediate Model

**Total:** 20 marks

This phase is assessed across two dimensions:

1. How well the student translates the stakeholder's needs into analytical questions and field choices.
2. How well the intermediate model is planned and implemented as a technical foundation.

## Business Understanding & Analytical Questions

**Marks:** 10  
**Learning Outcome:** LO2  
**Professional Skills:** OV-MPA, OV-OZK, DI-STH

| Insufficient | Poor | Sufficient | Good | Excellent |
|---|---|---|---|---|
| Analytical questions are vague, generic, or not grounded in the stakeholder brief. The student-defined question adds no analytical value or simply restates the predefined one. No clear connection between stakeholder need and planned analysis. **0** | Questions stated but lack precision, or the student-defined question is too similar to the predefined one. Some business reasoning present but the connection between stakeholder need and field choices is incomplete. **3** | Both analytical questions are clearly stated and directly answerable using the available data. The student-defined question is meaningful and within realistic scope. Field selection is accompanied by basic business reasoning. The student explains why each field is needed. **6** | Both questions are clear and well-reasoned. The student-defined question adds genuine analytical depth. Field choices are justified in terms of the stakeholder's decision context, not just data availability. **8** | Both questions are precise and reflect genuine analytical thinking. The student-defined question shows initiative and is non-trivial. All field choices and derived logic are explicitly connected to what the stakeholder needs to understand, not just what is technically possible. Business intent is consistently visible throughout. **10** |

## Intermediate Model Planning & Implementation

**Marks:** 10  
**Learning Outcome:** LO4  
**Professional Skills:** OV-OPL, DI-COM

| Insufficient | Poor | Sufficient | Good | Excellent |
|---|---|---|---|---|
| Foundation not documented or join logic missing. Added fields not justified or contain aggregation. DBML missing or drawn after implementation. Model does not build or contains aggregation. **0** | Foundation partially documented but with gaps, for example join keys unclear, some added fields missing justification, or DBML incomplete. Model may build but does not fully reflect the plan. **3** | Foundation clearly documented: staging models, join keys, and base fields identified. Added fields defined with derivation and purpose explained. DBML drawn before implementation and reflects the planned design. Model builds without errors and contains no aggregation. **6** | All Sufficient elements present. Added field derivations are precise. DBML is complete and clearly readable. Implementation matches the plan with no unexplained deviations. **8** | Foundation and field choices connect directly to the analytical questions. Distinction between calculated and categorical fields clearly applied. DBML is precise and complete. Implementation fully reflects the planned design with no deviations. **10** |

---

# Phase 3 - Star Model

**Total:** 40 marks

Grain Reasoning and Star Model Design are assessed as a connected argument. The design should flow directly from the grain decisions. Layer Discipline is assessed as a separate technical check.

## Grain Reasoning & Metrics

**Marks:** 18  
**Learning Outcome:** LO2  
**Professional Skills:** OV-OZK, OV-OPL

| Insufficient | Poor | Sufficient | Good | Excellent |
|---|---|---|---|---|
| Grain statements missing, unclear, or not written as "each row represents" sentences. Primary and roll-up grains not defined for both questions. Metrics missing or statistical operations not justified. **0** | Some grain statements present but incomplete, for example only one question has both grains defined, or metric justifications are superficial. The four-fact-table structure may be partially achieved. **5** | Primary and roll-up grain defined for both analytical questions as clear "each row represents" sentences, resulting in four fact tables. Metrics defined with correct statistical operations. Justification explains why the chosen operation is appropriate at that grain. **11** | All Sufficient elements present with stronger reasoning. The relationship between primary and roll-up grain is explained. Metric justifications address why the chosen operation suits the grain rather than restating the metric definition. **14** | Grain decisions are precise and explicitly connected to the analytical questions. The relationship between primary and roll-up grain is explained in terms of what each level of detail enables. Metric justifications demonstrate genuine statistical reasoning, including why an alternative operation would give a misleading result at that grain. **18** |

## Star Model Design & Implementation

**Marks:** 17  
**Learning Outcome:** LO2  
**Professional Skills:** OV-OPL, DI-COM

| Insufficient | Poor | Sufficient | Good | Excellent |
|---|---|---|---|---|
| DBML missing or drawn after implementation. Fact tables do not match defined grain. Dimensions incorrectly structured or missing. Metrics in implementation misaligned with plan. **0** | DBML present but incomplete or inconsistent with the report. Some fact tables respect grain but others do not, or dimensions are present but not correctly structured. Implementation partially matches the plan. **5** | DBML represents a planned star schema with clear fact and dimension relationships. Fact tables respect defined grain. Dimensions correctly structured and joined. Implemented metrics match the planned design. Model builds without errors. **10** | All Sufficient elements present. Dimensions are reused where appropriate. DBML and implementation are clearly consistent. Planning decisions are traceable in the code. **13** | Design is coherent and well-structured. Dimensions reused across fact tables where appropriate. DBML and implementation read as one consistent argument. Planning decisions are visible in the code. Architecture across layers, intermediate to mart, is clearly reasoned and justified. **17** |

## Layer Discipline & dbt Execution

**Marks:** 5  
**Learning Outcome:** LO5

| Insufficient | Poor | Sufficient | Good | Excellent |
|---|---|---|---|---|
| `dbt run` fails. Layering violations present, for example staging referenced from mart, aggregation in intermediate models, or incorrect materialisation configuration. **0** | `dbt run` succeeds but minor layering issues present, for example an occasional cross-layer reference or inconsistent materialisation. **2** | `dbt run` succeeds. Layering respected: staging -> intermediate -> mart with no cross-layer violations. Materialisation configured correctly per layer. **3** | All Sufficient elements present. Dependency structure is clean and materialisation is consistent throughout. **4** | Clean dependency structure throughout. No cross-layer references. Materialisation configured correctly and consistently. Pipeline is professional and reproducible. **5** |

---

# Phase 4 - Dashboard

**Total:** 15 marks  
**Learning Outcome:** LO7

| Criterion | Insufficient | Poor | Sufficient | Good | Excellent |
|---|---|---|---|---|---|
| **Dashboard & Interpretation** / 15 marks | Dashboard incomplete or inconsistent with model. Primary and roll-up grain not demonstrated for both questions. **0** | Dashboard present but only partially demonstrates the model, for example only one grain level shown, or filtering not functional. Report interpretation is minimal or missing. **4** | Primary and roll-up grain demonstrated for both analytical questions. Filtering by team and circuit available. Basic interpretation of what the dashboard shows is provided in the report. **9** | All Sufficient elements present. Dashboard is well-organised. Report explains how changing grain affects what the stakeholder can see and understand. **12** | Dashboard clearly validates the modelling decisions made in Phases 2 and 3. The impact of grain on interpretation is explained. Insight is directly connected to the stakeholder's needs. The student can articulate what the engineer gains from each view. **15** |

---

# Notes

- **Poor and Good levels:** Poor and Good marks are awarded at teacher discretion between the described thresholds. Teacher comments explain the specific reasoning.
- **Report and own understanding:** Across all phases, the report must reflect the student's own reasoning and understanding. If report text reads as generated or paraphrased AI output without evidence of personal understanding, this should be treated as insufficient for the relevant criterion regardless of technical correctness.
- **Student-defined analytical question:** The additional analytical question is graded as part of Phase 2, Business Understanding & Analytical Questions. There is no separate mark for it.
- **Calculated and categorical fields:** The distinction between calculated fields, derived numerics, and categorical fields, bands or labels, is a teaching concept introduced in Lesson 7. Students are not required to label fields by type at Sufficient level. At Excellent level, evidence that the student understands and applies this distinction is an indicator of deeper understanding.
- **DBML diagrams:** DBML diagrams must represent planned design, not be reverse-engineered from the database. If there is evidence of reverse-engineering, for example a diagram inconsistent with report planning text, this should be treated as Insufficient for the relevant row.
- **Screen recording:** The screen recording is required evidence for Phase 4 assessment. It must demonstrate dashboard filtering and both grain levels. If no recording is submitted, Phase 4 cannot be assessed above Poor, 4 marks, because interactivity and filtering cannot be verified from the PDF alone.
- **Professional Skills:** Professional Skills, PS, links are shown per row for reference. They are not assessed separately in this rubric but map to the LOs that reference them.
- **LOs assessed by Gatekeepers:** LOs without an examMatrix entry, LO1, LO3, LO6, and LO8, are assessed through Gatekeeper exercises and do not contribute to the exam case grade.
