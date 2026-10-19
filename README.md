# Final Project — `infectious_cases`

PostgreSQL final project for the relational database course. The project imports the `infectious_cases.csv` dataset, normalizes it to a dimension/fact structure, analyzes `Number_rabies`, calculates date differences, and creates two SQL functions.

## Dataset

The supplied CSV contains **10,521 rows and 12 columns**:

`Entity`, `Code`, `Year`, `Number_yaws`, `polio_cases`, `cases_guinea_worm`, `Number_rabies`, `Number_malaria`, `Number_hiv`, `Number_tuberculosis`, `Number_smallpox`, `Number_cholera_cases`.

The data includes missing values. In the provided file, `Code` is missing in 1,128 rows and `Number_rabies` is missing in 3,741 rows. Missing disease values are retained as SQL `NULL`; they are not replaced with zero. The year range is 1920–2023.

## Repository structure

- `infectious_cases.csv` — source dataset supplied for the assignment.
- `01_prepare_import.sql` — creates schema `pandemic` and raw import table.
- `02_normalize_analyze_functions.sql` — normalizes data and executes tasks 2–5.
- `screenshots/` — place screenshots of the schema/tables and query results here before submission.

## How to run (pgAdmin)

1. Create or select your PostgreSQL database.
2. Open and execute `01_prepare_import.sql`.
3. In pgAdmin, right-click `pandemic.infectious_cases_raw` → **Import/Export Data** → **Import**. Select `infectious_cases.csv`, format **CSV**, delimiter comma, and enable **Header**. The table columns match the CSV header order.
4. Verify the import: `SELECT COUNT(*) FROM pandemic.infectious_cases_raw;` should return **10,521**.
5. Open and execute `02_normalize_analyze_functions.sql`.
6. Verify that the normalized fact table also contains **10,521** rows. The dimension table contains the unique `Entity`/`Code` combinations, with missing codes handled as a single null value per entity.
7. Capture real screenshots of the schema, both normalized tables, the top-10 rabies summary, the date-difference query, and both function outputs. Save them under `screenshots/`.

**Important:** run the scripts in the order above. Do not execute the processing script before importing the CSV. The raw table is not dropped by the processing script, so it remains available for traceability.

## Normalization

- `pandemic.entities`: dimension table with `id` as `PRIMARY KEY`, plus `entity` and `code`. A unique expression index treats a missing `code` consistently when enforcing uniqueness.
- `pandemic.infectious_cases`: fact table with `id` as `PRIMARY KEY`, `entity_id` as `FOREIGN KEY`, year, and disease measures.

This avoids repeating the entity/code attributes in every disease record and establishes referential integrity between the tables.

## Analysis and functions

1. Aggregates `AVG`, `MIN`, `MAX`, and `SUM` for `Number_rabies`, ordered by average descending, limited to 10 rows.
2. `MAKE_DATE(year, 1, 1)`, `CURRENT_DATE`, and `AGE()`/`EXTRACT()` for completed years between dates.
3. `pandemic.years_since_year(p_year)` — returns completed years since January 1 of the given year.
4. `pandemic.average_cases_per_period(p_annual_cases, p_divisor)` — divides an annual value by the supplied number of periods; the script tests divisors 12, 4, and 2. Rows with `NULL` rabies values are excluded from the application query.

## Before submitting

- Confirm the scripts execute successfully in your PostgreSQL instance.
- Add screenshots of actual query results; the repository's `screenshots/` directory is a placeholder until you add them.
- Publish the repository as `goit-rdb-fp` and submit its public URL plus a ZIP archive named `ФП_ПІБ`.
