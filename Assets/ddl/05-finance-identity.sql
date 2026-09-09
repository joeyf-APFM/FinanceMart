-- =====================================================================
-- Finance Catalog — 05 — finance.identity
--
-- STATUS: NOT EXECUTED.
--
-- PII-bearing, and isolated in its own schema so that grants can be too.
-- The initial plan records that masking is pushed to a later phase because
-- everyone who will access this data has rights to see it. That is a
-- decision about today's audience and holds only as long as the audience
-- does. Isolating the schema is what makes it revisable later without
-- re-plumbing the marts: column masks on RM00101 disable entity matching,
-- so a Genie agent tuned against an unmasked dim_customer is invalidated
-- the day masking arrives. Keep agents pointed at the marts, not here.
--
-- COLUMN PROFILING REQUIRED. dim_customer below is written against real
-- RM00101 columns. The three bridges are NOT: their sources
-- (main.prod_fin_ipr_ipr.ipr, main.prod_fin_01_cst.mir,
-- main.prod_ygl_apfm.great_plains_customer_mapping) are not in the GP
-- metadata reference, and the only columns confirmed in the vault are the
-- ones named in the spine validation. Every other column below is a
-- placeholder to be replaced by a DESCRIBE, not an assertion. They are
-- marked PROFILE.
-- =====================================================================

-- ---------------------------------------------------------------------
-- dim_customer
-- ---------------------------------------------------------------------
-- Not a partner master, and the name must not be allowed to imply
-- otherwise. GP's "customer" is who APFM bills, and
-- great_plains_customer_mapping resolves it at business_unit_id grain — a
-- community. dim_partner is the conformed commercial counterparty in the
-- shared design, so dim_customer is the BILLING-ACCOUNT VIEW of a partner
-- and bridges to dim_partner rather than competing with it.
--
-- HISTORY TYPE: Type 1, overwriting. Not a choice — Fivetran replicates
-- RM00101 as current state, so no prior version of a customer attribute
-- exists to preserve. If Finance needs Type 2 on any attribute here, that
-- requires either CDC on the connector or a daily snapshot, and it can
-- only start collecting from the day it is built.
--
-- DELIBERATELY NOT CARRIED: RM00101.CRCRDNUM (credit card number),
-- CCRDXPDT (expiry) and CRCARDID. Propagating a card number into a mart is
-- a payment-card exposure independent of the decision to defer masking,
-- and there is no finance use case in the epic that needs it. If one
-- appears, it needs its own review, not a column added here quietly.

