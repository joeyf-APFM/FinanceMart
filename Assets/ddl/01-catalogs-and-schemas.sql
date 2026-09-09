-- =====================================================================
-- Finance Catalog — 01 — catalogs and schemas
-- Implements the layout in plans/2026-09-09-finance-catalog-and-mart-design.md
--
-- STATUS: NOT EXECUTED. No object described here exists.
-- TARGET WORKSPACE: undecided. `attivita` for the stand-up, or production.
--                   Pass --profile explicitly; the CLI default is production.
--
-- Production schemas are UNPREFIXED. dev_* and qa_* are the same schema
-- names with a prefix. That is decision 1 in the design; it is also the
-- pattern the 2026-08-16 audit objected to as findings M5/M7, so the
-- mitigations in 10-grants.sql are part of the design, not a caveat.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Catalogs
-- ---------------------------------------------------------------------
-- MANAGED LOCATION is deliberately left unset below. Fill it in only after
-- the external location / storage credential for the target workspace is
-- known; inheriting the metastore root is a decision, not a default.

CREATE CATALOG IF NOT EXISTS finance
COMMENT 'Finance domain. Recognized ledger, receivables, operational billing, plan, GP customer identity, and finance reference data. Sourced from the Dynamics GP replicas and the charging platform. Holds the most access-restricted content in the estate: unclosed-period figures and pre-release results are potentially material non-public information. See plans/2026-09-09-finance-catalog-and-mart-design.md.';

CREATE CATALOG IF NOT EXISTS common
COMMENT 'Cross-domain conformed products that no single domain owns. Exists so that shared dimensions do not live inside a restricted domain catalog and force every other domain to reach into it.';

-- Own the catalogs with a group or service principal, never a person.
-- The owner holds all privileges implicitly; a named owner who changes
-- teams is how a catalog becomes unadministrable.
-- ALTER CATALOG finance OWNER TO `data-platform-owners`;
-- ALTER CATALOG common  OWNER TO `data-platform-owners`;

ALTER CATALOG finance SET TAGS ('domain' = 'finance', 'sensitivity' = 'restricted', 'design_doc' = 'plans/2026-09-09-finance-catalog-and-mart-design.md');
ALTER CATALOG common  SET TAGS ('domain' = 'shared',  'sensitivity' = 'internal');

-- ---------------------------------------------------------------------
-- finance — production schemas (unprefixed)
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS finance.general_ledger
COMMENT 'Posted and unposted GL, the account dimension, and period activity derived from them. This is the only schema in which an amount may be called recognized revenue.';

CREATE SCHEMA IF NOT EXISTS finance.receivables
COMMENT 'AR documents, the apply trail, aging, write-offs, and collections attributes. The apply trail is what makes aging history reconstructable rather than lost.';

CREATE SCHEMA IF NOT EXISTS finance.billing
COMMENT 'Operational charges and invoice lines from the charging platform and GP Sales Order Processing. Nothing in this schema is recognized revenue; an operational referral amount must never be labelled or presented as one.';

CREATE SCHEMA IF NOT EXISTS finance.plan
COMMENT 'Plan versions, plan amounts, plan adjustments, and plan-versus-actual. Named plan rather than budget because budget already means family affordability elsewhere in the semantic layer.';

CREATE SCHEMA IF NOT EXISTS finance.identity
COMMENT 'GP customer dimension and the identity bridges. PII-bearing and isolated in its own schema so that grants can be isolated too, and so that masking can be added later without re-plumbing the marts.';

CREATE SCHEMA IF NOT EXISTS finance.reference
COMMENT 'Currency, exchange rates, legal entity, and GP users. dim_currency and fact_exchange_rate are built to the shared-design contract and are expected to move to common when a second domain asks for them.';

ALTER SCHEMA finance.identity SET TAGS ('contains_pii' = 'true', 'masking_status' = 'deferred_by_decision');
ALTER SCHEMA finance.billing  SET TAGS ('measure_class' = 'operational_not_recognized');

-- ---------------------------------------------------------------------
-- finance — non-production schemas (prefixed)
-- ---------------------------------------------------------------------
-- Generate these by substituting the schema name. Do not hand-edit: a
-- substitution that misses one line creates a production object silently,
-- which is the whole cost of putting the environment in the schema name.

