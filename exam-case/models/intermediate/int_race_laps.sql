WITH laps AS (
    SELECT * FROM {{ ref('stg_laps') }}
),

results AS (
    SELECT
        race_date,
        driver_number,
        driver_full_name,
        team_name,
        team_id,
        finish_position,
        classified_position,
        race_status,
        race_status = 'Finished' AS is_finished
    FROM {{ ref('stg_session_results') }}
),

-- Aggregate weather to one representative row per race
weather_per_race AS (
    SELECT
        race_date,
        AVG(track_temp_c)                        AS avg_track_temp_c,
        MAX(CAST(is_raining AS INTEGER)) = 1     AS any_rain
    FROM {{ ref('stg_weather') }}
    GROUP BY race_date
),

weather_enriched AS (
    SELECT
        race_date,
        avg_track_temp_c,
        CASE WHEN any_rain THEN 'wet' ELSE 'dry' END AS is_wet_race,
        CASE
            WHEN avg_track_temp_c < 30  THEN 'cool'
            WHEN avg_track_temp_c < 45  THEN 'warm'
            ELSE 'hot'
        END AS track_temp_category
    FROM weather_per_race
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
        w.avg_track_temp_c,
        w.track_temp_category
    FROM laps l
    LEFT JOIN results r
        ON  l.race_date     = r.race_date
        AND l.driver_number = r.driver_number
    LEFT JOIN weather_enriched w
        ON l.race_date = w.race_date
)

SELECT * FROM final
