WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_session_results') }}
),

cleaned AS (
    SELECT
        CAST(race_date AS DATE)             AS race_date,
        circuit,
        CAST(season AS INTEGER)             AS season,
        "DriverNumber"                      AS driver_number,
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
