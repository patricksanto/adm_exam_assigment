# Metabase Dashboard Setup Guide
## F1 Competitiveness Analysis — Phase 4

> Create 2 dashboards, one per analytical question. Follow the bus example pattern.
> All questions use **Native SQL** mode in Metabase.

---

## Dashboard 1 — Q1: Driver Pace Gap
**New → Dashboard → name:** `F1 - Driver Pace Gap`

---

### Card 1 — Line chart: primary grain (one driver per race)

```sql
SELECT
    r.race_date,
    r.circuit,
    d.driver_abbreviation,
    d.team_name,
    f.lap_time_gap_s,
    f.lap_count
FROM fct_driver_pace_gap f
JOIN dim_driver d ON f.driver_key = d.driver_key
JOIN dim_race   r ON f.race_key   = r.race_key
ORDER BY r.race_date
```

- Visualization: **Line chart**
- X = `race_date` · Y = `lap_time_gap_s` · Series = `driver_abbreviation`
- Title: `Pace Gap per Driver per Race (primary grain)`

---

### Card 2 — Line chart: roll-up (one driver per circuit per season)

```sql
SELECT
    s.season,
    c.circuit,
    d.driver_abbreviation,
    d.team_name,
    s.avg_lap_time_gap_s,
    s.race_count
FROM fct_driver_pace_gap_by_season s
JOIN dim_driver  d ON s.driver_key  = d.driver_key
JOIN dim_circuit c ON s.circuit_key = c.circuit_key
ORDER BY s.season
```

- Visualization: **Line chart**
- X = `season` · Y = `avg_lap_time_gap_s` · Series = `driver_abbreviation`
- Title: `Avg Pace Gap by Season & Circuit (roll-up)`

---

### Card 3 — Bar chart: total laps per driver (context)

```sql
SELECT
    d.driver_abbreviation,
    d.team_name,
    SUM(f.lap_count) AS total_laps
FROM fct_driver_pace_gap f
JOIN dim_driver d ON f.driver_key = d.driver_key
GROUP BY d.driver_abbreviation, d.team_name
ORDER BY total_laps DESC
```

- Visualization: **Bar chart**
- X = `driver_abbreviation` · Y = `total_laps`
- Title: `Total Laps Counted per Driver`

---

### Card 4 — Table: largest gaps to winner

```sql
SELECT
    d.driver_abbreviation,
    d.team_name,
    r.race_date,
    r.circuit,
    ROUND(f.lap_time_gap_s, 3) AS lap_time_gap_s,
    f.lap_count
FROM fct_driver_pace_gap f
JOIN dim_driver d ON f.driver_key = d.driver_key
JOIN dim_race   r ON f.race_key   = r.race_key
ORDER BY f.lap_time_gap_s DESC
LIMIT 20
```

- Visualization: **Table**
- Title: `Largest Gaps to Winner`

---

### Filters — Dashboard 1

After adding all 4 cards: **Edit → Add a filter**

| Filter | Type | Connect to column |
|---|---|---|
| Team | Text / Category | `team_name` in all cards |
| Circuit | Text / Category | `circuit` in cards 1, 2, 4 |

---

## Dashboard 2 — Q2: Pace Gap by Race Condition
**New → Dashboard → name:** `F1 - Pace Gap by Race Condition`

---

### Card 1 — Bar chart: primary grain (driver × race condition)

```sql
SELECT
    co.condition_label,
    d.driver_abbreviation,
    d.team_name,
    ROUND(AVG(f.lap_time_gap_s), 3) AS avg_gap_s,
    SUM(f.lap_count) AS total_laps
FROM fct_pace_gap_by_condition f
JOIN dim_driver    d  ON f.driver_key    = d.driver_key
JOIN dim_condition co ON f.condition_key = co.condition_key
GROUP BY co.condition_label, d.driver_abbreviation, d.team_name
ORDER BY co.condition_label, avg_gap_s
```

- Visualization: **Bar chart**
- X = `condition_label` · Y = `avg_gap_s` · Series = `driver_abbreviation`
- Title: `Avg Pace Gap by Race Condition (primary grain)`

---

### Card 2 — Line chart: roll-up (driver × condition × season)

```sql
SELECT
    s.season,
    co.condition_label,
    d.driver_abbreviation,
    d.team_name,
    ROUND(s.avg_lap_time_gap_s, 3) AS avg_gap_s,
    s.race_count
FROM fct_pace_gap_by_condition_season s
JOIN dim_driver    d  ON s.driver_key    = d.driver_key
JOIN dim_condition co ON s.condition_key = co.condition_key
ORDER BY s.season, co.condition_label
```

- Visualization: **Line chart**
- X = `season` · Y = `avg_gap_s` · Series = `condition_label`
- Title: `Pace Gap by Condition per Season (roll-up)`

---

### Card 3 — Bar chart: race count per condition (context)

```sql
SELECT
    co.condition_label,
    SUM(s.race_count) AS total_races
FROM fct_pace_gap_by_condition_season s
JOIN dim_condition co ON s.condition_key = co.condition_key
GROUP BY co.condition_label
ORDER BY total_races DESC
```

- Visualization: **Bar chart**
- X = `condition_label` · Y = `total_races`
- Title: `Race Count per Condition (context)`

---

### Filters — Dashboard 2

| Filter | Type | Connect to column |
|---|---|---|
| Team | Text / Category | `team_name` in cards 1 and 2 |
| Circuit | Text / Category | add `r.circuit` to card 1 query and connect |

---

## Tips

- Use **Native SQL** for all questions (gives full control over joins)
- If Metabase shows `database is locked` → close DBCode connection to `f1.duckdb` first
- If numeric keys like `condition_key` show as `1,234` → format column as plain number in Metabase column settings
- The **roll-up chart** should always sit next to the **primary grain chart** so the viewer can compare both levels
