-- Q1 roll-up grain: one driver at one circuit in one season
-- Summarises per-race gaps to reveal seasonal trends

WITH finished AS (
    SELECT *
    FROM {{ ref('int_race_laps') }}
    WHERE is_finished = true
),

winner_laps AS (
    SELECT
        race_date,
        AVG(lap_time_seconds) AS winner_avg_lap_time_s
    FROM finished
    WHERE finish_position = 1
    GROUP BY race_date
),

driver_laps AS (
    SELECT
        race_date,
        circuit,
        season,
        driver_number,
        AVG(lap_time_seconds) AS avg_lap_time_s
    FROM finished
    GROUP BY race_date, circuit, season, driver_number
),

gaps AS (
    SELECT
        d.circuit,
        d.season,
        d.driver_number,
        d.race_date,
        d.avg_lap_time_s - w.winner_avg_lap_time_s AS gap_s
    FROM driver_laps d
    JOIN winner_laps w ON d.race_date = w.race_date
)

SELECT
    d.driver_key,
    c.circuit_key,
    g.season,
    AVG(g.gap_s)                   AS avg_lap_time_gap_s,
    MIN(g.gap_s)                   AS min_gap_s,
    MAX(g.gap_s)                   AS max_gap_s,
    COUNT(DISTINCT g.race_date)    AS race_count
FROM gaps g
JOIN {{ ref('dim_driver') }}  d ON g.driver_number = d.driver_number
JOIN {{ ref('dim_circuit') }} c ON g.circuit = c.circuit
GROUP BY d.driver_key, c.circuit_key, g.season
