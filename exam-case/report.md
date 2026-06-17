
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

**Q1 (predefined):** What is the difference between the average lap time of each driver and the average lap time of the race winner in the same race?

This question requires lap-level data joined with session results to identify the winner per race. Only drivers classified as `Finished` are included, as lapped or retired drivers did not complete the full race distance and their average pace would not represent a comparable competitive effort.

**Q2 (additional):** How does the average lap time gap between each driver and the race winner vary across different race conditions — wet versus dry races and track temperature ranges?

This question builds directly on Q1 and adds race conditions as an analytical dimension. The stakeholder brief explicitly requires the additional question to incorporate at least one race condition variable. Wet versus dry and track temperature were chosen because they are directly available in the weather data, operationally meaningful to performance engineers, and produce dimensions that can be reused across the star model. One limitation is that only 2 of the 17 races in this dataset had rainfall, which constrains the statistical depth of the wet/dry split. This is noted as a prototype constraint — the architecture is correct and extensible for larger datasets.

## Foundation

**Staging models required:**
- `stg_laps` — provides the core grain (one lap per driver per race) and the `lap_time_seconds` metric
- `stg_session_results` — provides `finish_position`, `race_status`, `team_id`, and driver identity fields
- `stg_weather` — provides `Rainfall` and `TrackTemp` per race for condition classification

**Join keys:**
- `stg_laps` joined to `stg_session_results` on `race_date + driver_number`
- Weather is aggregated to one row per `race_date` (max rainfall, avg track temp) before joining on `race_date`

**One row represents:** one lap driven by one driver in one race.

**Base fields carried forward:** `race_date`, `circuit`, `season`, `driver_number`, `driver_abbreviation`, `driver_full_name`, `team_name`, `team_id`, `lap_number`, `lap_time_seconds`, `tyre_compound`, `tyre_life`, `finish_position`, `classified_position`, `race_status`

## Added Fields

| Field | Type | Derived from | Why needed |
|---|---|---|---|
| `is_finished` | categorical | `race_status = 'Finished'` | Q1 and Q2 filter — only finished drivers are included in pace comparisons |
| `is_wet_race` | categorical | `MAX(is_raining)` per race → `'wet'` or `'dry'` | Q2 dimension — wet vs dry condition |
| `avg_track_temp_c` | calculated | `AVG(track_temp_c)` per race from stg_weather | Input for track_temp_category |
| `track_temp_category` | categorical | `avg_track_temp_c`: `<30='cool'`, `30-44='warm'`, `>=45='hot'` | Q2 dimension — temperature condition |

## Intermediate Model Design

The intermediate model is designed as a single wide table `int_race_laps` that preserves the lap-level grain throughout. No aggregation is applied. Weather data is pre-aggregated per race in a sub-CTE before joining — this produces one weather row per race which is then attached to every lap of that race. This does not reduce the grain; it adds race-level context to each lap row.

The `is_finished` field is derived here rather than in staging because it is a business rule (the stakeholder specifies only finished drivers), not a technical data quality fix. The temperature categories (`cool`, `warm`, `hot`) are defined here because they represent analytical classification logic that must live in dbt, not in the dashboard.

The DBML diagram in `design.dbml` was drawn before writing the SQL and represents the planned design.

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
