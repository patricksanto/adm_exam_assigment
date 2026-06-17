WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_schedule') }}
),

cleaned AS (
    SELECT
        CAST("Year" AS INTEGER)          AS season,
        CAST("RoundNumber" AS INTEGER)   AS round_number,
        "Country"                        AS country,
        "Location"                       AS location,
        "EventName"                      AS circuit,
        CAST("EventDate" AS DATE)        AS event_date,
        "OfficialEventName"              AS official_event_name,
        CAST("TotalLaps" AS INTEGER)     AS total_laps
    FROM source
)

SELECT * FROM cleaned
