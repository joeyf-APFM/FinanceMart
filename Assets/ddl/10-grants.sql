-- =====================================================================
-- Finance Catalog — 10 — grants
--
-- STATUS: NOT EXECUTED.
--
-- GROUP NAMES BELOW ARE PLACEHOLDERS. Every principal is written as
-- `finance-*` or `data-platform-*` and none of them has been checked
-- against the account console. Confirm each against the real account groups
-- before running anything here — a GRANT to a group that does not exist
-- fails loudly, which is fine, but a GRANT to a similarly-named group that
-- does exist succeeds silently and is the whole problem.
--
--   databricks account groups list --profile account-apfm
--
-- WHY THIS FILE IS LONG AND REPETITIVE. Environment lives in the schema
-- name, by decision. Unity Catalog inherits privileges DOWNWARD from
-- catalog to schema to table, which means a single GRANT SELECT ON CATALOG
-- finance reaches dev_general_ledger and qa_receivables as well as the
-- production schemas. There is no wildcard that says "the unprefixed ones."
-- So every grant here is written per schema, and the repetition is the cost
-- of the layout choice rather than an oversight.
--
-- The corollary, and it is the important one: NEVER GRANT ANYTHING AT
-- CATALOG LEVEL EXCEPT USE CATALOG. USE CATALOG conveys no read access on
-- its own; it is the traversal privilege that makes a schema-level grant
-- usable. Anything stronger at catalog level defeats the entire separation.
--
-- THE M5/M7 MITIGATION IS PREVENTION, NOT DETECTION. Unity Catalog is
-- deny-by-default, so the way to stop a non-production object appearing in
-- an unprefixed schema is to never grant CREATE TABLE on one to anyone
-- outside the build service principal. The drift check at the bottom exists
-- because "never granted" is an intention until something asserts it.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Catalog traversal — the ONLY catalog-level grants
-- ---------------------------------------------------------------------

GRANT USE CATALOG ON CATALOG finance TO `finance-analysts`;
GRANT USE CATALOG ON CATALOG finance TO `finance-engineers`;
GRANT USE CATALOG ON CATALOG finance TO `data-platform-engineers`;
GRANT USE CATALOG ON CATALOG finance TO `sp-finance-mart-build`;

GRANT USE CATALOG ON CATALOG common  TO `finance-analysts`;
GRANT USE CATALOG ON CATALOG common  TO `finance-engineers`;
GRANT USE CATALOG ON CATALOG common  TO `data-platform-engineers`;
GRANT USE CATALOG ON CATALOG common  TO `sp-finance-mart-build`;

-- Deliberately absent, and each absence is the mitigation rather than an
-- omission:
--   GRANT SELECT ON CATALOG finance        -- would reach dev_* and qa_*
--   GRANT ALL PRIVILEGES ON CATALOG ...    -- includes CREATE SCHEMA
--   GRANT CREATE SCHEMA ON CATALOG finance -- how M7 happened the first time

-- ---------------------------------------------------------------------
-- Production read — enumerated per schema, on purpose
-- ---------------------------------------------------------------------
-- finance.identity is NOT in this list. It gets its own section.

GRANT USE SCHEMA, SELECT ON SCHEMA finance.general_ledger TO `finance-analysts`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.receivables    TO `finance-analysts`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.billing        TO `finance-analysts`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.plan           TO `finance-analysts`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.reference      TO `finance-analysts`;

-- common.calendar is readable by everyone who can traverse the catalog.
-- This is the point of putting it in `common`: a shared calendar that
-- requires a Finance grant is not shared.
GRANT USE SCHEMA, SELECT ON SCHEMA common.calendar TO `account users`;

