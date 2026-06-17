WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_laps') }}
    WHERE "LapTime" IS NOT NULL
      AND "LapTime" != 'nan'
      AND "IsAccurate" = 'True'
),

cleaned AS (
    SELECT
        CAST(race_date AS DATE)                                     AS race_date,
        circuit,
        CAST(season AS INTEGER)                                     AS season,
        "Driver"                                                    AS driver_abbreviation,
        CAST(CAST("DriverNumber" AS FLOAT) AS INTEGER)::VARCHAR     AS driver_number,
        "Team"                                                      AS team_name,
        CAST(CAST("LapNumber" AS FLOAT) AS INTEGER)                 AS lap_number,
        CAST(CAST("Position" AS FLOAT) AS INTEGER)                  AS position,
        "Compound"                                                  AS tyre_compound,
        CAST("TyreLife" AS INTEGER)                                 AS tyre_life,
        CAST("FreshTyre" AS BOOLEAN)                                AS fresh_tyre,
        CAST("IsPersonalBest" AS BOOLEAN)                           AS is_personal_best,
        -- Convert "0 days HH:MM:SS.ffffff" to total seconds
        (
            CAST(SPLIT_PART(SPLIT_PART("LapTime", ' ', 3), ':', 1) AS FLOAT) * 3600
          + CAST(SPLIT_PART(SPLIT_PART("LapTime", ' ', 3), ':', 2) AS FLOAT) * 60
          + CAST(SPLIT_PART(SPLIT_PART("LapTime", ' ', 3), ':', 3) AS FLOAT)
        )                                                           AS lap_time_seconds,
        "TrackStatus"                                               AS track_status,
        source_file
    FROM source
)

SELECT * FROM cleaned
