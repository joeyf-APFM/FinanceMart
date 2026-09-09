-- =====================================================================
-- Finance Catalog — 03 — common.calendar
--
-- STATUS: NOT EXECUTED, with one exception flagged below.
--
-- Finance builds these three products and does not own them. dim_date is
-- consumed by every domain in the semantic-layer design, and the finance
-- catalog will hold the most access-restricted content in the estate, so a
-- universally shared calendar living inside it would invert the governance
-- gradient and force every other domain to reach into Finance.
--
-- THE ONE THING WITH A DEADLINE: snap_period_close_daily. SY40100.CLOSED is
-- a current-state boolean that Fivetran overwrites. GP records "is this
-- period closed now" and never "was this period closed as of last Tuesday."
-- Nine BO 2.0 vintage revenue measures need the second question. Every day
-- without a snapshot is a day of history that cannot be recovered, so this
-- table should start collecting into a scratch schema before the catalog
-- exists and before Finance reviews anything.
-- =====================================================================

-- ---------------------------------------------------------------------
-- dim_date — a PROMOTION, not a new build
-- ---------------------------------------------------------------------
-- There are already at least three: main.prod_refined.dim_date feeds
-- main.prod.dim_date (nine downstream consumers), and
-- main.prod_edw_dbo.dim_date exists as well. Building a fourth inside
-- `finance` is the exact failure this schema prevents.
--
-- The column list is NOT restated here, deliberately. It belongs to the
-- source and inventing it would create a fourth definition while claiming
-- to prevent one. Inventory first:
--
--   DESCRIBE TABLE EXTENDED main.prod_refined.dim_date;
--
-- Then promote as-is:

-- CREATE TABLE IF NOT EXISTS common.calendar.dim_date
-- COMMENT 'Conformed calendar date dimension. One row per calendar date. Promoted from main.prod_refined.dim_date on <date>; the column contract is inherited from that table, not redefined here. A calendar date is immutable — fiscal attributes that change (period close state) are deliberately NOT absorbed into this table, they live in dim_fiscal_calendar and snap_period_close_daily.'
-- AS SELECT * FROM main.prod_refined.dim_date;

-- The design requires one column the source may not have: an explicit
-- reference to the fiscal period, so that dim_date points at its period
-- rather than absorbing the period's mutable attributes.

-- ALTER TABLE common.calendar.dim_date ADD COLUMNS (
--   fiscal_period_key BIGINT COMMENT 'FK to dim_fiscal_calendar at period_level = ''period''. dim_date references its fiscal period rather than absorbing fiscal attributes, because a calendar date is immutable and a period''s close state is not.'
-- );

-- ALTER TABLE common.calendar.dim_date ALTER COLUMN date_key SET NOT NULL;
-- ALTER TABLE common.calendar.dim_date ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_key);

-- Confirm date_key's type before writing the facts: every date_key column
-- in 04-09 is declared INT on the assumption of a yyyymmdd surrogate. If
-- the promoted source uses DATE or BIGINT, change the facts, not this file.

-- ---------------------------------------------------------------------
-- Deprecating the existing copies — DO NOT RUN YET
-- ---------------------------------------------------------------------
-- main.prod.dim_date is a table with nine downstream consumers. Replacing
-- it with a view is a change to production with nine blast-radius targets.
-- Identify all nine, agree a schedule, then run these.
--
-- CREATE OR REPLACE VIEW main.prod.dim_date          AS SELECT * FROM common.calendar.dim_date;
-- CREATE OR REPLACE VIEW main.prod_refined.dim_date  AS SELECT * FROM common.calendar.dim_date;
-- CREATE OR REPLACE VIEW main.prod_edw_dbo.dim_date  AS SELECT * FROM common.calendar.dim_date;

-- ---------------------------------------------------------------------
-- dim_fiscal_calendar
-- ---------------------------------------------------------------------
-- Grain is one row per fiscal period AND period level — NOT one row per
-- calendar date. Close state is deliberately absent from this table: GP
-- grains close on period x SERIES, so a single close flag per period would
-- be silently wrong for whoever cares about the other series. Close state
-- lives in snap_period_close_daily.

