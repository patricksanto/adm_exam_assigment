# Advanced Data Management — Exam Case Instructions

This file compiles the main ideas from the **Advanced Data Management** lessons in a practical format to use in your exam case.

Main pipeline:

```text
Load → Staging → Intermediate Model → Star Model → Dashboard
```

The general logic of the course is ELT:

- **Extract / Load first**: place the raw data inside DuckDB.
- **Transform later**: perform cleaning, standardization, joins, calculations, aggregations, and analytical models inside dbt.
- **Display last**: use Metabase only to visualize what has already been prepared in dbt.

> Central rule: the more important the business logic is, the more it should live in dbt, not in loose scripts or in the dashboard.

---

## 0. Overview of the phases

| Phase | Tool | Objective | Expected result |
|---|---|---|---|
| Phase 0 — Load | Python + pandas + DuckDB | Read raw files and load them into the database | Raw tables in DuckDB |
| Phase 1 — Staging | dbt | Clean, rename, fix types, and validate data | Reliable `stg_` models |
| Phase 2 — Intermediate Model | dbt | Join sources, add calculated and categorical fields | `int_` model without aggregation |
| Phase 3 — Star Model | dbt | Create dimensions and aggregated facts with a defined grain | `dim_` and `fct_` models |
| Phase 4 — Dashboard | Metabase | Visualize the facts and prove that they answer the questions | Exported dashboard + explanation |

---

# Phase 0 — Load

## Objective of the phase

Load the original files into DuckDB **exactly as they arrive from the source**.

In this phase, you should avoid:

- cleaning data;
- renaming columns;
- fixing data types;
- applying business rules;
- creating aggregations;
- removing rows based on analytical decisions.

These decisions belong in dbt, mainly in the staging phase.

## What can be done in Load

You can do only what is necessary to load the data:

- read CSV, JSON, or TXT files with pandas;
- identify separators such as `,`, `|`, `;`, or `\t`;
- use `decimal=","` when numbers use a comma as decimal separator;
- combine files of the same type into one logical table;
- add contextual columns derived from the filename when that information only exists in the filename.

Example of context derived from the filename:

```text
race_2024_monaco_practice.csv
```

This may generate columns such as:

```text
year = 2024
circuit = monaco
session_type = practice
```

This is not considered an analytical transformation because you are preserving information that was encoded in the filename.

## Mental structure

```text
raw files → pandas DataFrames → DuckDB raw tables
```

## Reading files

### CSV

```python
import pandas as pd

df = pd.read_csv("path/to/file.csv")
```

With a specific separator:

```python
df = pd.read_csv("path/to/file.csv", sep="|")
```

With decimal comma:

```python
df = pd.read_csv("path/to/file.csv", sep="|", decimal=",")
```

### JSON

```python
import json
import pandas as pd

with open("path/to/file.json", "r", encoding="utf-8") as f:
    raw = json.load(f)

df = pd.json_normalize(raw)
```

### TXT

A TXT file can be read like a CSV file as long as you know the separator.

```python
df = pd.read_csv("path/to/file.txt", sep="\t")
```

or:

```python
df = pd.read_csv("path/to/file.txt", sep="|")
```

Before loading a TXT file, open it in VS Code to identify the delimiter.

## Loading multiple files

```python
from pathlib import Path
import pandas as pd

folder = Path("raw/some-folder")
files = sorted(folder.glob("*.csv"))

frames = []

for file in files:
    df = pd.read_csv(file, sep="|")
    df["source_file"] = file.name
    frames.append(df)

combined = pd.concat(frames, ignore_index=True)
```

## Writing to DuckDB

```python
import duckdb

con = duckdb.connect("db/exam.duckdb")
con.execute("CREATE OR REPLACE TABLE raw_table_name AS SELECT * FROM combined")
con.close()
```

Important note: when you use DuckDB with pandas, the name used in the SQL must be the real name of the Python variable in memory.

```python
con.execute("CREATE OR REPLACE TABLE drivers AS SELECT * FROM drivers_df")
```

In this example, `drivers_df` must exist in the Python script.

## Minimum verification after Load

Create simple queries to check whether the tables exist and whether the data was loaded.

