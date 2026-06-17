WITH source AS (
    SELECT DISTINCT
        is_wet_race,
        track_temp_category
    FROM {{ ref('int_race_laps') }}
    WHERE is_wet_race IS NOT NULL
      AND track_temp_category IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY is_wet_race, track_temp_category) AS condition_key,
    is_wet_race,
    track_temp_category,
    is_wet_race || ' / ' || track_temp_category AS condition_label
FROM source