CREATE TABLE IF NOT EXISTS common.calendar.dim_fiscal_calendar (
  fiscal_period_key   BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(fiscal_year, period_level, period_number). Deterministic rather than an identity column because this table is rebuilt from a replica, and an identity column would renumber on every full reload and orphan every fact already keyed to it.',
  fiscal_year         INT         NOT NULL COMMENT 'SY40101.YEAR1. The GP fiscal year.',
  period_level        STRING      NOT NULL COMMENT 'One of period, quarter, year. Only period rows come from GP (SY40100); quarter and year rows are derived by rollup and are marked as such in is_derived_level.',
  period_number       INT         NOT NULL COMMENT 'SY40100.PERIODID for period rows; 1-4 for quarters; 0 for the year row. Period 0 in GP carries beginning-balance-forward, so a period_number of 0 at period_level = period is not a data error.',
  period_name         STRING               COMMENT 'SY40100.PERNAME, the period name as maintained in GP.',
  period_start_date   DATE                 COMMENT 'SY40100.PERIODDT. GP blank-date sentinel 1900-01-01 is mapped to NULL.',
  period_end_date     DATE                 COMMENT 'SY40100.PERDENDT.',
  fiscal_year_start_date DATE              COMMENT 'SY40101.FSTFSCDY, first day of the fiscal year.',
  fiscal_year_end_date   DATE              COMMENT 'SY40101.LSTFSCDY, last day of the fiscal year.',
  periods_in_year     INT                  COMMENT 'SY40101.NUMOFPER. Read this rather than assuming twelve.',
  is_historical_year  BOOLEAN              COMMENT 'SY40101.HISTORYR. True once GP has moved the year to history, which is also the boundary between gl20000 and gl30000.',
  is_derived_level    BOOLEAN     NOT NULL COMMENT 'True for quarter and year rows, which this pipeline derives. False for period rows, which GP supplies. A consumer summing across levels without filtering will double count.',
  source_calendar     STRING      NOT NULL COMMENT 'Which GP company supplied the period boundaries. Expected to be a single shared value: publication is blocked on test T-03 confirming that APFM and CAPFM define identical periods, because a conformed calendar cannot represent two different calendars.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Fully qualified guarded-layer table the row was built from.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_dim_fiscal_calendar PRIMARY KEY (fiscal_period_key)
)
COMMENT 'Conformed fiscal calendar. One row per fiscal period and period level. Built by Finance from Dynamics GP SY40100 and SY40101; owned by Data Platform. Close state is NOT here — see snap_period_close_daily, because GP grains close on period x series.'
CLUSTER BY (fiscal_year, period_level);

ALTER TABLE common.calendar.dim_fiscal_calendar SET TAGS ('conformed' = 'true', 'grain' = 'fiscal_period_x_period_level', 'built_by' = 'finance', 'owned_by' = 'data_platform');

-- ---------------------------------------------------------------------
-- snap_period_close_daily — START THIS FIRST
-- ---------------------------------------------------------------------
-- One row per snapshot date x legal entity x fiscal year x period x series.
-- SERIES matters and is the correction this design makes to the earlier
-- vault claim: a period can be closed for Financial and open for Sales, so
-- one close flag per period is wrong for someone.
--
-- SERIES codes as documented in the GP metadata reference:
--   1 All, 2 Financial, 3 Sales, 4 Purchasing, 5 Inventory,
--   6 Payroll - USA, 7 Project

CREATE TABLE IF NOT EXISTS common.calendar.snap_period_close_daily (
  snapshot_date       DATE        NOT NULL COMMENT 'The date this observation was taken. This column exists because GP does not: SY40100.CLOSED is current state and Fivetran overwrites the prior value.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM. Each GP company maintains its own period-close state; do not assume they match.',
  fiscal_year         INT         NOT NULL COMMENT 'SY40100.YEAR1.',
  period_number       INT         NOT NULL COMMENT 'SY40100.PERIODID.',
  series_id           INT         NOT NULL COMMENT 'SY40100.SERIES. 1 All, 2 Financial, 3 Sales, 4 Purchasing, 5 Inventory, 6 Payroll - USA, 7 Project.',
  series_name         STRING               COMMENT 'Decoded series_id. Decoded here rather than left to consumers because the codes are not self-evident.',
  fiscal_period_key   BIGINT               COMMENT 'FK to dim_fiscal_calendar at period_level = period.',
  is_closed           BOOLEAN     NOT NULL COMMENT 'SY40100.CLOSED as observed on snapshot_date. This is the whole point of the table.',
  period_start_date   DATE                 COMMENT 'SY40100.PERIODDT as observed, so a period boundary that is edited in GP is visible as a change rather than silently overwritten.',
  period_end_date     DATE                 COMMENT 'SY40100.PERDENDT as observed.',
  origin_flag         STRING               COMMENT 'SY40100.FORIGIN, retained unresolved. Its semantics are not documented in the vault; profile before using.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table observed, e.g. main.prod_gp_apfm_dbo_live.sy40100.',
  _source_synced_at   TIMESTAMP            COMMENT '_fivetran_synced on the observed row. NOT a freshness signal — it advances only when the row changes. Retained for provenance only.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When the snapshot job wrote the row.',
  CONSTRAINT pk_snap_period_close_daily PRIMARY KEY (snapshot_date, legal_entity_code, fiscal_year, period_number, series_id),
  CONSTRAINT fk_snap_close_period FOREIGN KEY (fiscal_period_key) REFERENCES common.calendar.dim_fiscal_calendar
)
COMMENT 'Daily as-of snapshot of GP period-close state, one row per snapshot date x legal entity x fiscal year x period x series. Exists because GP retains only current state and Fivetran overwrites it. Answers "was this period closed as of date D", which is a different question from "is it closed now" and is the question every vintage revenue measure depends on. Append-only; never restate.'
CLUSTER BY (snapshot_date, legal_entity_code);