```sql
ATTACH 'db/exam.duckdb' AS examdb;
USE examdb;

SELECT COUNT(*) FROM raw_table_name;
SELECT * FROM raw_table_name LIMIT 10;
```

## Load phase checklist

- [ ] All required files were read.
- [ ] Similar files were combined into logical tables.
- [ ] Columns derived from filenames were added when necessary.
- [ ] No analytical cleaning was done in Python.
- [ ] Raw tables were created in DuckDB.
- [ ] Simple queries confirm row counts and first rows.
- [ ] The script can be run again without breaking.

---

# Phase 1 — Staging

## Objective of the phase

Transform raw data into technically reliable data.

The main question of the phase is:

```text
Is the data clean, standardized, and reliable enough to be used in the next phases?
```

Staging is not yet the place to answer analytical questions. It is the place to prepare the ingredients.

## What belongs in Staging

Common activities:

- remove redundant or unnecessary columns;
- rename columns to readable names;
- use lowercase;
- avoid spaces, special characters, and reserved words;
- fix data types;
- convert strings into numbers, dates, or timestamps;
- standardize abbreviated values;
- handle technical date and time issues;
- filter invalid rows when they are not useful for the question;
- document fields in `schema.yml`;
- create data quality tests with dbt.

Examples:

```text
S → southbound
N → northbound
COMPL → completed
CANC → cancelled
"42" → 42
"2024-05-01" → date
```

## What does not belong in Staging

Avoid the following in this phase:

- joins between business tables;
- analytical calculations such as revenue, delay_minutes, or score;
- analytical categories such as high/medium/low;
- aggregations;
- `GROUP BY`;
- metrics such as AVG, SUM, MAX, STDDEV, or COUNT.

Important boundary example:

```text
quantity and unit_price can be converted to numbers in staging.
revenue = quantity × unit_price belongs in the intermediate model.
```

## Naming convention

Staging models usually live in:

```text
models/staging/
```

And use the prefix:

```text
stg_source_name.sql
```

Examples:

```text
models/staging/stg_arrival_times.sql
models/staging/stg_drivers.sql
models/staging/stg_races.sql
```

## Referencing raw tables with `source`

In dbt, use `source()` to make the lineage clear.

```sql
SELECT
    column_a,
    column_b
FROM {{ source('raw', 'table_name') }}
```

Sources should be defined in a YAML file, usually something like:

```text
models/staging/sources.yml
```

Example:

```yaml
version: 2

sources:
  - name: raw
    tables:
      - name: drivers
      - name: races
```

## Example staging model

```sql
WITH source AS (
    SELECT *
    FROM {{ source('raw', 'arrival_times') }}
),

renamed AS (
    SELECT
        route AS route,
        CASE
            WHEN direction = 'N' THEN 'northbound'
            WHEN direction = 'S' THEN 'southbound'
            ELSE direction
        END AS direction,
        CAST(arrival_date AS DATE) AS arrival_date,
        CAST(scheduled AS TIMESTAMP) AS scheduled,
        CAST(actual AS TIMESTAMP) AS actual
    FROM source
)

SELECT *
FROM renamed
```

## Tests and documentation

Use `schema.yml` to document models, columns, and tests.

Example:

```yaml
version: 2

models:
  - name: stg_arrival_times
    description: "Cleaned arrival times from the raw source."
    columns:
      - name: route
        description: "Bus route number."
        tests:
          - not_null

      - name: direction
        description: "Readable bus direction."
        tests:
          - not_null
          - accepted_values:
              values: ['northbound', 'southbound']
```

Common tests:

- `not_null`;
- `unique`;
- `accepted_values`;
- custom SQL tests.

## Custom tests

Custom tests live in the folder:

```text
tests/
```

A SQL test should return the rows that failed.

Example:

```sql
-- tests/test_no_negative_quantity.sql

SELECT *
FROM {{ ref('stg_order_items') }}
WHERE quantity <= 0
```

Run tests:

```bash
dbt test
```

Run models:

```bash
dbt run
```

Common flow:

```bash
dbt run
# then
dbt test
```

## Materialization in Staging

Staging should usually be materialized as a **view**.

Reason:

