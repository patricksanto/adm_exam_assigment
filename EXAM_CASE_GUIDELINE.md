# ADM 2026 — Exam Case Guideline
## Stakeholder A — F1 Competitiveness Analysis

> This file is your personal step-by-step guide. Follow it in order. Do not skip phases.

---

## Your Assignment at a Glance

**Stakeholder:** Performance engineers at a multi-team F1 analytics platform.  
**Goal:** Build an analytical data warehouse prototype that answers how competitive each driver's race pace is relative to the race winner — across circuits, seasons, and race conditions.  
**Pipeline:** `Load → Staging → Intermediate → Star Model → Dashboard`

---

## Grade Weights

| Phase | Weight | What is being assessed |
|---|---:|---|
| Phase 0 — Load | 5% | Loading correctness, consolidation, no business logic |
| Phase 1 — Staging | 20% | Data types, naming, tests, schema.yml, no business logic |
| Phase 2 — Intermediate | 20% | Analytical questions (10%) + model planning & implementation (10%) |
| Phase 3 — Star Model | 40% | Grain reasoning (18%) + design & implementation (17%) + layer discipline (5%) |
| Phase 4 — Dashboard | 15% | Both grains shown, filters working, insight explained |

---

## Raw Data Reference

**File naming pattern:** `YYYYMMDD_Circuit Name_Race_type.ext`

**Example:** `20180429_Azerbaijan Grand Prix_Race_laps.csv`

**From the filename you can derive:**
- `race_date` → `20180429` → `2018-04-29`
- `circuit` → `Azerbaijan Grand Prix`
- `season` → `2018`

**Four file types per race event:**

| File type | Format | Key columns |
|---|---|---|
| `_laps.csv` | CSV | `Driver`, `DriverNumber`, `LapTime`, `LapNumber`, `Team`, `Compound`, `Position`, `IsAccurate`, etc. |
| `_session_results.json` | JSON array | `DriverNumber`, `Abbreviation`, `FullName`, `TeamName`, `Position`, `ClassifiedPosition`, `Status`, `Points` |
| `_weather.csv` | CSV | `Time`, `AirTemp`, `Humidity`, `Pressure`, `Rainfall`, `TrackTemp`, `WindDirection`, `WindSpeed` |
| `_race_control_messages.csv` | CSV | `Time`, `Category`, `Message`, `Status`, `Flag`, `Scope`, `Sector`, `RacingNumber`, `Lap` |

**Additional file:** `schedule.txt` (tab-separated) — `Year`, `RoundNumber`, `Country`, `Location`, `OfficialEventName`, `EventDate`, `EventName`, `TotalLaps`, session dates

**Circuits covered:** Baku (Azerbaijan), Monza (Italy), Zandvoort (Netherlands)  
**Seasons covered:** 2018–2024 (varies per circuit)

---

## Your Two Analytical Questions

### Q1 — Predefined (from stakeholder brief)
> What is the difference between the average lap time of each driver and the average lap time of the race winner in the same race?

- Only drivers with `Status = "Finished"` in session results.
- Winner = driver with `Position = 1` in that race.
- Gap = `avg_laptime_driver − avg_laptime_winner` per race.

### Q2 — Your own question (must meet requirements)
Your question **must** incorporate at least one race condition variable:
- Wet vs dry (from `Rainfall` in weather)
- Temperature ranges (from `AirTemp` or `TrackTemp`)
- Circuit (derived from filename)
- Season (derived from filename)

**Suggested Q2:**
> How does the average lap time gap between each driver and the race winner vary across different race conditions (wet vs dry, track temperature range)?

This is a solid choice — it builds directly on Q1 and adds the required condition dimension.

---

## Submission Checklist

Before you submit, you need:

- [ ] Zipped `exam-case/` folder
- [ ] `load/load.py` — complete
- [ ] `models/staging/*.sql` — all staging models
- [ ] `models/staging/schema.yml` — docs + tests
- [ ] `models/intermediate/*.sql` — int model
- [ ] `models/mart/*.sql` — 4 fact tables + dimensions
- [ ] `design.dbml` — intermediate + star model (drawn BEFORE writing SQL)
- [ ] `report.md` — complete, in your own words
- [ ] PDF export of `report.md`
- [ ] PDF export of Metabase dashboard
- [ ] Screen recording (2–5 min) showing filters, both grains, one insight

---

## Phase 0 — Load to Raw

**Weight: 5% | Goal: get raw data into DuckDB, no transformation**

### What you must load

| Raw table name | Source files | Strategy |
|---|---|---|
| `raw_laps` | All `*_laps.csv` files | Concat all, add `race_date`, `circuit`, `season` from filename |
| `raw_session_results` | All `*_session_results.json` files | Parse JSON array, concat all, add `race_date`, `circuit`, `season` |
| `raw_weather` | All `*_weather.csv` files | Concat all, add `race_date`, `circuit`, `season` |
| `raw_race_control` | All `*_race_control_messages.csv` files | Concat all, add `race_date`, `circuit`, `season` |
| `raw_schedule` | `schedule.txt` | Single file, tab-separated |

### load.py — Step by step