CREATE TABLE IF NOT EXISTS finance.identity.dim_customer (
  customer_key        BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, gp_customer_number). Legal entity is IN the key because GP customer numbers are company-scoped — the same CUSTNMBR in APFM and CAPFM is not necessarily the same counterparty. Reserved members -1 Unknown, -2 Not Applicable, -3 Unresolved.',
  legal_entity_code   STRING               COMMENT 'APFM or CAPFM. Null on reserved members.',
  legal_entity_key    BIGINT               COMMENT 'FK to finance.reference.dim_legal_entity.',
  gp_customer_number  STRING               COMMENT 'RM00101.CUSTNMBR. Trim before joining — GP char columns are space-padded, and an untrimmed join to ipr or the YGL mapping will silently return nothing.',
  parent_customer_number STRING            COMMENT 'RM00101.CPRCSTNM. GP''s parent/corporate customer. This is the closest thing GP has to a partner rollup and should be reconciled against dim_partner rather than used as a hierarchy on its own.',
  customer_name       STRING               COMMENT 'RM00101.CUSTNAME. PII.',
  statement_name      STRING               COMMENT 'RM00101.STMTNAME. PII.',
  short_name          STRING               COMMENT 'RM00101.SHRTNAME. PII.',
  contact_person      STRING               COMMENT 'RM00101.CNTCPRSN. PII — a named individual.',
  customer_class      STRING               COMMENT 'RM00101.CUSTCLAS. Confirm with Finance what the classes mean before exposing to a Genie agent; an undocumented class code invites a confident wrong answer.',
  address_line_1      STRING               COMMENT 'RM00101.ADDRESS1. PII.',
  address_line_2      STRING               COMMENT 'RM00101.ADDRESS2. PII.',
  address_line_3      STRING               COMMENT 'RM00101.ADDRESS3. PII.',
  city                STRING               COMMENT 'RM00101.CITY.',
  state_province      STRING               COMMENT 'RM00101.STATE.',
  postal_code         STRING               COMMENT 'RM00101.ZIP.',
  country             STRING               COMMENT 'RM00101.COUNTRY.',
  phone_1             STRING               COMMENT 'RM00101.PHONE1. PII.',
  phone_2             STRING               COMMENT 'RM00101.PHONE2. PII.',
  fax                 STRING               COMMENT 'RM00101.FAX. PII.',
  bank_name           STRING               COMMENT 'RM00101.BANKNAME. Financial PII. Carried because collections work needs it; a candidate for the first mask.',
  bank_branch         STRING               COMMENT 'RM00101.BNKBRNCH. Financial PII.',
  tax_registration_number STRING           COMMENT 'RM00101.TXRGNNUM. Tax identifier. Financial PII.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency, from RM00101.CURNCYID.',
  payment_terms_id    STRING               COMMENT 'RM00101.PYMTRMID.',
  salesperson_id      STRING               COMMENT 'RM00101.SLPRSNID.',
  sales_territory     STRING               COMMENT 'RM00101.SALSTERR.',
  credit_limit_type   INT                  COMMENT 'RM00101.CRLMTTYP. Coded; decode against the value lists in the GP reference rather than guessing.',
  credit_limit_amount DECIMAL(19,5)        COMMENT 'RM00101.CRLMTAMT.',
  balance_type        INT                  COMMENT 'RM00101.BALNCTYP. Balance-forward versus open-item. This changes how the apply trail behaves and therefore how aging must be computed.',
  statement_cycle     INT                  COMMENT 'RM00101.STMTCYCL.',
  is_on_hold          BOOLEAN              COMMENT 'RM00101.HOLD.',
  is_inactive         BOOLEAN              COMMENT 'RM00101.INACTIVE.',
  first_invoice_date  DATE                 COMMENT 'RM00101.FRSTINDT. GP blank-date sentinel 1900-01-01 mapped to NULL.',
  user_defined_1      STRING               COMMENT 'RM00101.USERDEF1. Semantics are an open decision in the epic — do not surface to a Genie agent until Finance says what it holds.',
  user_defined_2      STRING               COMMENT 'RM00101.USERDEF2. Same caveat as USERDEF1.',
  gp_created_date     DATE                 COMMENT 'RM00101.CREATDDT.',
  gp_modified_date    DATE                 COMMENT 'RM00101.MODIFDT.',
  partner_key         BIGINT               COMMENT 'Intended FK to the conformed dim_partner, which does not exist yet. Left nullable and WITHOUT a foreign-key constraint until it does. The column is present now so that the bridge is designed in rather than bolted on, and so that no one mistakes dim_customer for the partner master.',
  is_reserved_member  BOOLEAN     NOT NULL COMMENT 'True for the -1/-2/-3 rows.',
  history_type        STRING      NOT NULL COMMENT 'Always type_1. Stated as data rather than documentation so a consumer can see it without reading a note.',
  source_system       STRING      NOT NULL COMMENT 'GP, or SEED for reserved members.',
  source_table        STRING               COMMENT 'Guarded-layer table, e.g. main.prod_gp_apfm_dbo_live.rm00101.',
  _source_synced_at   TIMESTAMP            COMMENT '_fivetran_synced on the source row. NOT freshness — it advances only when the row changes.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_dim_customer PRIMARY KEY (customer_key),
  CONSTRAINT fk_customer_legal_entity FOREIGN KEY (legal_entity_key) REFERENCES finance.reference.dim_legal_entity,
  CONSTRAINT fk_customer_currency     FOREIGN KEY (currency_key)     REFERENCES finance.reference.dim_currency
)
COMMENT 'One row per GP customer, which is one BILLING ACCOUNT — not one partner and not one family. Type 1, overwriting, because the source replica carries current state only. PII-bearing: names, addresses, phone, bank name and branch, tax registration. Credit card columns from RM00101 are deliberately excluded. Open question for Finance: whether any GP customers are families or private-pay individuals, because that would change the grain rather than the label.'
CLUSTER BY (legal_entity_code, gp_customer_number);

