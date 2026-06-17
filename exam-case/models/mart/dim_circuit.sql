WITH source AS (
    SELECT DISTINCT
        circuit,
        country,
        location
    FROM {{ ref('stg_schedule') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY circuit) AS circuit_key,
    circuit,
    country,
    location
FROM source