- simple transformations;
- always updates with source data;
- no need to persist a physical result in this phase.

Typical configuration in `dbt_project.yml`:

```yaml
models:
  project_name:
    staging:
      +materialized: view
```

## Staging phase checklist

- [ ] Each important raw source has a `stg_` model.
- [ ] Columns were renamed to clear names.
- [ ] Data types were fixed.
- [ ] Technical values were standardized.
- [ ] Invalid data was handled with justification.
- [ ] There are no analytical joins.
- [ ] There are no business calculations.
- [ ] There is no aggregation.
- [ ] `schema.yml` documents models and columns.
- [ ] dbt tests were created.
- [ ] `dbt run` works.
- [ ] `dbt test` passes or failures are justified.

---

# Phase 2 — Intermediate Model

## Objective of the phase

Create the analytical foundation before any grouping.

The main question is:

```text
What should the analytical base look like before any GROUP BY?
```

The intermediate model is not the final answer. It is the clean and enriched base that will be used to build the star model.

## Main rule

```text
No GROUP BY. No aggregation. Every row still represents one event.
```

In other words:

- if each row in staging represents one bus arrival, each row in intermediate still represents one bus arrival;
- if each row represents one participation, enrolment, race, order, or transaction, it continues to represent that;
- you can enrich the row, but you cannot group several rows into one.

## Why not query staging directly

Querying staging directly creates problems:

- calculations are repeated in every query;
- each analyst defines categories differently;
- joins are repeated in multiple places;
- business rules become scattered;
- maintenance becomes difficult;
- trust in results decreases.

The intermediate model solves this because:

- derived fields are calculated once;
- categories are defined in one place;
- joins are done once;
- logic is documented and testable;
- downstream models become cleaner.

## Three-step planning

### 1. Foundation

Questions:

- Which `stg_` models are needed?
- How do they connect?
- What is the join key?
- Which base fields should move forward?
- What does one row mean?

Example:

```text
stg_arrival_times
one row per individual bus arrival
```

### 2. Added Fields

Define which fields need to be added.

There are two main types:

#### Calculated fields

Numeric fields derived from other fields.

Examples:

```text
delay_minutes = actual - scheduled
revenue = quantity × unit_price
```

They become the basis for the metrics in the star model phase.

#### Categorical fields

Labels created from existing values.

Examples:

```text
delay_category = early / on_time / slight / moderate / severe
time_category = morning / midday / afternoon / night
quantity_category = small / medium / large
```

They help filter and group in the dashboard without creating logic outside dbt.

### 3. DBML Diagram

Before writing SQL, draw the model in DBML.

Objective:

- define base fields;
- define added fields;
- make it clear that there is no aggregation;
- confirm that each row still represents one event.

Example:

```dbml
Table int_bus_arrivals {
  route varchar
  direction varchar
  arrival_date date
  scheduled timestamp
  actual timestamp
  delay_minutes float
  delay_category varchar
  time_category varchar
}
```

## Implementation in dbt

Intermediate models usually live in:

```text
models/intermediate/
```

And use the prefix:

```text
int_model_name.sql
```

Example:

```text
models/intermediate/int_bus_arrivals.sql
```

Example structure:

```sql
WITH arrivals AS (
    SELECT *
    FROM {{ ref('stg_arrival_times') }}
),

final AS (
    SELECT
        route,
        direction,
        arrival_date,
        scheduled,
        actual,
        date_diff('minute', scheduled, actual) AS delay_minutes,
        CASE
            WHEN date_diff('minute', scheduled, actual) < 0 THEN 'early'
            WHEN date_diff('minute', scheduled, actual) <= 5 THEN 'on_time'
            WHEN date_diff('minute', scheduled, actual) <= 15 THEN 'slight'
            WHEN date_diff('minute', scheduled, actual) <= 30 THEN 'moderate'
            ELSE 'severe'
        END AS delay_category
    FROM arrivals
)

SELECT *
FROM final
```

## Materialization in Intermediate

Intermediate can usually also be a **view**.

Reason:

- it is still a transformation layer;
- it is not consumed directly by the dashboard yet;
- it changes frequently during development.

