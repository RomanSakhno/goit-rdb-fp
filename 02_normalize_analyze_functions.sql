-- Step 2: run ONLY AFTER importing infectious_cases.csv into pandemic.infectious_cases_raw.
-- PostgreSQL 12+ recommended. The raw table is intentionally NOT dropped here.

CREATE SCHEMA IF NOT EXISTS pandemic;
SET search_path TO pandemic, public;

-- Rebuild normalized tables so this script can be rerun safely after import.
DROP TABLE IF EXISTS pandemic.infectious_cases CASCADE;
DROP TABLE IF EXISTS pandemic.entities CASCADE;

-- Dimension table: unique Entity + Code combinations.
CREATE TABLE pandemic.entities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity TEXT NOT NULL,
    code TEXT
);

-- Treat NULL codes as one distinct value for uniqueness (CSV contains missing codes).
CREATE UNIQUE INDEX uq_entities_entity_code
    ON pandemic.entities (entity, COALESCE(code, ''));

INSERT INTO pandemic.entities (entity, code)
SELECT DISTINCT NULLIF(BTRIM(entity), ''), NULLIF(BTRIM(code), '')
FROM pandemic.infectious_cases_raw
WHERE NULLIF(BTRIM(entity), '') IS NOT NULL
ON CONFLICT DO NOTHING;

-- Fact table: disease measures with a foreign key to the dimension table.
CREATE TABLE pandemic.infectious_cases (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_id BIGINT NOT NULL REFERENCES pandemic.entities(id),
    year INTEGER,
    number_yaws NUMERIC,
    polio_cases NUMERIC,
    cases_guinea_worm NUMERIC,
    number_rabies NUMERIC,
    number_malaria NUMERIC,
    number_hiv NUMERIC,
    number_tuberculosis NUMERIC,
    number_smallpox NUMERIC,
    number_cholera_cases NUMERIC
);

-- Convert blank or malformed numeric values to NULL rather than failing the import.
INSERT INTO pandemic.infectious_cases (
    entity_id, year, number_yaws, polio_cases, cases_guinea_worm,
    number_rabies, number_malaria, number_hiv, number_tuberculosis,
    number_smallpox, number_cholera_cases
)
SELECT
    e.id,
    CASE WHEN BTRIM(r.year) ~ '^[+-]?[0-9]+$' THEN BTRIM(r.year)::INTEGER END,
    CASE WHEN BTRIM(r.number_yaws) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.number_yaws)::NUMERIC END,
    CASE WHEN BTRIM(r.polio_cases) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.polio_cases)::NUMERIC END,
    CASE WHEN BTRIM(r.cases_guinea_worm) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.cases_guinea_worm)::NUMERIC END,
    CASE WHEN BTRIM(r.number_rabies) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.number_rabies)::NUMERIC END,
    CASE WHEN BTRIM(r.number_malaria) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.number_malaria)::NUMERIC END,
    CASE WHEN BTRIM(r.number_hiv) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.number_hiv)::NUMERIC END,
    CASE WHEN BTRIM(r.number_tuberculosis) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.number_tuberculosis)::NUMERIC END,
    CASE WHEN BTRIM(r.number_smallpox) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.number_smallpox)::NUMERIC END,
    CASE WHEN BTRIM(r.number_cholera_cases) ~ '^[+-]?[0-9]+([.][0-9]+)?$' THEN BTRIM(r.number_cholera_cases)::NUMERIC END
FROM pandemic.infectious_cases_raw r
JOIN pandemic.entities e
  ON e.entity = NULLIF(BTRIM(r.entity), '')
 AND e.code IS NOT DISTINCT FROM NULLIF(BTRIM(r.code), '');

CREATE INDEX ix_infectious_cases_entity_year
    ON pandemic.infectious_cases (entity_id, year);
ANALYZE pandemic.entities;
ANALYZE pandemic.infectious_cases;

-- Validation: expected 10,521 raw and normalized rows for the supplied CSV.
SELECT COUNT(*) AS raw_rows FROM pandemic.infectious_cases_raw;
SELECT COUNT(*) AS entity_code_pairs FROM pandemic.entities;
SELECT COUNT(*) AS normalized_rows FROM pandemic.infectious_cases;
SELECT COUNT(*) AS rows_without_rabies FROM pandemic.infectious_cases WHERE number_rabies IS NULL;

-- Task 3: statistics for Number_rabies, descending average, top 10.
SELECT
    e.entity,
    e.code,
    AVG(ic.number_rabies) AS average_rabies,
    MIN(ic.number_rabies) AS minimum_rabies,
    MAX(ic.number_rabies) AS maximum_rabies,
    SUM(ic.number_rabies) AS total_rabies
FROM pandemic.infectious_cases ic
JOIN pandemic.entities e ON e.id = ic.entity_id
GROUP BY e.id, e.entity, e.code
ORDER BY AVG(ic.number_rabies) DESC NULLS LAST
LIMIT 10;

-- Task 4: year start, current date, and completed years between dates.
SELECT
    e.entity,
    e.code,
    ic.year,
    MAKE_DATE(ic.year, 1, 1) AS year_start_date,
    CURRENT_DATE AS current_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAKE_DATE(ic.year, 1, 1)))::INTEGER AS years_difference
FROM pandemic.infectious_cases ic
JOIN pandemic.entities e ON e.id = ic.entity_id
WHERE ic.year IS NOT NULL
ORDER BY e.entity, ic.year
LIMIT 100;

-- Task 5a: function returning the number of completed years since Jan 1 of p_year.
CREATE OR REPLACE FUNCTION pandemic.years_since_year(p_year INTEGER)
RETURNS INTEGER
LANGUAGE SQL
STABLE
STRICT
AS $$
    SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAKE_DATE(p_year, 1, 1)))::INTEGER;
$$;

SELECT year, pandemic.years_since_year(year) AS years_difference
FROM pandemic.infectious_cases
WHERE year IS NOT NULL
ORDER BY year
LIMIT 20;

-- Task 5b: average annual value over a chosen number of periods.
CREATE OR REPLACE FUNCTION pandemic.average_cases_per_period(
    p_annual_cases NUMERIC,
    p_divisor NUMERIC
)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT CASE
        WHEN p_annual_cases IS NULL OR p_divisor IS NULL OR p_divisor <= 0 THEN NULL
        ELSE p_annual_cases / p_divisor
    END;
$$;

-- Function test: monthly, quarterly, and half-year averages.
SELECT
    pandemic.average_cases_per_period(1200, 12) AS monthly_average,
    pandemic.average_cases_per_period(1200, 4) AS quarterly_average,
    pandemic.average_cases_per_period(1200, 2) AS half_year_average;

-- Apply the function to numeric values only (NUMERIC column and non-NULL filter).
SELECT
    e.entity,
    e.code,
    ic.year,
    ic.number_rabies AS annual_rabies,
    pandemic.average_cases_per_period(ic.number_rabies, 12) AS monthly_average,
    pandemic.average_cases_per_period(ic.number_rabies, 4) AS quarterly_average,
    pandemic.average_cases_per_period(ic.number_rabies, 2) AS half_year_average
FROM pandemic.infectious_cases ic
JOIN pandemic.entities e ON e.id = ic.entity_id
WHERE ic.number_rabies IS NOT NULL
ORDER BY e.entity, ic.year
LIMIT 100;

-- Optional source-data quality checks.
SELECT COUNT(*) AS missing_years FROM pandemic.infectious_cases WHERE year IS NULL;
SELECT COUNT(*) AS missing_rabies_values FROM pandemic.infectious_cases WHERE number_rabies IS NULL;
