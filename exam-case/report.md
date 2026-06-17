
Name: `<insert here>`
Class: `<insert here>`
Teacher: `<insert here>`

---

# Phase 0 — Load to Raw

The raw data consists of four file types repeated across 17 race events: lap-level data (`_laps.csv`), session results (`_session_results.json`), weather measurements (`_weather.csv`), and race control messages (`_race_control_messages.csv`), plus a single `schedule.txt` file with event metadata.

Each file type was consolidated into one raw table in DuckDB (`raw_laps`, `raw_session_results`, `raw_weather`, `raw_race_control`, `raw_schedule`), combining all 17 race files per type using `pd.concat`. The race control table was loaded for completeness but is not used in the analytical questions.

The filename encodes three contextual fields not present inside the files themselves — `race_date`, `circuit`, and `season` — which were extracted via string parsing and added as columns to every row before loading. This is not a transformation; it preserves information that would otherwise be lost.

No cleaning, type correction, renaming, or business logic was applied at this stage. All raw values arrive in DuckDB exactly as they appear in the source files.

---

# Phase 1 — Staging

Four staging models were created, one per raw source used in the analytical questions. The race control table was not staged as it is not needed for either question.

**stg_laps** is the most complex model. The `LapTime` column arrives as a timedelta string (`"0 days 00:01:28.179000"`) and is converted to total seconds using string splitting — this is necessary because DuckDB cannot aggregate or compare timedelta strings. Rows where `LapTime` is null or `"nan"` (2.7% of rows) and rows where `IsAccurate = False` (14.2%) are excluded at this stage. Inaccurate laps are laps recorded under safety car, VSC, or with telemetry issues; including them would distort pace comparisons. `DriverNumber`, `LapNumber`, and `Position` arrive as floats and are cast to their correct types. Boolean columns (`FreshTyre`, `IsPersonalBest`) arrive as strings and are cast to BOOLEAN. Sector times and speed trap columns are dropped as they are not needed for the analytical questions.

**stg_session_results** requires minimal cleaning. `Position` and `GridPosition` arrive as floats and are cast to INTEGER. The `Status` field is kept as-is with all 15 distinct values preserved — the filter to `Status = 'Finished'` is a business rule that belongs in the intermediate model, not staging. `TeamName` is kept despite being inconsistent across seasons because `TeamId` (which is stable) is used as the join key in the mart layer. Columns that are always null in race results (`Q1`, `Q2`, `Q3`), always empty (`HeadshotUrl`, `CountryCode`), or redundant (`BroadcastName`, `TeamColor`) are dropped.

**stg_weather** has one structural issue: `Rainfall` arrives as the string `"True"`/`"False"` and is cast to BOOLEAN. All numeric columns (`AirTemp`, `TrackTemp`, `Humidity`, `Pressure`, `WindSpeed`) are confirmed as floats and kept as-is.

**stg_schedule** drops all session date columns (ten columns covering practice and qualifying dates) as only event-level metadata is needed. `EventDate` is cast to DATE and `Year` is renamed to `season` for consistency with other models.

Tests added cover `not_null` on all key identifiers and join fields, and `accepted_values` on `race_status` to confirm no unexpected status values appear in future data.

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