```yaml
models:
  project_name:
    intermediate:
      +materialized: view
```

## Minimum verification

After running:

```bash
dbt run
```

Check:

- the model was created;
- the calculated columns exist;
- the categories make sense;
- the row count still matches the original grain;
- there is no row reduction caused by aggregation;
- some rows match staging when checked manually.

## Intermediate Model phase checklist

- [ ] The analytical question is clear.
- [ ] The required staging models were identified.
- [ ] The required joins were defined.
- [ ] The base fields were chosen.
- [ ] Calculated fields were planned.
- [ ] Categorical fields were planned.
- [ ] DBML was created before SQL.
- [ ] The model uses the `int_` prefix.
- [ ] The model uses `ref()` for staging.
- [ ] There is no `GROUP BY`.
- [ ] There is no aggregation.
- [ ] Each row still represents one event.
- [ ] `dbt run` works.

---

# Phase 3 — Star Model

## Objective of the phase

Transform the analytical foundation into models ready to answer stakeholder questions.

The main question is:

```text
What question does each fact table answer, and how does it answer it?
```

In this phase, you separate:

- **facts**: aggregated numbers that answer a question at a defined grain;
- **dimensions**: context used to filter, group, and compare.

## Why create a Star Model

The intermediate model contains everything in detailed format, but the stakeholder does not want thousands of individual rows. The stakeholder wants answers.

The star model helps because:

- calculations are done once in dbt;
- each metric stays consistent;
- the grain defines what each row means;
- dimensions can be reused;
- the dashboard becomes simpler;
- filters work better;
- results are more reliable.

## Grain

Grain is the contract of the fact table.

Always write it like this:

```text
Each row represents one [X] in one [Y]
```

Examples:

```text
Each row represents one route on one day.
Each row represents one route in one week.
Each row represents one driver in one race.
Each row represents one team in one season.
```

If you cannot write this sentence clearly, the model is not ready yet.

## Primary grain and roll-up grain

For each analytical question, the course expects two fact tables:

```text
1 analytical question → 1 primary grain fact table + 1 roll-up grain fact table
```

Example:

```text
Question: How reliable are bus routes over time?
Primary grain: route × day
Roll-up grain: route × week
```

Primary grain:

- the finest detail that still answers the question;
- shows daily or individual variation;
- helps identify specific cases.

Roll-up grain:

- summarized version of the primary grain;
- can summarize time, such as day → week;
- can summarize a dimension, such as pizza_size → pizza_category;
- reveals patterns that fine detail may hide.

## Course rule

If there are two analytical questions, you will normally have:

```text
2 questions × 2 grains = 4 fact tables
```

Example:

```text
fct_route_reliability
fct_route_reliability_weekly
fct_time_reliability
fct_time_reliability_weekly
```

## Facts and dimensions

### Fact tables

Fact tables contain:

- keys to dimensions;
- a clearly defined grain;
- aggregated metrics;
- one row per grain combination.

Example:

```text
fct_route_reliability
route_key
date_key
avg_delay_minutes
max_delay_minutes
stddev_delay_minutes
trip_count
```

### Dimension tables

Dimension tables contain context.

Examples:

```text
dim_route
dim_date
dim_week
dim_time_category
dim_driver
dim_team
dim_circuit
```

Dimensions are used to:

- filter;
- group;
- compare;
- give human meaning to the keys in facts.

## Choosing metrics

Before writing SQL, create a metrics table for each fact table.

Template:

| Fact table | Grain | Metric | Source field | Operation | Justification |
|---|---|---|---|---|---|
| `fct_example` | one X in one Y | `avg_value` | `value` | AVG | Typical value at this grain |

Common operations:

| Operation | Meaning | When to use | Caution |
|---|---|---|---|
| AVG | typical value | representative behavior | outliers can distort it |
| SUM | total | total makes sense at the grain | can favor groups with more volume |
| MAX | worst case or peak | you want to see extremes | alone it does not show typical behavior |
| STDDEV | consistency or variation | you want to compare stability | needs context |
| COUNT | volume | always gives context to other metrics | without COUNT, comparisons can mislead |

Important rule:

```text
Categorical data belongs in dimensions.
Numerical data can become measures.
```

