-- =====================================================================
-- Finance Catalog — 04 — finance.reference
--
-- STATUS: NOT EXECUTED.
--
-- Built first because everything else references it. dim_currency and
-- fact_exchange_rate sit here by decision 3 and the vault expects them to
-- move: the shared design says Commercial & Partner needs the identical
-- product today. Both are therefore built to the shared-design contract
-- now, so the eventual move to `common` is a rename and a grant rather
-- than a remodel.
--
-- Reserved dimension members, per the conformed-dimension standard that
-- every dimension declares Unknown, Not Applicable and Unresolved rather
-- than leaving a fact key null:
--     -1  Unknown       source value present but unrecognised
--     -2  Not Applicable the attribute does not apply to this fact
--     -3  Unresolved     source value absent, expected to arrive later
-- =====================================================================

-- ---------------------------------------------------------------------
-- dim_currency
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS finance.reference.dim_currency (
  currency_key        BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(iso_currency_code). Reserved members -1 Unknown, -2 Not Applicable, -3 Unresolved.',
  iso_currency_code   STRING               COMMENT 'MC40200.ISOCURRC. The conformed key — this is what other domains join on, not GP''s internal currency id. Null on the reserved members.',
  gp_currency_id      STRING               COMMENT 'MC40200.CURNCYID. GP''s own currency identifier, retained because a surrogate never replaces the source key.',
  gp_currency_index   INT                  COMMENT 'MC40200.CURRNIDX. The integer GP actually stores on transactions; needed to join facts back to currency.',
  currency_name       STRING               COMMENT 'MC40200.CRNCYDSC.',
  currency_symbol     STRING               COMMENT 'MC40200.CRNCYSYM.',
  decimal_places      INT                  COMMENT 'Decoded from MC40200.DECPLCUR. GP stores this as a one-based offset, so 3 means 2 decimal places. Confirm the encoding against the replica before trusting the decode; a wrong decode silently misstates every rounded amount.',
  language_id         INT                  COMMENT 'MC40200.CURLNGID.',
  is_reserved_member  BOOLEAN     NOT NULL COMMENT 'True for the -1/-2/-3 rows. Consumers filtering to real currencies filter on this rather than on a negative key.',
  source_system       STRING      NOT NULL COMMENT 'GP, or SEED for reserved members.',
  source_table        STRING               COMMENT 'Preferred source is main.prod_gp_dynamics_dbo_live.mc40200 — the system database defines currency once rather than per company.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_dim_currency PRIMARY KEY (currency_key)
)
COMMENT 'Conformed currency dimension. One row per currency. ISO 4217 code is the conformed key; GP''s CURNCYID and CURRNIDX are retained for joins back to source. Built to the shared-design contract in anticipation of moving to common.';

ALTER TABLE finance.reference.dim_currency SET TAGS ('conformed' = 'true', 'grain' = 'currency', 'expected_to_move_to' = 'common');

-- INSERT INTO finance.reference.dim_currency
--   (currency_key, iso_currency_code, is_reserved_member, currency_name, source_system, _loaded_at)
-- VALUES (-1, NULL, true, 'Unknown',        'SEED', current_timestamp()),
--        (-2, NULL, true, 'Not Applicable', 'SEED', current_timestamp()),
--        (-3, NULL, true, 'Unresolved',     'SEED', current_timestamp());

-- ---------------------------------------------------------------------
-- fact_exchange_rate
-- ---------------------------------------------------------------------
-- A first-class fact rather than a lookup, because CAPFM is Canadian and
-- consolidated APFM + CAPFM reporting requires translation. RM20201 also
-- carries APTOEXRATE and originating-currency amounts, so rate provenance
-- is available per apply — build to that from the start rather than
-- retrofitting translation later.

CREATE TABLE IF NOT EXISTS finance.reference.fact_exchange_rate (
  exchange_rate_key   BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, exchange_table_id, gp_currency_id, rate_date, rate_time).',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM. Exchange tables are maintained per company.',
  exchange_table_id   STRING      NOT NULL COMMENT 'MC00100.EXGTBLID. Which rate table the rate belongs to.',
  currency_key        BIGINT      NOT NULL COMMENT 'FK to dim_currency.',
  gp_currency_id      STRING      NOT NULL COMMENT 'MC00100.CURNCYID as replicated.',
  rate_date           DATE        NOT NULL COMMENT 'MC00100.EXCHDATE. GP blank-date sentinel 1900-01-01 mapped to NULL — but a null here means the row is unusable, so it should be surfaced rather than loaded.',
  rate_time           TIMESTAMP            COMMENT 'MC00100.TIME1. GP stores date and time in separate columns; both are needed because a table can hold multiple rates for one day.',
  expiration_date     DATE                 COMMENT 'MC00100.EXPNDATE. When the rate stops applying.',
  exchange_rate       DECIMAL(19,7)        COMMENT 'MC00100.XCHGRATE. Confirm the landed precision against the replica rather than assuming 19,7; a truncated rate is a silent translation error.',
  rate_purpose        STRING               COMMENT 'Derived from MC40600, which maps a currency to its Current, Historical, Average and Budget exchange tables. One of current, historical, average, budget, or unmapped. Note that MC40600''s purpose is inferred rather than documented by Microsoft, so treat unmapped as a real category, not a defect.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table, e.g. main.prod_gp_apfm_dbo_live.mc00100.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_exchange_rate PRIMARY KEY (exchange_rate_key),
  CONSTRAINT fk_exchange_rate_currency FOREIGN KEY (currency_key) REFERENCES finance.reference.dim_currency
)
COMMENT 'Exchange rates as maintained in GP. One row per legal entity, exchange table, currency, rate date and rate time. A fact rather than a lookup because consolidated APFM + CAPFM reporting depends on it.'
CLUSTER BY (rate_date, gp_currency_id);