CREATE SCHEMA IF NOT EXISTS finance.dev_general_ledger COMMENT 'Development copy of finance.general_ledger. Not production.';
CREATE SCHEMA IF NOT EXISTS finance.dev_receivables    COMMENT 'Development copy of finance.receivables. Not production.';
CREATE SCHEMA IF NOT EXISTS finance.dev_billing        COMMENT 'Development copy of finance.billing. Not production.';
CREATE SCHEMA IF NOT EXISTS finance.dev_plan           COMMENT 'Development copy of finance.plan. Not production.';
CREATE SCHEMA IF NOT EXISTS finance.dev_identity       COMMENT 'Development copy of finance.identity. Not production. Still PII-bearing.';
CREATE SCHEMA IF NOT EXISTS finance.dev_reference      COMMENT 'Development copy of finance.reference. Not production.';

CREATE SCHEMA IF NOT EXISTS finance.qa_general_ledger  COMMENT 'QA copy of finance.general_ledger. Not production.';
CREATE SCHEMA IF NOT EXISTS finance.qa_receivables     COMMENT 'QA copy of finance.receivables. Not production.';
CREATE SCHEMA IF NOT EXISTS finance.qa_billing         COMMENT 'QA copy of finance.billing. Not production.';
CREATE SCHEMA IF NOT EXISTS finance.qa_plan            COMMENT 'QA copy of finance.plan. Not production.';
CREATE SCHEMA IF NOT EXISTS finance.qa_identity        COMMENT 'QA copy of finance.identity. Not production. Still PII-bearing.';
CREATE SCHEMA IF NOT EXISTS finance.qa_reference       COMMENT 'QA copy of finance.reference. Not production.';

-- No personal sandbox schemas in finance, ever. That is audit finding M7
-- and it is the single thing that made `main` unnavigable.

-- ---------------------------------------------------------------------
-- common — production schema
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS common.calendar
COMMENT 'Conformed calendar. One row per calendar date in dim_date, one row per fiscal period and period level in dim_fiscal_calendar, and the as-of close history that GP does not retain. Finance builds these and does not own them.';

CREATE SCHEMA IF NOT EXISTS common.dev_calendar COMMENT 'Development copy of common.calendar. Not production.';
CREATE SCHEMA IF NOT EXISTS common.qa_calendar  COMMENT 'QA copy of common.calendar. Not production.';

-- ---------------------------------------------------------------------
-- main — guarded read schemas alongside the replicas
-- ---------------------------------------------------------------------
-- Decision 2 puts the _fivetran_deleted guard next to the replicas rather
-- than inside a Finance schema, so every consumer of GP inherits it and
-- not only Finance. Views are defined in 02-guarded-gp-views.sql.

CREATE SCHEMA IF NOT EXISTS main.prod_gp_apfm_dbo_live
COMMENT 'Guarded read layer over main.prod_gp_apfm_dbo. One view per replicated table, tombstones excluded and _fivetran_deleted dropped from the projection. Read these, not the raw replica.';

CREATE SCHEMA IF NOT EXISTS main.prod_gp_capfm_dbo_live
COMMENT 'Guarded read layer over main.prod_gp_capfm_dbo. One view per replicated table, tombstones excluded and _fivetran_deleted dropped from the projection. Read these, not the raw replica.';

CREATE SCHEMA IF NOT EXISTS main.prod_gp_dynamics_dbo_live
COMMENT 'Guarded read layer over main.prod_gp_dynamics_dbo (the GP system database). One view per replicated table, tombstones excluded and _fivetran_deleted dropped from the projection.';

ALTER SCHEMA main.prod_gp_apfm_dbo_live     SET TAGS ('layer' = 'guarded_read', 'source_schema' = 'main.prod_gp_apfm_dbo');
ALTER SCHEMA main.prod_gp_capfm_dbo_live    SET TAGS ('layer' = 'guarded_read', 'source_schema' = 'main.prod_gp_capfm_dbo');
ALTER SCHEMA main.prod_gp_dynamics_dbo_live SET TAGS ('layer' = 'guarded_read', 'source_schema' = 'main.prod_gp_dynamics_dbo');
