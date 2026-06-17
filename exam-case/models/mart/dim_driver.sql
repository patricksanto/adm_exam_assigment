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