```python
import duckdb
import pandas as pd
import json
from pathlib import Path
import os

RAW_DIR = Path("../raw")
DB_PATH = os.path.abspath("../f1.duckdb")

def parse_filename(filename: str):
    """Extract race_date, circuit, season from filename like 20180429_Azerbaijan Grand Prix_Race_laps.csv"""
    parts = filename.replace(".csv", "").replace(".json", "").split("_")
    date_str = parts[0]          # e.g. 20180429
    circuit = parts[1]           # e.g. Azerbaijan Grand Prix
    # season = first 4 chars of date
    season = int(date_str[:4])
    race_date = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:]}"
    return race_date, circuit, season

con = duckdb.connect(DB_PATH)

# --- raw_laps ---
frames = []
for f in sorted(RAW_DIR.glob("*_laps.csv")):
    df = pd.read_csv(f)
    race_date, circuit, season = parse_filename(f.name)
    df["race_date"] = race_date
    df["circuit"] = circuit
    df["season"] = season
    df["source_file"] = f.name
    frames.append(df)
raw_laps = pd.concat(frames, ignore_index=True)
con.execute("CREATE OR REPLACE TABLE raw_laps AS SELECT * FROM raw_laps")

# --- raw_session_results ---
frames = []
for f in sorted(RAW_DIR.glob("*_session_results.json")):
    with open(f, "r", encoding="utf-8") as fp:
        data = json.load(fp)
    df = pd.json_normalize(data)
    race_date, circuit, season = parse_filename(f.name)
    df["race_date"] = race_date
    df["circuit"] = circuit
    df["season"] = season
    df["source_file"] = f.name
    frames.append(df)
raw_session_results = pd.concat(frames, ignore_index=True)
con.execute("CREATE OR REPLACE TABLE raw_session_results AS SELECT * FROM raw_session_results")

# --- raw_weather ---
frames = []
for f in sorted(RAW_DIR.glob("*_weather.csv")):
    df = pd.read_csv(f)
    race_date, circuit, season = parse_filename(f.name)
    df["race_date"] = race_date
    df["circuit"] = circuit
    df["season"] = season
    df["source_file"] = f.name
    frames.append(df)
raw_weather = pd.concat(frames, ignore_index=True)
con.execute("CREATE OR REPLACE TABLE raw_weather AS SELECT * FROM raw_weather")

# --- raw_race_control ---
frames = []
for f in sorted(RAW_DIR.glob("*_race_control_messages.csv")):
    df = pd.read_csv(f)
    race_date, circuit, season = parse_filename(f.name)
    df["race_date"] = race_date
    df["circuit"] = circuit
    df["season"] = season
    df["source_file"] = f.name
    frames.append(df)
raw_race_control = pd.concat(frames, ignore_index=True)
con.execute("CREATE OR REPLACE TABLE raw_race_control AS SELECT * FROM raw_race_control")

# --- raw_schedule ---
raw_schedule = pd.read_csv(RAW_DIR / "schedule.txt", sep="\t")
con.execute("CREATE OR REPLACE TABLE raw_schedule AS SELECT * FROM raw_schedule")

con.close()
print("Done. All raw tables loaded.")
```

### Run it (inside the container)

```bash
cd /adm-workspace/exam-case
cd load && python load.py && cd ..
```

### Verify in DBCode

```sql
SELECT COUNT(*) FROM raw_laps;
SELECT COUNT(*) FROM raw_session_results;
SELECT COUNT(*) FROM raw_weather;
SELECT COUNT(*) FROM raw_race_control;
SELECT COUNT(*) FROM raw_schedule;
SELECT * FROM raw_laps LIMIT 5;
SELECT * FROM raw_session_results LIMIT 5;
```

### Phase 0 — report.md section

Write 3–5 sentences explaining:
- How many tables you created and why (one per file type)
- That you extracted `race_date`, `circuit`, `season` from the filename
- That no cleaning or business logic was applied

### Phase 0 Checklist

- [ ] All 5 raw tables created in DuckDB
- [ ] `race_date`, `circuit`, `season` columns added from filenames
- [ ] No type conversions or cleaning in load.py
- [ ] Script runs without errors and is idempotent (`CREATE OR REPLACE`)
- [ ] Row counts verified


---

## Phase 1 — Staging

**Weight: 20% | Goal: make data technically trustworthy. No business logic.**

### Staging models to create

| File | Source raw table | Purpose |
|---|---|---|
| `stg_laps.sql` | `raw_laps` | Clean lap data — rename cols, fix types, handle NaN lap times |
| `stg_session_results.sql` | `raw_session_results` | Clean race results — driver info, status, position |
| `stg_weather.sql` | `raw_weather` | Clean weather — numeric types, rainfall as boolean/flag |
| `stg_schedule.sql` | `raw_schedule` | Clean schedule — date types, rename cols |

> `raw_race_control` is optional — only needed if your Q2 uses flags (SC, VSC, red flag). Otherwise you can skip it.

### Sources file — create first

`models/staging/sources.yml`

```yaml
version: 2

sources:
  - name: raw
    schema: main
    tables:
      - name: raw_laps
      - name: raw_session_results
      - name: raw_weather
      - name: raw_race_control
      - name: raw_schedule
```

### stg_laps.sql

Key decisions:
- Rename the unnamed index column (`""` or column 0) — drop it
- Convert `LapTime` from timedelta string (`0 days 00:02:39.485000`) to seconds (float)
- Drop rows where `LapTime` is null or `IsAccurate = False` (not reliable times)
- Rename columns to snake_case

```sql
-- models/staging/stg_laps.sql
WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_laps') }}
),

cleaned AS (
    SELECT
        CAST(race_date AS DATE)                         AS race_date,
        circuit,
        CAST(season AS INTEGER)                         AS season,
        "Driver"                                        AS driver_abbreviation,
        CAST("DriverNumber" AS VARCHAR)                 AS driver_number,
        "Team"                                          AS team_name,
        CAST("LapNumber" AS INTEGER)                    AS lap_number,
        CAST("Position" AS INTEGER)                     AS position,
        "Compound"                                      AS tyre_compound,
        CAST("TyreLife" AS INTEGER)                     AS tyre_life,
        CAST("FreshTyre" AS BOOLEAN)                    AS fresh_tyre,
        -- Convert timedelta string to total seconds
        -- Format: "0 days 00:02:39.485000"
        CAST(
            SPLIT_PART(SPLIT_PART("LapTime", ' ', 3), ':', 1) AS FLOAT
        ) * 3600
        + CAST(SPLIT_PART(SPLIT_PART("LapTime", ' ', 3), ':', 2) AS FLOAT) * 60
        + CAST(SPLIT_PART(SPLIT_PART("LapTime", ' ', 3), ':', 3) AS FLOAT)
                                                        AS lap_time_seconds,
        CAST("IsPersonalBest" AS BOOLEAN)               AS is_personal_best,
        CAST("IsAccurate" AS BOOLEAN)                   AS is_accurate,
        "TrackStatus"                                   AS track_status,
        source_file
    FROM source
    WHERE "LapTime" IS NOT NULL
      AND "LapTime" != 'nan'
      AND "IsAccurate" = 'True'
)

SELECT * FROM cleaned
```