ALTER TABLE finance.identity.dim_customer SET TAGS (
  'contains_pii' = 'true',
  'history_type' = 'type_1',
  'grain' = 'gp_billing_account',
  'not_a_partner_master' = 'true',
  'excludes_source_columns' = 'CRCRDNUM,CCRDXPDT,CRCARDID'
);

-- ---------------------------------------------------------------------
-- bridge_customer_to_family
-- ---------------------------------------------------------------------
-- This is one table, not a chain. `ipr` carries the GP key and the funnel
-- key on the same row for 99.28% of live rows. DO NOT route it through
-- YGL: prod_ygl_apfm has 481 tables, 94 lead-keyed, exactly one
-- family-keyed, and the GP mapping's grain is business_unit_id.
--
-- Coverage is a documented property of the model, not a caveat to be
-- discovered in month three: 100.00% for FY2023-2026 and roughly 1.8%
-- before mid-2022. Quote the bound or not at all — the bare all-time
-- figure of 51.85% undersells it, and an unqualified "100%" promises
-- history that does not exist.
--
-- And: any INNER join from ipr to GP silently drops most of the current
-- month. fin_customer_id is assigned at invoicing, so blank is a lifecycle
-- stage rather than a defect — 0.02% blank for January-created rows,
-- 77.74% for September. The corollary is a free use case: unbilled
-- move-ins are the rows where the spine is null and move_in is populated.

CREATE TABLE IF NOT EXISTS finance.identity.bridge_customer_to_family (
  customer_key        BIGINT               COMMENT 'FK to dim_customer. NULL is meaningful here and must not be filtered away: it means the charge has not been invoiced yet, which is the unbilled-move-in population.',
  gp_customer_number  STRING               COMMENT 'ipr.fin_customer_id. The GP spine key, at 97.92% row coverage and 97.24% distinct coverage.',
  lead_id             STRING               COMMENT 'ipr.lead_id. PROFILE — confirm the landed type; declared STRING here to avoid asserting an integer that may be a code.',
  family_file_id      STRING               COMMENT 'The funnel family key reached from lead_id. Resolves at 100.00% for FY2023-2026. PROFILE.',
  move_in_date        DATE                 COMMENT 'ipr.move_in. Populated with a null customer_key is the definition of an unbilled move-in.',
  first_charge_date   DATE                 COMMENT 'PROFILE — earliest ipr charge date for the pair, used to place the relationship in time.',
  coverage_era        STRING      NOT NULL COMMENT 'One of fy2023_plus (resolution measured at 100.00%), pre_mid_2022 (measured at roughly 1.8%), or transitional. Carried as a column so that any consumer aggregating across eras sees the discontinuity instead of averaging through it.',
  is_spine_resolved   BOOLEAN     NOT NULL COMMENT 'False where fin_customer_id is blank. Distinguishes "not yet invoiced" from "failed to match", which are different problems with different owners.',
  source_system       STRING      NOT NULL COMMENT 'IPR.',
  source_table        STRING      NOT NULL COMMENT 'main.prod_fin_ipr_ipr.ipr.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT fk_bridge_family_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer
)
COMMENT 'Bridge from GP billing account to the funnel family file, built from main.prod_fin_ipr_ipr.ipr alone because that table carries both keys on 99.28% of live rows. Grain is customer x family_file_id. Coverage is FY2023 forward at 100.00% and roughly 1.8% before mid-2022 — quote the bound, never the all-time figure. No primary key is declared: a customer legitimately maps to many families and a family to more than one customer, so this is a many-to-many bridge and asserting uniqueness would be false.'
CLUSTER BY (gp_customer_number);