-- ---------------------------------------------------------------------
-- finance.identity — a SEPARATE grant set
-- ---------------------------------------------------------------------
-- This schema holds names, addresses, phone numbers, bank name and branch,
-- and tax registration numbers. The plan records the decision to defer
-- masking on the grounds that everyone who will access this data has rights
-- to see it. That decision is about TODAY'S AUDIENCE, and it holds exactly
-- as long as the audience does.
--
-- Isolating the grant is what keeps the decision cheap to reverse. When the
-- audience widens, the change is a grant here plus the statements in file
-- 11 — not a re-plumbing of five marts.
--
-- Note the corollary already recorded in the vault: column masks on RM00101
-- disable entity matching. A Genie agent tuned against an unmasked
-- dim_customer is invalidated the day masking arrives. Point agents at the
-- marts, and grant them nothing here.

GRANT USE SCHEMA, SELECT ON SCHEMA finance.identity TO `finance-pii-readers`;

-- Deliberately NOT granted to `finance-analysts`. If that turns out to be
-- the same set of people today, make them members of finance-pii-readers
-- rather than widening this grant — membership is reversible in one place,
-- a grant sprawls.

-- ---------------------------------------------------------------------
-- Build and write
-- ---------------------------------------------------------------------
-- Only the build service principal writes to unprefixed schemas. Not the
-- engineers. An engineer who needs to write does it in dev_* or through the
-- pipeline, which is the difference between a mart and a sandbox that
-- happens to be in the production catalog.

GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.general_ledger TO `sp-finance-mart-build`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.receivables    TO `sp-finance-mart-build`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.billing        TO `sp-finance-mart-build`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.plan           TO `sp-finance-mart-build`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.identity       TO `sp-finance-mart-build`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.reference      TO `sp-finance-mart-build`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA common.calendar        TO `sp-finance-mart-build`;

-- The snapshot job is separated from the mart build because it has a
-- different failure mode: a missed day of snap_period_close_daily is
-- permanently lost history, so it should be able to run when the mart build
-- is broken or paused.
GRANT USE SCHEMA, MODIFY, SELECT ON SCHEMA common.calendar        TO `sp-finance-snapshot`;
GRANT USE SCHEMA, MODIFY, SELECT ON SCHEMA finance.receivables    TO `sp-finance-snapshot`;

-- ---------------------------------------------------------------------
-- Non-production
-- ---------------------------------------------------------------------
-- Engineers get write access in dev_*, read in qa_*. The asymmetry is
-- deliberate: if an engineer can write to qa_*, qa_* stops being a test of
-- the pipeline and becomes a second sandbox.

GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.dev_general_ledger TO `finance-engineers`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.dev_receivables    TO `finance-engineers`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.dev_billing        TO `finance-engineers`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.dev_plan           TO `finance-engineers`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.dev_reference      TO `finance-engineers`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA finance.dev_identity       TO `finance-engineers`;
GRANT USE SCHEMA, CREATE TABLE, MODIFY, SELECT ON SCHEMA common.dev_calendar        TO `finance-engineers`;

GRANT USE SCHEMA, SELECT ON SCHEMA finance.qa_general_ledger TO `finance-engineers`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.qa_receivables    TO `finance-engineers`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.qa_billing        TO `finance-engineers`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.qa_plan           TO `finance-engineers`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.qa_reference      TO `finance-engineers`;
GRANT USE SCHEMA, SELECT ON SCHEMA finance.qa_identity       TO `finance-engineers`;
GRANT USE SCHEMA, SELECT ON SCHEMA common.qa_calendar        TO `finance-engineers`;

-- dev_identity and qa_identity hold PII of the same shape as production. If
-- they are to be loaded with real data, they need the same grant discipline
-- as finance.identity and the finance-engineers grant above is too wide. The
-- alternative is to load them with synthetic or subsetted data. THIS IS AN
-- OPEN DECISION and it must be made before the first load, not after.

-- ---------------------------------------------------------------------
-- Guarded GP read layer
-- ---------------------------------------------------------------------
-- Grant on the _live views, never on the underlying replica schemas. A
-- consumer with SELECT on main.prod_gp_apfm_dbo will read tombstoned rows
-- and overstate gl20000 by roughly 5.7x, and nothing in the query will look
-- wrong.