ALTER TABLE common.calendar.snap_period_close_daily SET TAGS ('append_only' = 'true', 'irrecoverable_if_delayed' = 'true', 'grain' = 'snapshot_date_x_legal_entity_x_period_x_series');

-- The daily load. Run once per day; missing a day loses that day permanently.
-- INSERT INTO common.calendar.snap_period_close_daily
-- SELECT current_date()                                   AS snapshot_date,
--        'APFM'                                           AS legal_entity_code,
--        p.YEAR1                                          AS fiscal_year,
--        p.PERIODID                                       AS period_number,
--        p.SERIES                                         AS series_id,
--        CASE p.SERIES WHEN 1 THEN 'All' WHEN 2 THEN 'Financial' WHEN 3 THEN 'Sales'
--                      WHEN 4 THEN 'Purchasing' WHEN 5 THEN 'Inventory'
--                      WHEN 6 THEN 'Payroll - USA' WHEN 7 THEN 'Project' END AS series_name,
--        xxhash64(p.YEAR1, 'period', p.PERIODID)          AS fiscal_period_key,
--        p.CLOSED                                         AS is_closed,
--        nullif(date(p.PERIODDT), DATE'1900-01-01')       AS period_start_date,
--        nullif(date(p.PERDENDT), DATE'1900-01-01')       AS period_end_date,
--        cast(p.FORIGIN AS STRING)                        AS origin_flag,
--        'main.prod_gp_apfm_dbo_live.sy40100'             AS source_table,
--        p._fivetran_synced                               AS _source_synced_at,
--        current_timestamp()                              AS _loaded_at
-- FROM   main.prod_gp_apfm_dbo_live.sy40100 p
-- UNION ALL
-- SELECT current_date(), 'CAPFM', p.YEAR1, p.PERIODID, p.SERIES,
--        CASE p.SERIES WHEN 1 THEN 'All' WHEN 2 THEN 'Financial' WHEN 3 THEN 'Sales'
--                      WHEN 4 THEN 'Purchasing' WHEN 5 THEN 'Inventory'
--                      WHEN 6 THEN 'Payroll - USA' WHEN 7 THEN 'Project' END,
--        xxhash64(p.YEAR1, 'period', p.PERIODID),
--        p.CLOSED,
--        nullif(date(p.PERIODDT), DATE'1900-01-01'),
--        nullif(date(p.PERDENDT), DATE'1900-01-01'),
--        cast(p.FORIGIN AS STRING),
--        'main.prod_gp_capfm_dbo_live.sy40100',
--        p._fivetran_synced, current_timestamp()
-- FROM   main.prod_gp_capfm_dbo_live.sy40100 p;

-- ---------------------------------------------------------------------
-- Convenience views over the close history
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW common.calendar.vw_period_close_current
COMMENT 'Latest observed close state per legal entity, fiscal year, period and series. Use this for "is it closed now". Use snap_period_close_daily directly for "was it closed as of date D" — that is what the snapshot is for and this view cannot answer it.'
AS
SELECT s.*
FROM   common.calendar.snap_period_close_daily s
QUALIFY row_number() OVER (
          PARTITION BY s.legal_entity_code, s.fiscal_year, s.period_number, s.series_id
          ORDER BY s.snapshot_date DESC
        ) = 1;

CREATE OR REPLACE VIEW common.calendar.vw_period_close_transitions
COMMENT 'One row per observed change in close state, derived from consecutive snapshots. This is the closest thing available to a GP close event log, and it only sees transitions that fall between two snapshots — a period closed and reopened within one day is invisible.'
AS
SELECT legal_entity_code, fiscal_year, period_number, series_id, series_name,
       snapshot_date          AS observed_on,
       prev_is_closed         AS was_closed,
       is_closed              AS now_closed
FROM (
  SELECT s.*,
         lag(s.is_closed) OVER (
           PARTITION BY s.legal_entity_code, s.fiscal_year, s.period_number, s.series_id
           ORDER BY s.snapshot_date
         ) AS prev_is_closed
  FROM   common.calendar.snap_period_close_daily s
)
WHERE  prev_is_closed IS NOT NULL
  AND  prev_is_closed <> is_closed;