### stg_session_results.sql

Key decisions:
- Keep only fields needed: driver info, team, position, classified position, status
- `ClassifiedPosition` is a string — "1", "2", … or "R" for retired
- Only `Status = "Finished"` drivers will be used in the intermediate model (but apply that filter there, not here)

```sql
-- models/staging/stg_session_results.sql
WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_session_results') }}
),

cleaned AS (
    SELECT
        CAST(race_date AS DATE)             AS race_date,
        circuit,
        CAST(season AS INTEGER)             AS season,
        CAST("DriverNumber" AS VARCHAR)     AS driver_number,
        "Abbreviation"                      AS driver_abbreviation,
        "FullName"                          AS driver_full_name,
        "FirstName"                         AS driver_first_name,
        "LastName"                          AS driver_last_name,
        "TeamName"                          AS team_name,
        "TeamId"                            AS team_id,
        CAST("Position" AS INTEGER)         AS finish_position,
        "ClassifiedPosition"                AS classified_position,
        CAST("GridPosition" AS INTEGER)     AS grid_position,
        "Status"                            AS race_status,
        CAST("Points" AS FLOAT)             AS points_scored,
        source_file
    FROM source
)

SELECT * FROM cleaned
```

### stg_weather.sql

Key decisions:
- `Rainfall` arrives as `True`/`False` string — cast to boolean
- All temperature/pressure/wind columns are floats
- `Time` is a timedelta offset from session start — keep as-is or convert

```sql
-- models/staging/stg_weather.sql
WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_weather') }}
),

cleaned AS (
    SELECT
        CAST(race_date AS DATE)             AS race_date,
        circuit,
        CAST(season AS INTEGER)             AS season,
        "Time"                              AS session_time_offset,
        CAST("AirTemp" AS FLOAT)            AS air_temp_c,
        CAST("Humidity" AS FLOAT)           AS humidity_pct,
        CAST("Pressure" AS FLOAT)           AS pressure_hpa,
        CAST("Rainfall" AS BOOLEAN)         AS is_raining,
        CAST("TrackTemp" AS FLOAT)          AS track_temp_c,
        CAST("WindDirection" AS INTEGER)    AS wind_direction_deg,
        CAST("WindSpeed" AS FLOAT)          AS wind_speed_ms,
        source_file
    FROM source
)

SELECT * FROM cleaned
```

### stg_schedule.sql

```sql
-- models/staging/stg_schedule.sql
WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_schedule') }}
),

cleaned AS (
    SELECT
        CAST("Year" AS INTEGER)             AS season,
        CAST("RoundNumber" AS INTEGER)      AS round_number,
        "Country"                           AS country,
        "Location"                          AS location,
        "OfficialEventName"                 AS official_event_name,
        CAST("EventDate" AS DATE)           AS event_date,
        "EventName"                         AS event_name,
        CAST("TotalLaps" AS INTEGER)        AS total_laps
    FROM source
)

SELECT * FROM cleaned
```

### schema.yml — documentation and tests

`models/staging/schema.yml`

```yaml
version: 2

sources:
  - name: raw
    schema: main
    tables:
      - name: raw_laps
      - name: raw_session_results
      - name: raw_weather
      - name: raw_race_control
      - name: raw_schedule

models:
  - name: stg_laps
    description: "Cleaned lap-level data for all F1 races. Each row is one lap driven by one driver. LapTime converted to seconds. Rows with null or inaccurate lap times excluded."
    columns:
      - name: race_date
        description: "Date of the race, derived from the source filename."
        tests:
          - not_null
      - name: driver_abbreviation
        description: "Three-letter driver abbreviation (e.g. HAM, VER)."
        tests:
          - not_null
      - name: lap_time_seconds
        description: "Lap duration in seconds, converted from timedelta string."
        tests:
          - not_null
      - name: lap_number
        description: "Lap number within the race."
        tests:
          - not_null
      - name: team_name
        description: "Constructor team name."
        tests:
          - not_null

  - name: stg_session_results
    description: "Cleaned race session results. One row per driver per race. Includes classification status, finishing position, and team."
    columns:
      - name: race_date
        description: "Date of the race."
        tests:
          - not_null
      - name: driver_number
        description: "Driver number as string."
        tests:
          - not_null
      - name: race_status
        description: "Race status: Finished, Accident, Collision, etc."
        tests:
          - not_null
      - name: finish_position
        description: "Final race position (numeric)."
      - name: classified_position
        description: "Official classified position: '1'–'20' or 'R' for retired."

  - name: stg_weather
    description: "Cleaned weather measurements sampled throughout each race session. One row per time sample per race."
    columns:
      - name: race_date
        tests:
          - not_null
      - name: air_temp_c
        description: "Air temperature in Celsius."
      - name: is_raining
        description: "Boolean: True if rain was detected during this sample."
      - name: track_temp_c
        description: "Track surface temperature in Celsius."

  - name: stg_schedule
    description: "Race schedule metadata. One row per race event."
    columns:
      - name: season
        tests:
          - not_null
      - name: event_name
        tests:
          - not_null
      - name: total_laps
        description: "Total number of laps in the race."
```