GRANT USE SCHEMA, SELECT ON SCHEMA main.prod_gp_apfm_dbo_live     TO `finance-analysts`;
GRANT USE SCHEMA, SELECT ON SCHEMA main.prod_gp_capfm_dbo_live    TO `finance-analysts`;
GRANT USE SCHEMA, SELECT ON SCHEMA main.prod_gp_dynamics_dbo_live TO `finance-analysts`;

-- The views' owner needs SELECT on the underlying tables for the views to
-- resolve. That is the owner, not the readers.
-- GRANT USE SCHEMA, SELECT ON SCHEMA main.prod_gp_apfm_dbo TO `sp-finance-mart-build`;

-- ---------------------------------------------------------------------
-- Drift checks — run on a schedule, not once
-- ---------------------------------------------------------------------
-- "We never granted that" is an intention until something asserts it.

-- 1. No catalog-level grant on `finance` other than USE CATALOG. This is the
--    single check that catches an accidental blanket grant reaching dev_*.
-- SELECT grantee, privilege_type
-- FROM   system.information_schema.catalog_privileges
-- WHERE  catalog_name = 'finance'
--   AND  privilege_type <> 'USE CATALOG';

-- 2. No non-production principal holds a privilege on an unprefixed finance
--    schema. Adjust the principal pattern to the real group naming once the
--    account groups are confirmed.
-- SELECT schema_name, grantee, privilege_type
-- FROM   system.information_schema.schema_privileges
-- WHERE  catalog_name = 'finance'
--   AND  schema_name NOT LIKE 'dev_%'
--   AND  schema_name NOT LIKE 'qa_%'
--   AND  grantee NOT IN ('sp-finance-mart-build', 'sp-finance-snapshot',
--                        'finance-analysts', 'finance-pii-readers',
--                        'data-platform-owners');

-- 3. No schema in `finance` outside the sanctioned twelve plus identity.
--    This is the M7 check: a schema nobody planned is how sandboxes get
--    into a production catalog.
-- SELECT schema_name
-- FROM   system.information_schema.schemata
-- WHERE  catalog_name = 'finance'
--   AND  schema_name NOT IN (
--          'general_ledger','receivables','billing','plan','identity','reference',
--          'dev_general_ledger','dev_receivables','dev_billing','dev_plan','dev_identity','dev_reference',
--          'qa_general_ledger','qa_receivables','qa_billing','qa_plan','qa_identity','qa_reference',
--          'information_schema','default');

-- 4. Nobody but the build principals can create in an unprefixed schema.
-- SELECT schema_name, grantee, privilege_type
-- FROM   system.information_schema.schema_privileges
-- WHERE  catalog_name = 'finance'
--   AND  schema_name NOT LIKE 'dev_%'
--   AND  schema_name NOT LIKE 'qa_%'
--   AND  privilege_type IN ('CREATE TABLE','CREATE FUNCTION','CREATE MATERIALIZED VIEW','ALL PRIVILEGES')
--   AND  grantee NOT IN ('sp-finance-mart-build','sp-finance-snapshot');

-- 5. Nobody reads the raw GP replicas directly. A grant here means someone
--    is counting tombstoned rows.
-- SELECT schema_name, grantee, privilege_type
-- FROM   system.information_schema.schema_privileges
-- WHERE  catalog_name = 'main'
--   AND  schema_name IN ('prod_gp_apfm_dbo','prod_gp_capfm_dbo','prod_gp_dynamics_dbo')
--   AND  grantee <> 'sp-finance-mart-build';

-- 6. finance.identity is readable only by the PII group and the build
--    principal. The narrowest grant in the catalog is the one most likely to
--    widen quietly.
-- SELECT grantee, privilege_type
-- FROM   system.information_schema.schema_privileges
-- WHERE  catalog_name = 'finance' AND schema_name = 'identity'
--   AND  grantee NOT IN ('finance-pii-readers','sp-finance-mart-build','data-platform-owners');
