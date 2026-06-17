-- Q2 roll-up grain: one driver in one condition group in one season
-- Reveals whether wet/dry performance patterns are consistent across seasons

WITH finished AS (
    SELECT *
    FROM {{ ref('int_race_laps') }}
    WHERE is_finished = true
      AND is_wet_race IS NOT NULL
      AND track_temp_category IS NOT NULL
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
        season,
        driver_number,
        is_wet_race,
        track_temp_category,
        AVG(lap_time_seconds) AS avg_lap_time_s
    FROM finished
    GROUP BY race_date, season, driver_number, is_wet_race, track_temp_category
),

gaps AS (
    SELECT
        d.season,
        d.driver_number,
        d.is_wet_race,
        d.track_temp_category,
        d.race_date,
        d.avg_lap_time_s - w.winner_avg_lap_time_s AS gap_s
    FROM driver_laps d
    JOIN winner_laps w ON d.race_date = w.race_date
)

SELECT
    d.driver_key,
    co.condition_key,
    g.season,
    AVG(g.gap_s)                AS avg_lap_time_gap_s,
    COUNT(DISTINCT g.race_date) AS race_count
FROM gaps g
JOIN {{ ref('dim_driver') }}    d  ON g.driver_number      = d.driver_number
JOIN {{ ref('dim_condition') }} co ON g.is_wet_race         = co.is_wet_race
                                  AND g.track_temp_category  = co.track_temp_category
GROUP BY d.driver_key, co.condition_key, g.season