### dbt_project.yml — set materializations

Make sure staging is set to `view` in `dbt_project.yml`:

```yaml
models:
  f1:
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    mart:
      +materialized: table
```

### Run and test

```bash
cd /adm-workspace/exam-case
dbt run
dbt test
```

### Phase 1 Checklist

- [ ] `sources.yml` created with all raw tables
- [ ] `stg_laps.sql` — LapTime converted to seconds, nulls and inaccurate laps removed
- [ ] `stg_session_results.sql` — types correct, all drivers included (filter in int layer)
- [ ] `stg_weather.sql` — Rainfall cast to boolean, temps as float
- [ ] `stg_schedule.sql` — dates and integers correct
- [ ] `schema.yml` — descriptions and tests for all models
- [ ] No `JOIN`, no `GROUP BY`, no calculated metrics in any staging model
- [ ] `dbt run` passes
- [ ] `dbt test` passes
- [ ] Report written for Phase 1

---

## Phase 2 — Intermediate Model

**Weight: 20% | Goal: analytical foundation before any aggregation**

> **Critical rule:** No `GROUP BY`. No aggregation. Every row still represents one lap.

### Plan DBML before writing SQL

Open `design.dbml` and draw the intermediate model FIRST. The rubric explicitly penalises diagrams that were reverse-engineered after coding.

### Foundation

| Staging model | Join key | Why needed |
|---|---|---|
| `stg_laps` | `race_date + driver_number` | Provides lap times (the core metric) |
| `stg_session_results` | `race_date + driver_number` | Provides team, status (Finished filter), position |
| `stg_weather` | `race_date` | Provides weather conditions (Q2 requirement) |

**One row represents:** one lap driven by one driver in one race.

**Join strategy:**
- `stg_laps` LEFT JOIN `stg_session_results` on `race_date` + `driver_number`
- For weather: aggregate `stg_weather` per `race_date` into a single representative row (avg air temp, max rainfall), then join — this is acceptable because weather is a race-level attribute, not a lap-level one.

### Added Fields

| Field | Type | Derivation | Why needed |
|---|---|---|---|
| `lap_time_seconds` | calculated | already in stg_laps | Base for gap calculation |
| `is_finished` | categorical | `race_status = 'Finished'` → boolean | Filter criterion for Q1 |
| `is_wet_race` | categorical | `MAX(is_raining) per race = True` → label `'wet'`/`'dry'` | Q2 condition dimension |
| `track_temp_category` | categorical | `avg_track_temp_c`: `<30` = 'cool', `30–45` = 'warm', `>45` = 'hot' | Q2 condition dimension |
| `avg_air_temp_c` | calculated | Average of weather samples per race | Q2 condition context |

### DBML design (intermediate)

Write this in `design.dbml`:

```dbml
Table int_race_laps {
  race_date date
  circuit varchar
  season int
  driver_number varchar
  driver_abbreviation varchar
  driver_full_name varchar
  team_name varchar
  team_id varchar
  lap_number int
  lap_time_seconds float
  tyre_compound varchar
  tyre_life int
  finish_position int
  classified_position varchar
  race_status varchar
  is_finished boolean
  is_wet_race varchar      // 'wet' or 'dry'
  avg_air_temp_c float
  track_temp_category varchar  // 'cool', 'warm', 'hot'
}
```

### int_race_laps.sql

```sql
-- models/intermediate/int_race_laps.sql
WITH laps AS (
    SELECT * FROM {{ ref('stg_laps') }}
),

results AS (
    SELECT
        race_date,
        driver_number,
        driver_abbreviation,
        driver_full_name,
        driver_first_name,
        driver_last_name,
        team_name,
        team_id,
        finish_position,
        classified_position,
        race_status,
        race_status = 'Finished'    AS is_finished
    FROM {{ ref('stg_session_results') }}
),

-- Aggregate weather to one row per race
weather_by_race AS (
    SELECT
        race_date,
        AVG(air_temp_c)                         AS avg_air_temp_c,
        AVG(track_temp_c)                       AS avg_track_temp_c,
        MAX(CAST(is_raining AS INTEGER))        AS any_rain
    FROM {{ ref('stg_weather') }}
    GROUP BY race_date
),

weather_enriched AS (
    SELECT
        race_date,
        avg_air_temp_c,
        avg_track_temp_c,
        CASE WHEN any_rain = 1 THEN 'wet' ELSE 'dry' END   AS is_wet_race,
        CASE
            WHEN avg_track_temp_c < 30 THEN 'cool'
            WHEN avg_track_temp_c <= 45 THEN 'warm'
            ELSE 'hot'
        END                                                 AS track_temp_category
    FROM weather_by_race
),

final AS (
    SELECT
        l.race_date,
        l.circuit,
        l.season,
        l.driver_number,
        l.driver_abbreviation,
        r.driver_full_name,
        r.team_name,
        r.team_id,
        l.lap_number,
        l.lap_time_seconds,
        l.tyre_compound,
        l.tyre_life,
        r.finish_position,
        r.classified_position,
        r.race_status,
        r.is_finished,
        w.is_wet_race,
        w.avg_air_temp_c,
        w.track_temp_category
    FROM laps l
    LEFT JOIN results r
        ON l.race_date = r.race_date
        AND l.driver_number = r.driver_number
    LEFT JOIN weather_enriched w
        ON l.race_date = w.race_date
)

SELECT * FROM final
```

### Run and verify

```bash
dbt run
```

Then in DBCode:
```sql
-- Check row count still equals total clean laps (no reduction from GROUP BY)
SELECT COUNT(*) FROM int_race_laps;

-- Verify is_wet_race populated
SELECT DISTINCT race_date, circuit, is_wet_race FROM int_race_laps ORDER BY race_date;

-- Check track_temp_category values
SELECT DISTINCT track_temp_category FROM int_race_laps;
```

