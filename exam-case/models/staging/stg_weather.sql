WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_weather') }}
),

cleaned AS (
    SELECT
        CAST(race_date AS DATE)          AS race_date,
        circuit,
        CAST(season AS INTEGER)          AS season,
        "Time"                           AS session_time_offset,
        CAST("AirTemp" AS FLOAT)         AS air_temp_c,
        CAST("Humidity" AS FLOAT)        AS humidity_pct,
        CAST("Pressure" AS FLOAT)        AS pressure_hpa,
        CAST("Rainfall" AS BOOLEAN)      AS is_raining,
        CAST("TrackTemp" AS FLOAT)       AS track_temp_c,
        CAST("WindDirection" AS INTEGER) AS wind_direction_deg,
        CAST("WindSpeed" AS FLOAT)       AS wind_speed_ms,
        source_file
    FROM source
)

SELECT * FROM cleaned