ALTER TABLE finance.identity.bridge_customer_to_family SET TAGS ('cardinality' = 'many_to_many', 'coverage_floor' = 'fy2023', 'do_not_route_through' = 'ygl');

-- ---------------------------------------------------------------------
-- bridge_customer_to_salesforce
-- ---------------------------------------------------------------------
-- Use mir as the Salesforce bridge, NEVER as the GP spine.
-- mir.customer_billing_id matches GP at only 22.19%.

CREATE TABLE IF NOT EXISTS finance.identity.bridge_customer_to_salesforce (
  customer_key        BIGINT               COMMENT 'FK to dim_customer. Null where the Salesforce record carries a billing id GP does not recognise, which is most of them.',
  gp_customer_number  STRING               COMMENT 'mir.customer_billing_id, trimmed. Matches a GP customer on only 22.19% of rows.',
  salesforce_id       STRING               COMMENT 'mir.salesforce_id. PROFILE — confirm which Salesforce object this identifies before a consumer assumes Account.',
  match_status        STRING      NOT NULL COMMENT 'One of matched, unmatched_in_gp, ambiguous. Carried explicitly because a 22.19% match rate means the unmatched rows are the normal case and must be visible rather than lost to an inner join.',
  source_system       STRING      NOT NULL COMMENT 'CST.',
  source_table        STRING      NOT NULL COMMENT 'main.prod_fin_01_cst.mir.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT fk_bridge_sfdc_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer
)
COMMENT 'Bridge from GP billing account to Salesforce, built from main.prod_fin_01_cst.mir. A BRIDGE ONLY — mir.customer_billing_id matches GP at 22.19% and must never be used as the identity spine. The Salesforce-to-GP reconciliation use case in the epic is served by exposing the mismatch, not by hiding it.'
CLUSTER BY (gp_customer_number);

ALTER TABLE finance.identity.bridge_customer_to_salesforce SET TAGS ('cardinality' = 'many_to_many', 'measured_match_rate' = '0.2219', 'never_use_as_spine' = 'true');

-- ---------------------------------------------------------------------
-- bridge_customer_to_business_unit
-- ---------------------------------------------------------------------
-- The YGL mapping resolves a GP customer at business_unit_id grain — a
-- community. This is the table that proves dim_customer is a billing
-- account rather than a partner: one GP customer can bill for several
-- communities, and a community can change which customer bills it.

CREATE TABLE IF NOT EXISTS finance.identity.bridge_customer_to_business_unit (
  customer_key        BIGINT               COMMENT 'FK to dim_customer.',
  gp_customer_number  STRING               COMMENT 'The GP customer number as held in the YGL mapping, trimmed.',
  business_unit_id    STRING               COMMENT 'A community. PROFILE — confirm the landed type and whether it is unique across YGL tenants.',
  valid_from          DATE                 COMMENT 'great_plains_customer_mapping.begin_date. The mapping is effective-dated, which is why this bridge is not a simple lookup.',
  valid_to            DATE                 COMMENT 'great_plains_customer_mapping.end_date. Null means currently effective. PROFILE — confirm whether the source uses null or a high-date sentinel.',
  is_current          BOOLEAN     NOT NULL COMMENT 'Derived. True where the row is effective as of the load date.',
  source_system       STRING      NOT NULL COMMENT 'YGL.',
  source_table        STRING      NOT NULL COMMENT 'main.prod_ygl_apfm.great_plains_customer_mapping.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT fk_bridge_bu_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer
)
COMMENT 'Effective-dated bridge from GP billing account to YGL business unit (a community), from main.prod_ygl_apfm.great_plains_customer_mapping. This is the evidence that a GP customer is a billing account and not a partner: the mapping resolves at community grain and changes over time. Any point-in-time question must filter on valid_from / valid_to rather than taking the current row.'
CLUSTER BY (gp_customer_number, business_unit_id);

ALTER TABLE finance.identity.bridge_customer_to_business_unit SET TAGS ('cardinality' = 'many_to_many', 'effective_dated' = 'true');