### Write report.md — Phase 2

You must document BEFORE implementing (or at minimum document as if you planned first):

1. **Analytical Questions section** — state Q1 and Q2, justify both briefly
2. **Foundation section** — staging models used, join keys, base fields
3. **Added Fields section** — table with field name, derivation, why needed
4. **Intermediate Model Design section** — describe DBML, confirm no aggregation

### Phase 2 Checklist

- [ ] Both analytical questions written in report.md before SQL
- [ ] DBML drawn in `design.dbml` before SQL
- [ ] `int_race_laps.sql` created in `models/intermediate/`
- [ ] No `GROUP BY` in the intermediate model (weather aggregation is a sub-CTE, acceptable)
- [ ] `is_finished`, `is_wet_race`, `track_temp_category` fields present
- [ ] `dbt run` passes
- [ ] Row count matches stg_laps (no rows lost from bad joins)
- [ ] Report Phase 2 written in your own words

---

## Phase 3 — Star Model

**Weight: 40% | This is the most important phase.**

> Design DBML first. Run SQL second. The grain sentence must come before everything.

### Your Four Fact Tables

| Fact table | Analytical question | Grain |
|---|---|---|
| `fct_driver_pace_gap` | Q1 — Avg lap time gap vs winner | Each row = one driver in one race |
| `fct_driver_pace_gap_by_season` | Q1 — roll-up | Each row = one driver in one season at one circuit |
| `fct_pace_gap_by_condition` | Q2 — Gap by race condition | Each row = one driver in one race condition group |
| `fct_pace_gap_by_condition_season` | Q2 — roll-up | Each row = one driver in one condition group in one season |

### Your Dimensions

| Dimension | Key fields |
|---|---|
| `dim_driver` | `driver_number`, `driver_abbreviation`, `driver_full_name`, `team_name` |
| `dim_team` | `team_id`, `team_name` |
| `dim_circuit` | `circuit`, `country` (from schedule) |
| `dim_race` | `race_date`, `circuit`, `season`, `is_wet_race`, `track_temp_category` |
| `dim_condition` | `is_wet_race`, `track_temp_category` (combined condition label) |

### Metrics planning (document in report.md before coding)

**fct_driver_pace_gap — primary grain: driver × race**

