-- Step 1: prepare the schema and raw landing table.
-- Run this script FIRST. Then import infectious_cases.csv into pandemic.infectious_cases_raw
-- with pgAdmin (Import/Export > Import; format CSV; Header = Yes; delimiter comma).

CREATE SCHEMA IF NOT EXISTS pandemic;

CREATE TABLE IF NOT EXISTS pandemic.infectious_cases_raw (
    entity TEXT,
    code TEXT,
    year TEXT,
    number_yaws TEXT,
    polio_cases TEXT,
    cases_guinea_worm TEXT,
    number_rabies TEXT,
    number_malaria TEXT,
    number_hiv TEXT,
    number_tuberculosis TEXT,
    number_smallpox TEXT,
    number_cholera_cases TEXT
);

-- In pgAdmin, select the pandemic schema for browsing.
-- After importing, run these checks:
SELECT COUNT(*) AS raw_rows FROM pandemic.infectious_cases_raw;
SELECT * FROM pandemic.infectious_cases_raw LIMIT 10;
