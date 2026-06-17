-- Q2 primary grain: one driver in one race, with condition context
-- Same grain as fct_driver_pace_gap but joined to dim_condition

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
        circuit,
        season,
        driver_number,
        is_wet_race,
        track_temp_category,
        AVG(lap_time_seconds) AS avg_lap_time_s,
        COUNT(*)              AS lap_count
    FROM finished
    GROUP BY race_date, circuit, season, driver_number, is_wet_race, track_temp_category
),

final AS (
    SELECT
        d.race_date,
        d.circuit,
        d.driver_number,
        d.is_wet_race,
        d.track_temp_category,
        d.avg_lap_time_s,
        w.winner_avg_lap_time_s,
        d.avg_lap_time_s - w.winner_avg_lap_time_s AS lap_time_gap_s,
        d.lap_count
    FROM driver_laps d
    JOIN winner_laps w ON d.race_date = w.race_date
)

SELECT
    r.race_key,
    d.driver_key,
    co.condition_key,
    f.avg_lap_time_s,
    f.winner_avg_lap_time_s,
    f.lap_time_gap_s,
    f.lap_count
FROM final f
JOIN {{ ref('dim_driver') }}    d  ON f.driver_number     = d.driver_number
JOIN {{ ref('dim_race') }}      r  ON f.race_date         = r.race_date AND f.circuit = r.circuit
JOIN {{ ref('dim_condition') }} co ON f.is_wet_race       = co.is_wet_race
                                  AND f.track_temp_category = co.track_temp_category
