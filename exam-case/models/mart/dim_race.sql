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