| Metric | Source field | Operation | Justification |
|---|---|---|---|
| `avg_lap_time_s` | `lap_time_seconds` | AVG | Average pace of this driver in this race |
| `winner_avg_lap_time_s` | `lap_time_seconds` (winner's laps) | AVG | Reference pace for the race |
| `lap_time_gap_s` | derived | `avg_lap_time_s − winner_avg_lap_time_s` | The core metric: how far behind winner |
| `lap_count` | `lap_number` | COUNT | Context — fewer laps = less reliable average |

**fct_driver_pace_gap_by_season — roll-up grain: driver × circuit × season**

| Metric | Operation | Why roll-up adds value |
|---|---|---|
| `avg_lap_time_gap_s` | AVG of gaps across races | Shows seasonal trend at a circuit |
| `min_gap_s` | MIN | Best performance in the season |
| `max_gap_s` | MAX | Worst performance in the season |
| `race_count` | COUNT DISTINCT race_date | How many races in this aggregation |

**fct_pace_gap_by_condition — primary grain: driver × race × condition**

Same metrics as fct_driver_pace_gap but grouped with condition in the grain.

**fct_pace_gap_by_condition_season — roll-up: driver × condition × season**

Reveals whether wet/dry performance patterns persist across seasons.

### DBML — Star Model (add to design.dbml after the intermediate table)

```dbml
Table dim_driver {
  driver_key int [pk]
  driver_number varchar
  driver_abbreviation varchar
  driver_full_name varchar
  team_name varchar
  team_id varchar
}

Table dim_team {
  team_key int [pk]
  team_id varchar
  team_name varchar
}

Table dim_circuit {
  circuit_key int [pk]
  circuit varchar
  country varchar
  location varchar
}

Table dim_race {
  race_key int [pk]
  race_date date
  circuit varchar
  season int
  is_wet_race varchar
  track_temp_category varchar
}

Table dim_condition {
  condition_key int [pk]
  is_wet_race varchar
  track_temp_category varchar
  condition_label varchar
}

Table fct_driver_pace_gap {
  race_key int [ref: > dim_race.race_key]
  driver_key int [ref: > dim_driver.driver_key]
  avg_lap_time_s float
  winner_avg_lap_time_s float
  lap_time_gap_s float
  lap_count int
}

Table fct_driver_pace_gap_by_season {
  circuit_key int [ref: > dim_circuit.circuit_key]
  driver_key int [ref: > dim_driver.driver_key]
  season int
  avg_lap_time_gap_s float
  min_gap_s float
  max_gap_s float
  race_count int
}

Table fct_pace_gap_by_condition {
  race_key int [ref: > dim_race.race_key]
  driver_key int [ref: > dim_driver.driver_key]
  condition_key int [ref: > dim_condition.condition_key]
  avg_lap_time_s float
  winner_avg_lap_time_s float
  lap_time_gap_s float
  lap_count int
}

Table fct_pace_gap_by_condition_season {
  driver_key int [ref: > dim_driver.driver_key]
  condition_key int [ref: > dim_condition.condition_key]
  season int
  avg_lap_time_gap_s float
  race_count int
}
```

### Implementation

#### dim_driver.sql

```sql
-- models/mart/dim_driver.sql
WITH source AS (
    SELECT DISTINCT
        driver_number,
        driver_abbreviation,
        driver_full_name,
        team_name,
        team_id
    FROM {{ ref('int_race_laps') }}
    WHERE driver_number IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY driver_abbreviation) AS driver_key,
    driver_number,
    driver_abbreviation,
    driver_full_name,
    team_name,
    team_id
FROM source
```

#### dim_circuit.sql

```sql
-- models/mart/dim_circuit.sql
WITH source AS (
    SELECT DISTINCT
        circuit,
        country,
        location
    FROM {{ ref('stg_schedule') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY circuit) AS circuit_key,
    circuit,
    country,
    location
FROM source
```

#### dim_race.sql

```sql
-- models/mart/dim_race.sql
WITH source AS (
    SELECT DISTINCT
        race_date,
        circuit,
        season,
        is_wet_race,
        track_temp_category
    FROM {{ ref('int_race_laps') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY race_date, circuit) AS race_key,
    race_date,
    circuit,
    season,
    is_wet_race,
    track_temp_category
FROM source
```

#### dim_condition.sql

```sql
-- models/mart/dim_condition.sql
WITH source AS (
    SELECT DISTINCT
        is_wet_race,
        track_temp_category
    FROM {{ ref('int_race_laps') }}
    WHERE is_wet_race IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY is_wet_race, track_temp_category) AS condition_key,
    is_wet_race,
    track_temp_category,
    is_wet_race || ' / ' || track_temp_category AS condition_label
FROM source
```

#### fct_driver_pace_gap.sql

```sql
-- models/mart/fct_driver_pace_gap.sql
WITH base AS (
    SELECT *
    FROM {{ ref('int_race_laps') }}
    WHERE is_finished = true
),

-- Calculate avg lap time per driver per race
driver_avg AS (
    SELECT
        race_date,
        circuit,
        season,
        driver_number,
        driver_abbreviation,
        team_name,
        AVG(lap_time_seconds) AS avg_lap_time_s,
        COUNT(*)              AS lap_count
    FROM base
    GROUP BY race_date, circuit, season, driver_number, driver_abbreviation, team_name
),

-- Identify winner per race (finish_position = 1)
winner AS (
    SELECT
        race_date,
        AVG(lap_time_seconds) AS winner_avg_lap_time_s
    FROM base
    WHERE finish_position = 1
    GROUP BY race_date
),

final AS (
    SELECT
        d.race_date,
        d.circuit,
        d.season,
        d.driver_number,
        d.driver_abbreviation,
        d.team_name,
        d.avg_lap_time_s,
        w.winner_avg_lap_time_s,
        d.avg_lap_time_s - w.winner_avg_lap_time_s  AS lap_time_gap_s,
        d.lap_count
    FROM driver_avg d
    JOIN winner w ON d.race_date = w.race_date
)

SELECT
    dr.driver_key,
    rc.race_key,
    f.avg_lap_time_s,
    f.winner_avg_lap_time_s,
    f.lap_time_gap_s,
    f.lap_count
FROM final f
JOIN {{ ref('dim_driver') }} dr
    ON f.driver_number = dr.driver_number
JOIN {{ ref('dim_race') }} rc
    ON f.race_date = rc.race_date AND f.circuit = rc.circuit
```

#### fct_driver_pace_gap_by_season.sql

```sql
-- models/mart/fct_driver_pace_gap_by_season.sql
WITH base AS (
    SELECT
        race_date,
        circuit,
        season,
        driver_number,
        driver_abbreviation,
        team_name,
        lap_time_seconds
    FROM {{ ref('int_race_laps') }}
    WHERE is_finished = true
),

driver_avg AS (
    SELECT
        race_date,
        circuit,
        season,
        driver_number,
        AVG(lap_time_seconds) AS avg_lap_time_s
    FROM base
    GROUP BY race_date, circuit, season, driver_number
),

winner AS (
    SELECT
        race_date,
        AVG(lap_time_seconds) AS winner_avg_lap_time_s
    FROM base
    JOIN (
        SELECT DISTINCT race_date, driver_number
        FROM {{ ref('int_race_laps') }}
        WHERE finish_position = 1 AND is_finished = true
    ) w USING (race_date, driver_number)
    GROUP BY race_date
),

gaps AS (
    SELECT
        d.circuit,
        d.season,
        d.driver_number,
        d.avg_lap_time_s - w.winner_avg_lap_time_s AS gap_s,
        d.race_date
    FROM driver_avg d
    JOIN winner w ON d.race_date = w.race_date
)

SELECT
    dr.driver_key,
    ci.circuit_key,
    g.season,
    AVG(g.gap_s)                            AS avg_lap_time_gap_s,
    MIN(g.gap_s)                            AS min_gap_s,
    MAX(g.gap_s)                            AS max_gap_s,
    COUNT(DISTINCT g.race_date)             AS race_count
FROM gaps g
JOIN {{ ref('dim_driver') }} dr ON g.driver_number = dr.driver_number
JOIN {{ ref('dim_circuit') }} ci ON g.circuit = ci.circuit
GROUP BY dr.driver_key, ci.circuit_key, g.season
```

#### fct_pace_gap_by_condition.sql

```sql
-- models/mart/fct_pace_gap_by_condition.sql
WITH base AS (
    SELECT *
    FROM {{ ref('int_race_laps') }}
    WHERE is_finished = true
      AND is_wet_race IS NOT NULL
),

driver_avg AS (
    SELECT
        race_date,
        circuit,
        season,
        driver_number,
        is_wet_race,
        track_temp_category,
        AVG(lap_time_seconds) AS avg_lap_time_s,
        COUNT(*)              AS lap_count
    FROM base
    GROUP BY race_date, circuit, season, driver_number, is_wet_race, track_temp_category
),

winner AS (
    SELECT
        race_date,
        AVG(lap_time_seconds) AS winner_avg_lap_time_s
    FROM base
    WHERE finish_position = 1
    GROUP BY race_date
),

final AS (
    SELECT
        d.race_date,
        d.circuit,
        d.season,
        d.driver_number,
        d.is_wet_race,
        d.track_temp_category,
        d.avg_lap_time_s,
        w.winner_avg_lap_time_s,
        d.avg_lap_time_s - w.winner_avg_lap_time_s  AS lap_time_gap_s,
        d.lap_count
    FROM driver_avg d
    JOIN winner w ON d.race_date = w.race_date
)

SELECT
    dr.driver_key,
    rc.race_key,
    co.condition_key,
    f.avg_lap_time_s,
    f.winner_avg_lap_time_s,
    f.lap_time_gap_s,
    f.lap_count
FROM final f
JOIN {{ ref('dim_driver') }} dr ON f.driver_number = dr.driver_number
JOIN {{ ref('dim_race') }} rc ON f.race_date = rc.race_date AND f.circuit = rc.circuit
JOIN {{ ref('dim_condition') }} co
    ON f.is_wet_race = co.is_wet_race
    AND f.track_temp_category = co.track_temp_category
```

#### fct_pace_gap_by_condition_season.sql

```sql
-- models/mart/fct_pace_gap_by_condition_season.sql
WITH base AS (
    SELECT *
    FROM {{ ref('int_race_laps') }}
    WHERE is_finished = true
      AND is_wet_race IS NOT NULL
),

driver_avg AS (
    SELECT
        race_date,
        season,
        driver_number,
        is_wet_race,
        track_temp_category,
        AVG(lap_time_seconds) AS avg_lap_time_s
    FROM base
    GROUP BY race_date, season, driver_number, is_wet_race, track_temp_category
),

winner AS (
    SELECT
        race_date,
        AVG(lap_time_seconds) AS winner_avg_lap_time_s
    FROM base
    WHERE finish_position = 1
    GROUP BY race_date
),

gaps AS (
    SELECT
        d.season,
        d.driver_number,
        d.is_wet_race,
        d.track_temp_category,
        d.avg_lap_time_s - w.winner_avg_lap_time_s AS gap_s,
        d.race_date
    FROM driver_avg d
    JOIN winner w ON d.race_date = w.race_date
)

SELECT
    dr.driver_key,
    co.condition_key,
    g.season,
    AVG(g.gap_s)                        AS avg_lap_time_gap_s,
    COUNT(DISTINCT g.race_date)         AS race_count
FROM gaps g
JOIN {{ ref('dim_driver') }} dr ON g.driver_number = dr.driver_number
JOIN {{ ref('dim_condition') }} co
    ON g.is_wet_race = co.is_wet_race
    AND g.track_temp_category = co.track_temp_category
GROUP BY dr.driver_key, co.condition_key, g.season
```

### Run and verify

```bash
dbt run
dbt test
```

Check in DBCode:
```sql
-- Q1 primary grain: one row per driver per race
SELECT race_key, driver_key, COUNT(*) FROM fct_driver_pace_gap GROUP BY 1,2 HAVING COUNT(*) > 1;
-- Should return 0 rows

-- Winner gap should be 0 for the winner
SELECT * FROM fct_driver_pace_gap WHERE lap_time_gap_s < -0.01;
-- Should return 0 rows

-- Check condition coverage
SELECT DISTINCT condition_label FROM dim_condition ORDER BY 1;
```

### Phase 3 Checklist

- [ ] 4 fact table grain sentences written in report.md before SQL
- [ ] Metrics table completed in report.md for each fact table
- [ ] DBML extended with full star model (in `design.dbml`)
- [ ] `dim_driver.sql`, `dim_circuit.sql`, `dim_race.sql`, `dim_condition.sql` created
- [ ] `fct_driver_pace_gap.sql` — primary grain Q1
- [ ] `fct_driver_pace_gap_by_season.sql` — roll-up Q1
- [ ] `fct_pace_gap_by_condition.sql` — primary grain Q2
- [ ] `fct_pace_gap_by_condition_season.sql` — roll-up Q2
- [ ] Mart models materialized as `table` in dbt_project.yml
- [ ] No staging models referenced directly from mart (only `int_` or other `mart_`)
- [ ] `dbt run` passes
- [ ] Row count confirms grain (no duplicates per grain combination)
- [ ] Report Phase 3 written in your own words

---

## Phase 4 — Dashboard

**Weight: 15% | Goal: prove your models work and answer the stakeholder's questions**

> All logic lives in dbt. Metabase is for display only.

### Connect Metabase to your database

1. Open Metabase (runs locally — see Brightspace → Getting Started → Metabase Setup Guide)
2. Add database: DuckDB
3. Path to database: the absolute path to `exam-case/f1.duckdb` on your machine
4. Confirm tables appear: `fct_driver_pace_gap`, `fct_driver_pace_gap_by_season`, etc.

### What your dashboard must show

| Requirement | How to satisfy it |
|---|---|
| Primary grain Q1 | Chart from `fct_driver_pace_gap` — x-axis: race/circuit, y-axis: lap_time_gap_s, grouped by driver or team |
| Roll-up grain Q1 | Chart from `fct_driver_pace_gap_by_season` — x-axis: season, y-axis: avg_lap_time_gap_s |
| Primary grain Q2 | Chart from `fct_pace_gap_by_condition` — grouped by condition_label |
| Roll-up grain Q2 | Chart from `fct_pace_gap_by_condition_season` — trend by season and condition |
| Filter by team | Connect to `team_name` in `dim_driver` (join through fact table) |
| Filter by circuit | Connect to `circuit` in `dim_circuit` or `dim_race` |
| Multiple metrics per Q | Show `lap_time_gap_s` AND `lap_count` (at minimum) in each question |
| One insight | Write a sentence: "Driver X at circuit Y shows gap of Z seconds in wet conditions..." |

### Suggested chart types

| Chart | Recommended type |
|---|---|
| Gap per driver per race | Bar chart (grouped by driver, faceted by circuit) |
| Seasonal trend | Line chart (x = season, y = avg gap, color = driver/team) |
| Condition comparison | Grouped bar (x = condition label, y = avg gap, color = driver) |
| Condition × season | Line chart (x = season, color = condition label) |
| KPI card | Show single number: avg gap for selected team/circuit |

### Filters

In Metabase dashboard edit mode:
1. Add a **Text / Category** filter for **Team**
2. Add a **Text / Category** filter for **Circuit**
3. Click each chart card → map the filter to the correct column
4. Test: select a team, verify all charts update

### Dashboard report section (in report.md)

Write at least these three things:

1. **Grain effect on interpretation** — e.g. "The primary grain shows race-by-race variation, revealing outlier performances. The season roll-up smooths this and shows whether performance is improving."

2. **Stakeholder insight from each view** — e.g. "The condition view shows that Team X's gap to the winner is 0.3s larger in wet conditions, suggesting a setup weakness in the rain."

3. **One specific insight** — name a driver, team, circuit, or season with a concrete finding.

### Export

1. Export dashboard as PDF: Metabase → Dashboard → Export → PDF
2. Screen recording (2–5 min):
   - Show dashboard loading from fact tables
   - Apply team filter → show charts updating
   - Apply circuit filter → show charts updating
   - Switch between primary and roll-up grain view
   - Explain one insight out loud (or in text on screen)

### Phase 4 Checklist

- [ ] Metabase connected to f1.duckdb
- [ ] Charts use fact tables only (not raw or staging)
- [ ] Q1 primary grain chart present
- [ ] Q1 roll-up grain chart present
- [ ] Q2 primary grain chart present
- [ ] Q2 roll-up grain chart present
- [ ] Team filter working (updates all relevant charts)
- [ ] Circuit filter working (updates all relevant charts)
- [ ] Multiple metrics shown per question (gap + count at minimum)
- [ ] Report explains grain effect and one specific insight
- [ ] Dashboard PDF exported without cut-off charts
- [ ] Screen recording shows filtering and both grain levels

---

## report.md — Completion Guide

Fill in each section in your own words. The rubric explicitly states that AI-generated text without evidence of personal understanding is insufficient. Write as if explaining to a classmate.

| Section | What to write |
|---|---|
| Name / Class / Teacher | Your info |
| Phase 0 | 3–5 sentences: tables created, filename derivation, no cleaning applied |
| Phase 1 | What you renamed, what types you fixed, what tests you added and why |
| Phase 2 — Analytical Questions | State Q1 and Q2, justify why Q2 meets requirements |
| Phase 2 — Foundation | Which staging models, join keys, base fields, what one row represents |
| Phase 2 — Added Fields | Table: field name, derivation, why needed for Q1/Q2 |
| Phase 2 — Intermediate Design | Describe the DBML, confirm no aggregation |
| Phase 3 — Grain sentences | 4 "each row represents" sentences, one per fact table |
| Phase 3 — Metrics tables | 4 tables: metric, source, operation, justification |
| Phase 3 — Star Model Design | Describe dimensions, fact tables, reuse strategy |
| Phase 4 | Grain effect, insight per view, one specific finding |
| Use of Generative AI | APA-format account of how AI was used |

---

## Common Mistakes to Avoid

| Mistake | Why it hurts your grade |
|---|---|
| Filtering `Status = "Finished"` in staging | Business logic belongs in intermediate, not staging |
| Aggregating in the intermediate model | The model must stay at lap-level grain |
| Mart models that `ref()` staging directly | Layer discipline violation — always go through intermediate |
| DBML drawn after SQL | Rubric treats this as Insufficient for design criterion |
| Missing `COUNT` in fact tables | Averages without volume context can mislead |
| Winner identified by `Position = 1` in laps | The winner's position comes from `session_results`, not laps |
| Only one grain per question | You need 4 fact tables total — 2 per question |
| Screen recording not submitted | Phase 4 capped at Poor (4/15) without it |

---

## Quick Command Reference

```bash
# Inside the dev container at /adm-workspace/exam-case

# Load raw data
cd load && python load.py && cd ..

# Run all dbt models
dbt run

# Run tests
dbt test

# Run specific model only
dbt run --select stg_laps
dbt run --select int_race_laps
dbt run --select fct_driver_pace_gap

# View docs
dbt docs generate
dbt docs serve --port 8888
# then open http://localhost:8888
```

---

## File Delivery Summary

When done, your `exam-case/` folder should contain:

```
exam-case/
├── load/
│   └── load.py                          ← Phase 0 ✓
├── models/
│   ├── staging/
│   │   ├── sources.yml                  ← Phase 1 ✓
│   │   ├── schema.yml                   ← Phase 1 ✓
│   │   ├── stg_laps.sql                 ← Phase 1 ✓
│   │   ├── stg_session_results.sql      ← Phase 1 ✓
│   │   ├── stg_weather.sql              ← Phase 1 ✓
│   │   └── stg_schedule.sql             ← Phase 1 ✓
│   ├── intermediate/
│   │   └── int_race_laps.sql            ← Phase 2 ✓
│   └── mart/
│       ├── dim_driver.sql               ← Phase 3 ✓
│       ├── dim_circuit.sql              ← Phase 3 ✓
│       ├── dim_race.sql                 ← Phase 3 ✓
│       ├── dim_condition.sql            ← Phase 3 ✓
│       ├── fct_driver_pace_gap.sql      ← Phase 3 ✓
│       ├── fct_driver_pace_gap_by_season.sql    ← Phase 3 ✓
│       ├── fct_pace_gap_by_condition.sql        ← Phase 3 ✓
│       └── fct_pace_gap_by_condition_season.sql ← Phase 3 ✓
├── design.dbml                          ← Phases 2 + 3 ✓
├── report.md                            ← All phases ✓
├── dbt_project.yml
└── profiles.yml
```