-- ---------------------------------------------------------------------
-- dim_legal_entity
-- ---------------------------------------------------------------------
-- Two real members, and this is a correction to how the degeneracy has
-- been described elsewhere. 100% of APFM GL activity — all 8,204,550 rows,
-- FY2000-2026 — carries Company account segment 10, so the company segment
-- is degenerate WITHIN APFM and no hierarchy should be built on it. But
-- APFM and CAPFM are two replicated companies and therefore two legal
-- entities. The dimension is real at catalog level even though the segment
-- is degenerate inside one company.

CREATE TABLE IF NOT EXISTS finance.reference.dim_legal_entity (
  legal_entity_key    BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code). Reserved members -1 Unknown, -2 Not Applicable, -3 Unresolved.',
  legal_entity_code   STRING               COMMENT 'APFM or CAPFM. The code stamped on every row of every fact in this catalog. Null on reserved members.',
  gp_company_id       INT                  COMMENT 'SY01500.CMPANYID.',
  gp_interid          STRING               COMMENT 'SY01500.INTERID. The GP company database name, which is what ties a row back to prod_gp_apfm_dbo vs prod_gp_capfm_dbo.',
  company_name        STRING               COMMENT 'SY01500.CMPNYNAM.',
  country_code        STRING               COMMENT 'SY01500.CMPCNTRY. CAPFM being Canadian is what makes multicurrency load-bearing rather than optional.',
  location_id         STRING               COMMENT 'SY01500.LOCATNID.',
  account_segment_separator STRING         COMMENT 'SY01500.ACSEGSEP. Needed to render a formatted account number; do not hardcode a hyphen.',
  functional_currency_key BIGINT           COMMENT 'FK to dim_currency. The entity''s functional currency, which is the denominator for every unconverted amount in that entity''s facts.',
  gp_created_date     DATE                 COMMENT 'SY01500.CREATDDT.',
  gp_modified_date    DATE                 COMMENT 'SY01500.MODIFDT.',
  is_reserved_member  BOOLEAN     NOT NULL COMMENT 'True for the -1/-2/-3 rows.',
  source_system       STRING      NOT NULL COMMENT 'GP, or SEED for reserved members.',
  source_table        STRING               COMMENT 'main.prod_gp_dynamics_dbo_live.sy01500 — the system database company list is authoritative, not the per-company copies.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_dim_legal_entity PRIMARY KEY (legal_entity_key),
  CONSTRAINT fk_legal_entity_currency FOREIGN KEY (functional_currency_key) REFERENCES finance.reference.dim_currency
)
COMMENT 'One row per GP company. Two real members today, APFM and CAPFM. Do not build a hierarchy on the GL company account segment: it is 10 on 100% of APFM activity and therefore carries no information within an entity.';

-- ---------------------------------------------------------------------
-- dim_gp_user
-- ---------------------------------------------------------------------
-- SY01400 carries a PASSWORD column. It is excluded from the projection
-- here on purpose, and the exclusion is the reason this dimension exists
-- rather than consumers reading sy01400 directly.

CREATE TABLE IF NOT EXISTS finance.reference.dim_gp_user (
  gp_user_key         BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(gp_user_id). Reserved members -1 Unknown, -2 Not Applicable, -3 Unresolved.',
  gp_user_id          STRING               COMMENT 'SY01400.USERID. The value that appears in LASTUSER, USWHPSTD, PSTUSRID, LSTUSRED across the GP tables. Trim before joining — GP char columns are space-padded.',
  user_name           STRING               COMMENT 'SY01400.USERNAME. A person''s name; treat as internal-employee data, not customer PII.',
  user_class          STRING               COMMENT 'SY01400.USRCLASS.',
  user_role           STRING               COMMENT 'SY01400.UserRole.',
  user_type           STRING               COMMENT 'SY01400.UserType.',
  user_status         STRING               COMMENT 'SY01400.UserStatus.',
  date_inactivated    DATE                 COMMENT 'SY01400.DateInactivated. GP blank-date sentinel 1900-01-01 mapped to NULL.',
  gp_created_date     DATE                 COMMENT 'SY01400.CREATDDT.',
  gp_modified_date    DATE                 COMMENT 'SY01400.MODIFDT.',
  is_reserved_member  BOOLEAN     NOT NULL COMMENT 'True for the -1/-2/-3 rows.',
  source_system       STRING      NOT NULL COMMENT 'GP, or SEED for reserved members.',
  source_table        STRING               COMMENT 'main.prod_gp_dynamics_dbo_live.sy01400 — the system user list is authoritative; the per-company copies record company access.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_dim_gp_user PRIMARY KEY (gp_user_key)
)
COMMENT 'One row per Dynamics GP user. Exists so that consumers resolving LASTUSER / USWHPSTD / PSTUSRID never read sy01400 directly, because sy01400 carries a PASSWORD column that must not propagate. PASSWORD, the UI colour preferences, and the browser fields are deliberately not carried here.';

ALTER TABLE finance.reference.dim_gp_user SET TAGS ('excludes_source_columns' = 'PASSWORD', 'contains_employee_names' = 'true');