## COUNT should almost always exist

`COUNT` gives context to metrics.

Example:

```text
avg_delay_minutes = 10
trip_count = 3
```

does not carry the same weight as:

```text
avg_delay_minutes = 10
trip_count = 300
```

## Star Model DBML

Update the DBML to include dimensions and facts.

Example:

```dbml
Table dim_route {
  route_key int [pk]
  route varchar
  direction varchar
}

Table dim_date {
  date_key int [pk]
  date date
  day_of_week varchar
  week int
  year int
}

Table fct_route_reliability {
  route_key int [ref: > dim_route.route_key]
  date_key int [ref: > dim_date.date_key]
  avg_delay_minutes float
  max_delay_minutes float
  stddev_delay_minutes float
  trip_count int
}
```

## Implementation in dbt

Mart models live in:

```text
models/mart/
```

Common names:

```text
dim_*.sql
fct_*.sql
```

### Creating dimensions

Dimensions normally reference the intermediate model and use `SELECT DISTINCT`.

```sql
WITH source AS (
    SELECT *
    FROM {{ ref('int_bus_arrivals') }}
),

final AS (
    SELECT DISTINCT
        route,
        direction
    FROM source
)

SELECT
    row_number() OVER () AS route_key,
    route,
    direction
FROM final
```

### Creating a fact table at the primary grain

```sql
WITH source AS (
    SELECT *
    FROM {{ ref('int_bus_arrivals') }}
)

SELECT
    route,
    arrival_date,
    AVG(delay_minutes) AS avg_delay_minutes,
    MAX(delay_minutes) AS max_delay_minutes,
    STDDEV(delay_minutes) AS stddev_delay_minutes,
    COUNT(*) AS trip_count
FROM source
GROUP BY
    route,
    arrival_date
```

### Creating a fact table at the roll-up grain

```sql
WITH source AS (
    SELECT *
    FROM {{ ref('int_bus_arrivals') }}
)

SELECT
    route,
    EXTRACT('week' FROM arrival_date) AS week,
    EXTRACT('year' FROM arrival_date) AS year,
    AVG(delay_minutes) AS avg_delay_minutes,
    MAX(delay_minutes) AS max_delay_minutes,
    STDDEV(delay_minutes) AS stddev_delay_minutes,
    COUNT(*) AS trip_count
FROM source
GROUP BY
    route,
    EXTRACT('week' FROM arrival_date),
    EXTRACT('year' FROM arrival_date)
```

## Materialization in Mart

Mart models should be materialized as **table**.

Reason:

- they are consumed by the dashboard;
- they need to be fast;
- facts and dimensions are more stable analytical products.

```yaml
models:
  project_name:
    mart:
      +materialized: table
```

## Minimum verification

After:

```bash
dbt run
```

Check:

- all `dim_` and `fct_` models were created;
- each fact table has exactly one row per grain combination;
- the metrics match the grain;
- `COUNT` makes sense;
- keys and relationships make sense;
- no categorical metric was aggregated as if it were numeric;
- DBML was updated.

## Star Model phase checklist

- [ ] Each analytical question is written in a neutral way and can be answered with data.
- [ ] Each question has a primary grain.
- [ ] Each question has a roll-up grain.
- [ ] Each fact table has a grain sentence.
- [ ] Metrics were documented before SQL.
- [ ] Each metric has source field, operation, and justification.
- [ ] `COUNT` was included when necessary.
- [ ] Dimensions were defined.
- [ ] DBML includes facts and dimensions.
- [ ] `dim_` and `fct_` models were created in `models/mart/`.
- [ ] Mart is materialized as table.
- [ ] `dbt run` works.
- [ ] Row counts confirm the grain.

---

# Phase 4 — Dashboard

## Objective of the phase

Create a dashboard that proves your models work and answer the stakeholder's questions.

Main idea:

```text
The dashboard is not the product. It is the proof.
```

The dashboard should prove:

- that the grain was chosen correctly;
- that the metrics make sense;
- that the analytical questions were answered;
- that the stakeholder can see insights without recalculating anything.

## Central rule

```text
All logic lives in dbt. Metabase is for display only.
```

In Metabase, avoid:

- creating new metrics;
- doing important calculations;
- fixing data;
- defining business rules;
- relying on manual aggregations in the dashboard.

If the logic is important, it should go back to dbt.

## What the exam case dashboard should demonstrate

### 1. Primary grain for each analytical question

You need to show charts based on the primary grain fact tables.

Example:

```text
one data point per driver per race
one data point per route per day
one data point per team per season
```

The chart must clearly reflect the grain.

### 2. Roll-up grain for each analytical question

You also need to show charts based on the roll-up fact tables.

In the report, explain what the roll-up reveals that the primary grain does not reveal.

Example:

```text
Daily grain shows individual bad days.
Weekly grain shows whether those bad days are isolated events or part of a trend.
```

### 3. Filters connected to dimensions

Filters should come from dimension tables, not from loose typed values.

Examples:

```text
team filter → dim_team
circuit filter → dim_circuit
route filter → dim_route
```

When a filter is selected, the relevant charts should update automatically.

### 4. Multiple metrics per question

Do not show only one metric.

If in Phase 3 you defined:

```text
AVG
MAX
STDDEV
COUNT
```

then these metrics should appear somewhere in the dashboard.

### 5. One specific insight

You need to be able to explain one real finding.

Good example:

```text
Route 673 is consistently late on weekday mornings.
```

Weak example:

```text
The chart shows the data.
```

## Primary grain vs roll-up grain in the dashboard

Primary grain shows fine variation.

Example:

```text
route × day
```

It helps you see:

- specific bad days;
- outliers;
- operational events;
- detailed variation.

Roll-up grain summarizes that variation.

Example:

```text
route × week
```

It helps you see:

- trends;
- stable patterns;
- whether an event was isolated or recurring;
- a more strategic view.

## How to connect filters in Metabase

### GUI questions

1. Include the filter column in the question/chart.
2. In the dashboard, click edit.
3. Add a Text or Category filter.
4. Click each card.
5. Connect the filter to the corresponding column.
6. Repeat for all relevant charts.

Without the column in the chart, the filter cannot connect.

### Native SQL questions

Use filter variables.

Example:

```sql
WHERE {{team_filter}}
```

Optional filter:

```sql
[[AND circuit = {{circuit}}]]
```

But if numeric filters cause problems in Native SQL, prefer GUI questions.

## Choosing visualizations

Use the chart type that best answers the question.

Suggestions:

| Objective | Common visualization |
|---|---|
| trend over time | line chart |
| comparison between categories | bar chart |
| ranking | horizontal bar chart |
| main number | KPI / number card |
| details | table |
| distribution comparison | boxplot, histogram, if available |

Avoid pie charts in most cases, unless you are showing a very simple part of a whole.

## Important pitfalls

### Wrong grain in the chart

If the fact table says:

```text
Each row represents one route on one day
```

then the chart should not accidentally show an aggregation that hides route or day without explanation.

### Metrics without context

AVG without COUNT can mislead.

Whenever comparing averages, try to show the volume.

### Misleading scales

Be careful with:

- a Y-axis that does not start at zero when it distorts comparison;
- pictograms that increase width and height at the same time;
- charts with different scales placed side by side;
- visualizations that are beautiful but unclear.

### Numeric keys with thousands separators

In Metabase, numeric keys like `week_key` may appear like this:

```text
201,612
```

Instead of something readable.

Recommended correction in dbt:

```sql
CAST(week_key AS VARCHAR) AS week_key
```

Or adjust the column format in Metabase to plain number.

## Export and submission

The dashboard is not submitted as a live Metabase instance.

You need to export:

- dashboard PDF;
- screen recording of 2 to 5 minutes;
- screenshot and explanation in the answer sheet, if the question paper asks for it.

In the recording, show:

- the dashboard loading from fact tables;
- filters working;
- filter by team;
- filter by circuit;
- primary grain and roll-up grain for at least one question;
- one specific insight revealed by the dashboard.

## Dashboard phase checklist

- [ ] Metabase is connected to the correct DuckDB.
- [ ] Charts use fact tables, not raw or staging tables.
- [ ] No important logic was created in Metabase.
- [ ] Each analytical question has a primary grain chart.
- [ ] Each analytical question has a roll-up grain chart.
- [ ] The dashboard shows multiple metrics per question.
- [ ] Filters come from dimensions.
- [ ] Filters update the relevant charts.
- [ ] There is at least one specific and well-formulated insight.
- [ ] The exported PDF does not cut off charts.
- [ ] The screen recording shows the required points.

---

# Recommended workflow for the exam case

## Practical working order

1. Read the entire question paper.
2. Identify the analytical questions.
3. List which raw files exist.
4. Plan which raw tables you will create in DuckDB.
5. Implement `load.py`.
6. Verify raw tables in DuckDB.
7. Create `sources.yml`.
8. Create `stg_` models.
9. Document and test staging with `schema.yml` and `tests/`.
10. Plan the intermediate model in DBML.
11. Implement the `int_` model.
12. Define primary grain and roll-up grain for each question.
13. Create a metrics table for each fact table.
14. Update DBML with the star model.
15. Implement `dim_` and `fct_` models in `models/mart/`.
16. Run `dbt run` and `dbt test`.
17. Verify row counts and grain.
18. Build the dashboard in Metabase.
19. Test filters.
20. Export the PDF and record the explanation.

---

# Suggested naming conventions

## Folders

```text
load/
  load.py

dbt/
  models/
    staging/
    intermediate/
    mart/
  tests/
```

## Models

```text
stg_source_name.sql
int_business_process.sql
dim_entity.sql
fct_question_grain.sql
fct_question_rollup.sql
```

## Examples

```text
stg_drivers.sql
stg_races.sql
stg_results.sql

int_race_results.sql

dim_driver.sql
dim_team.sql
dim_circuit.sql
dim_date.sql

fct_driver_performance_by_race.sql
fct_driver_performance_by_season.sql
```

---

# Mini template for report or answer sheet

## Analytical question

```text
Question 1: [write neutral, answerable question]
```

## Phase 2 — Intermediate planning

### Foundation

```text
Staging models needed:
- stg_...
- stg_...

Join keys:
- ...

Base fields carried forward:
- ...

One row represents:
- ...
```

### Added fields

| Field | Type | How derived | Why needed |
|---|---|---|---|
| `field_name` | calculated / categorical | ... | ... |

### DBML

```dbml
Table int_example {
  field_one varchar
  field_two int
  calculated_field float
  category_field varchar
}
```

## Phase 3 — Star model planning

### Fact table 1

```text
Fact table: fct_...
Grain: Each row represents one ... in one ...
```

| Metric | Source field | Operation | Justification |
|---|---|---|---|
| `avg_...` | `...` | AVG | ... |
| `max_...` | `...` | MAX | ... |
| `stddev_...` | `...` | STDDEV | ... |
| `count_...` | `...` | COUNT | ... |

### Roll-up fact table

```text
Fact table: fct_..._weekly or fct_..._rollup
Grain: Each row represents one ... in one ...
```

Explain what the roll-up reveals that the primary grain cannot.

## Phase 4 — Dashboard explanation

```text
Chart 1 shows the primary grain for question 1.
Chart 2 shows the roll-up grain for question 1.
The roll-up reveals ...
The filter by team/circuit updates ...
One specific insight is ...
```

---

# Final quality checklist

Before submitting, confirm:

- [ ] The raw data was loaded without inappropriate cleaning.
- [ ] Staging prepares technically reliable data.
- [ ] Staging does not contain business metrics.
- [ ] Intermediate contains joins and derived fields.
- [ ] Intermediate does not contain aggregation.
- [ ] The star model has explicit grain.
- [ ] Each analytical question has primary and roll-up grain.
- [ ] Facts contain aggregated metrics.
- [ ] Dimensions contain context.
- [ ] Mart models are materialized as tables.
- [ ] The dashboard uses fact tables.
- [ ] The dashboard does not contain hidden business logic.
- [ ] Filters come from dimensions.
- [ ] The report explains a real insight.
- [ ] `dbt run` passes.
- [ ] `dbt test` passes or failures are justified.
- [ ] DBML is updated.
- [ ] PDF and screen recording are ready.
