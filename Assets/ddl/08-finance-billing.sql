-- =====================================================================
-- Finance Catalog — 08 — finance.billing
--
-- STATUS: NOT EXECUTED.
--
-- NOTHING IN THIS SCHEMA IS NAMED REVENUE. Referral charges and invoice
-- lines are billing activity. Recognised revenue is what posts to the
-- general ledger, and it lives in finance.general_ledger. The moment a
-- column here is called revenue, someone will reconcile it against the
-- income statement and it will not tie — because these two measure
-- different things at different times, not because either is wrong. The
-- schema is called billing for that reason and every table here is tagged
-- measure_class = operational_not_recognized.
--
-- COLUMN PROFILING REQUIRED, MORE THAN ANYWHERE ELSE IN THIS BUILD. The
-- charging-platform tables — main.prod_fin_ipr_ipr.ipr,
-- main.prod_fin_ipr_ipr.ipr_invoice, main.prod_fin_01_cst.mir — are NOT in
-- the Dynamics GP metadata reference, and the vault confirms only the
-- columns that the spine validation touched: fin_customer_id, lead_id,
-- move_in, gp_invoice_num, salesforce_id, customer_billing_id,
-- business_unit_id, begin_date, end_date, family_file_id.
--
-- Every other IPR column below is a PLACEHOLDER marked PROFILE. Replace it
-- from a DESCRIBE before writing a line of load code. The sop30300 columns
-- ARE real — that table is in the reference.
--
--   DESCRIBE TABLE EXTENDED main.prod_fin_ipr_ipr.ipr;
--   DESCRIBE TABLE EXTENDED main.prod_fin_ipr_ipr.ipr_invoice;
--
-- WHAT IS MISSING, AND IT IS LOAD-BEARING: SOP30200, the sales document
-- HEADER history table, is not replicated. Only sop30300 (line history) is.
-- The consequence is not cosmetic — there is no reliable document-level
-- customer, document date, void status, or salesperson for an invoice. Each
-- of those absences is labelled on the columns below rather than left for a
-- consumer to discover when a total comes out wrong.
-- =====================================================================

-- ---------------------------------------------------------------------
-- fact_referral_charge
-- ---------------------------------------------------------------------
-- The charging platform's own record of what was charged. Grain must be
-- confirmed by profiling before this is built: the vault establishes that
-- ipr carries fin_customer_id, lead_id and move_in on one row, and that
-- 99.28% of live rows carry both keys, but it does not establish whether
-- one row is one charge, one charge period, or one move-in.

CREATE TABLE IF NOT EXISTS finance.billing.fact_referral_charge (
  referral_charge_key BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic over the natural key, which is UNCONFIRMED — profile ipr for its actual grain first (test T-10). Do not guess the key: a wrong grain here double counts every downstream billing figure.',
  customer_key        BIGINT               COMMENT 'FK to finance.identity.dim_customer, resolved on fin_customer_id. NULL IS MEANINGFUL AND MUST NOT BE FILTERED AWAY: fin_customer_id is assigned at invoicing, so a null means not yet invoiced. Measured at 0.02% blank for January-created rows and 77.74% for September — an inner join to GP silently drops most of the current month.',
  gp_customer_number  STRING               COMMENT 'ipr.fin_customer_id, trimmed. 97.92% row coverage, 97.24% distinct coverage against GP.',
  lead_id             STRING               COMMENT 'ipr.lead_id. PROFILE the landed type — declared STRING rather than asserting an integer.',
  family_file_id      STRING               COMMENT 'Resolved through finance.identity.bridge_customer_to_family. 100.00% for FY2023-2026, roughly 1.8% before mid-2022. PROFILE.',
  business_unit_id    STRING               COMMENT 'The community. PROFILE — confirm whether ipr carries it directly or it must come through bridge_customer_to_business_unit as of the charge date.',
  move_in_date        DATE                 COMMENT 'ipr.move_in. A populated move_in with a null customer_key is the unbilled-move-in population, which is a use case rather than a data quality problem.',
  charge_date         DATE                 COMMENT 'PROFILE — the date the charge was raised. Confirm which of the several date columns in ipr this is before choosing.',
  charge_period_start DATE                 COMMENT 'PROFILE.',
  charge_period_end   DATE                 COMMENT 'PROFILE.',
  date_key            INT                  COMMENT 'FK to common.calendar.dim_date, on charge_date.',
  charge_type         STRING               COMMENT 'PROFILE. The billing stream this charge belongs to; mart_billing_by_stream aggregates on it, so its domain must be enumerated before that mart is built rather than after.',
  charge_amount       DECIMAL(19,5)        COMMENT 'PROFILE — confirm the source type and scale. DECIMAL, never DOUBLE: a float amount will not reconcile to GP and the difference will be blamed on the mapping.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency. PROFILE whether ipr records a currency at all; if it does not, default to the legal entity''s functional currency and say so here rather than assuming USD silently.',
  gp_invoice_number   STRING               COMMENT 'The GP invoice this charge was billed on, reached through ipr_invoice.gp_invoice_num. Null until invoiced.',
  invoice_line_key    BIGINT               COMMENT 'FK to fact_invoice_line where the charge has been matched to a GP invoice line. Null where it has not — see the coverage figures on that table.',
  is_invoiced         BOOLEAN     NOT NULL COMMENT 'Derived: whether fin_customer_id is populated. Distinguishes not-yet-invoiced from failed-to-match, which are different problems with different owners.',
  source_system       STRING      NOT NULL COMMENT 'IPR.',
  source_table        STRING      NOT NULL COMMENT 'main.prod_fin_ipr_ipr.ipr.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_referral_charge PRIMARY KEY (referral_charge_key),
  CONSTRAINT fk_referral_charge_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer
)
COMMENT 'Referral charges from the charging platform, main.prod_fin_ipr_ipr.ipr. Grain is UNCONFIRMED and must be profiled before build. Billing activity, NOT recognised revenue. A null customer_key means not yet invoiced, which is a lifecycle stage — the unbilled-move-in population is exactly the rows where customer_key is null and move_in_date is populated.'
CLUSTER BY (charge_date, gp_customer_number);

ALTER TABLE finance.billing.fact_referral_charge SET TAGS (
  'measure_class' = 'operational_not_recognized',
  'grain' = 'unconfirmed_profile_first',
  'schema_source' = 'not_in_gp_reference',
  'null_key_is_meaningful' = 'customer_key'
);

-- ---------------------------------------------------------------------
-- fact_invoice_line
-- ---------------------------------------------------------------------
-- From sop30300, the sales transaction LINE history. These columns are
-- real — sop30300 is in the GP reference, all 119 columns of it.
--
-- Replicated for APFM ONLY. sop30300 is absent from prod_gp_capfm_dbo, so
-- this fact covers one legal entity. That is stamped in the table comment
-- and in a tag, because a consumer comparing invoiced amounts across
-- entities will otherwise read CAPFM's absence as zero.
--
-- The bridge from IPR to GP is measured, not assumed: 613,879 of 622,066
-- ipr_invoice rows carry a gp_invoice_num that matches a sopnumbe, which is
-- 98.7%. The end-to-end ceiling is lower — 60.6% of REF documents have an
-- associated IPR row. Both figures belong in the model.

CREATE TABLE IF NOT EXISTS finance.billing.fact_invoice_line (
  invoice_line_key    BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, sop_type, sop_number, line_item_sequence, component_sequence). Component sequence is in the key because sop30300 uses it for kit components, and omitting it collapses distinct lines.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM only. sop30300 is not replicated for CAPFM.',
  legal_entity_key    BIGINT               COMMENT 'FK to finance.reference.dim_legal_entity.',
  sop_type            INT         NOT NULL COMMENT 'SOP30300.SOPTYPE. Quote, order, invoice, return, back order. Filter to invoices explicitly — this table holds all types and a total across them is meaningless.',
  sop_number          STRING      NOT NULL COMMENT 'SOP30300.SOPNUMBE. The document number, and the join key to ipr_invoice.gp_invoice_num.',
  line_item_sequence  BIGINT      NOT NULL COMMENT 'SOP30300.LNITMSEQ.',
  component_sequence  BIGINT      NOT NULL COMMENT 'SOP30300.CMPNTSEQ. Non-zero for kit components.',
  customer_key        BIGINT               COMMENT 'FK to finance.identity.dim_customer. RESOLVED INDIRECTLY, because SOP30200 (the header) is not replicated and sop30300 carries no CUSTNMBR. The resolution path is sop_number to ipr_invoice.gp_invoice_num to ipr.fin_customer_id, which means the customer on an invoice line is only as good as the IPR bridge — 98.7% of ipr_invoice rows, and 60.6% of REF documents having an IPR row at all.',
  gp_customer_number  STRING               COMMENT 'Resolved as above, not read from source. Never present this as authoritative document-level customer; it is an inference from the charging platform.',
  ship_to_name        STRING               COMMENT 'SOP30300.ShipToName. PII. The one name sop30300 carries directly, and it is a ship-to rather than a bill-to, so it is NOT a substitute for the header customer.',
  ship_to_address_code STRING              COMMENT 'SOP30300.PRSTADCD.',
  ship_to_city        STRING               COMMENT 'SOP30300.CITY.',
  ship_to_state       STRING               COMMENT 'SOP30300.STATE.',
  requested_ship_date DATE                 COMMENT 'SOP30300.ReqShipDate. GP blank-date sentinel 1900-01-01 mapped to NULL.',
  fulfilled_date      DATE                 COMMENT 'SOP30300.FUFILDAT.',
  actual_ship_date    DATE                 COMMENT 'SOP30300.ACTLSHIP. THE CLOSEST AVAILABLE PROXY FOR A DOCUMENT DATE, and it is a proxy: the real document date lives on SOP30200, which is not replicated. Label it as a ship date wherever it is surfaced. Do not silently present it as the invoice date.',
  date_key            INT                  COMMENT 'FK to common.calendar.dim_date, on actual_ship_date, with the proxy caveat above.',
  item_number         STRING               COMMENT 'SOP30300.ITEMNMBR.',
  item_description    STRING               COMMENT 'SOP30300.ITEMDESC.',
  unit_of_measure     STRING               COMMENT 'SOP30300.UOFM.',
  location_code       STRING               COMMENT 'SOP30300.LOCNCODE.',
  quantity            DECIMAL(19,5)        COMMENT 'SOP30300.QUANTITY.',
  unit_price          DECIMAL(19,5)        COMMENT 'SOP30300.UNITPRCE.',
  extended_price      DECIMAL(19,5)        COMMENT 'SOP30300.XTNDPRCE. The line total in functional currency.',
  originating_extended_price DECIMAL(19,5) COMMENT 'SOP30300.OXTNDPRC, originating currency.',
  unit_cost           DECIMAL(19,5)        COMMENT 'SOP30300.UNITCOST.',
  extended_cost       DECIMAL(19,5)        COMMENT 'SOP30300.EXTDCOST.',
  tax_amount          DECIMAL(19,5)        COMMENT 'SOP30300.TAXAMNT.',
  trade_discount_amount DECIMAL(19,5)      COMMENT 'SOP30300.TRDISAMT.',
  markdown_amount     DECIMAL(19,5)        COMMENT 'SOP30300.MRKDNAMT.',
  sales_account_index INT                  COMMENT 'SOP30300.SLSINDX. Joins to finance.general_ledger.dim_gl_account, which is how an invoice line ties to the account it credited.',
  cost_of_sales_account_index INT          COMMENT 'SOP30300.CSLSINDX.',
  currency_index      INT                  COMMENT 'SOP30300.CURRNIDX.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency, resolved from CURRNIDX.',
  decimal_places_currency INT              COMMENT 'SOP30300.DECPLCUR. A one-based offset, so 3 means 2 decimal places. Read it rather than assuming two.',
  salesperson_id      STRING               COMMENT 'SOP30300.SLPRSNID. Present at LINE level. The document-level salesperson is on SOP30200 and is unavailable, so a per-document salesperson has to be inferred from its lines and can disagree across them.',
  sales_territory     STRING               COMMENT 'SOP30300.SALSTERR.',
  price_level         STRING               COMMENT 'SOP30300.PRCLEVEL.',
  trx_source          STRING               COMMENT 'SOP30300.TRXSORCE. Ties the line to the GL batch that posted it.',
  line_error_code     INT                  COMMENT 'SOP30300.SOPLNERR.',
  is_non_inventory    BOOLEAN              COMMENT 'SOP30300.NONINVEN. Expected true for most APFM lines, since referral fees are not stocked goods.',
  void_status         STRING               COMMENT 'DELIBERATELY NULL AND KEPT AS A COLUMN. SOP30300 carries no void flag; void status lives on SOP30200, which is not replicated. The column exists so the gap is visible in the schema instead of being an unstated assumption that nothing here is voided.',
  referral_charge_key BIGINT               COMMENT 'FK to fact_referral_charge where the line has been matched back to an IPR charge.',
  is_ipr_matched       BOOLEAN    NOT NULL COMMENT 'Whether this line''s document appears in ipr_invoice. 98.7% of ipr_invoice rows bridge to a sopnumbe; only 60.6% of REF documents have an IPR row at all. Carried as data so that the ceiling is visible in every aggregate rather than living in a footnote.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'main.prod_gp_apfm_dbo_live.sop30300.',
  _source_synced_at   TIMESTAMP            COMMENT '_fivetran_synced on the source row. NOT freshness.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_invoice_line PRIMARY KEY (invoice_line_key),
  CONSTRAINT fk_invoice_line_customer FOREIGN KEY (customer_key)        REFERENCES finance.identity.dim_customer,
  CONSTRAINT fk_invoice_line_currency FOREIGN KEY (currency_key)        REFERENCES finance.reference.dim_currency,
  CONSTRAINT fk_invoice_line_charge   FOREIGN KEY (referral_charge_key) REFERENCES finance.billing.fact_referral_charge
)
COMMENT 'One sales document line from sop30300, APFM only — sop30300 is not replicated for CAPFM. SOP30200, the document header, is NOT replicated, so this fact has no source-of-truth document date, document-level customer, void status, or document salesperson; each absence is labelled on the column rather than inferred silently. Billing activity, not recognised revenue.'
CLUSTER BY (legal_entity_code, sop_number);

ALTER TABLE finance.billing.fact_invoice_line SET TAGS (
  'measure_class' = 'operational_not_recognized',
  'grain' = 'sop_document_line',
  'covers_legal_entities' = 'APFM',
  'missing_header_table' = 'SOP30200',
  'ipr_bridge_rate' = '0.987',
  'ref_with_ipr_rate' = '0.606'
);

-- ---------------------------------------------------------------------
-- mart_billing_by_stream
-- ---------------------------------------------------------------------
-- Billed activity by stream and period. The whole value of this mart is
-- that it aggregates over a bridge with a measured ceiling, so the ceiling
-- is in the grain rather than in a note beside it.

CREATE TABLE IF NOT EXISTS finance.billing.mart_billing_by_stream (
  fiscal_period_key   BIGINT      NOT NULL COMMENT 'FK to common.calendar.dim_fiscal_calendar at period_level = period.',
  fiscal_year         INT         NOT NULL COMMENT 'Denormalized for query convenience.',
  period_number       INT         NOT NULL COMMENT 'Denormalized for query convenience.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM. Note that invoice-line measures are APFM-only; a CAPFM row here will carry charge measures and null invoice measures, and that is correct rather than missing data.',
  billing_stream      STRING      NOT NULL COMMENT 'The charge type or product stream. Domain must be enumerated from ipr before this mart is built (test T-11) — an unenumerated stream column becomes an ever-growing pivot no one can validate.',
  business_unit_id    STRING               COMMENT 'The community, where resolvable. PROFILE.',
  charge_amount       DECIMAL(19,5)        COMMENT 'Sum of fact_referral_charge.charge_amount over the grain. What the charging platform says was charged.',
  charge_count        BIGINT               COMMENT 'Number of charges.',
  invoiced_amount     DECIMAL(19,5)        COMMENT 'Sum of fact_invoice_line.extended_price for lines matched to those charges. NULL rather than zero where the invoice side is not available for the entity — see the APFM-only note above.',
  invoiced_line_count BIGINT               COMMENT 'Number of matched invoice lines.',
  unbilled_charge_amount DECIMAL(19,5)     COMMENT 'Sum of charges with no customer resolved — not yet invoiced. This is a first-class measure, not a residual: it is the unbilled-move-in exposure and it is what the 77.74% September blank rate actually means in dollars.',
  ipr_matched_rate    DECIMAL(9,6)         COMMENT 'Proportion of the period''s charges matched to a GP invoice line. Carried per period because the estate-wide 98.7% and 60.6% figures are averages, and a period whose rate has collapsed should be visible before someone builds a forecast on it.',
  measure_class       STRING      NOT NULL COMMENT 'Always operational_not_recognized. Stated as data so that a consumer reading only this table still learns it is not revenue.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_mart_billing_by_stream PRIMARY KEY (fiscal_period_key, legal_entity_code, billing_stream, business_unit_id),
  CONSTRAINT fk_billing_stream_period FOREIGN KEY (fiscal_period_key) REFERENCES common.calendar.dim_fiscal_calendar
)
COMMENT 'Billed and unbilled activity by fiscal period, legal entity, stream and community. NOT revenue — this is billing activity, and reconciling it to the income statement will not tie because the two measure different things at different times. ipr_matched_rate is carried per period so the coverage ceiling travels with the numbers.'
CLUSTER BY (fiscal_year, legal_entity_code);

ALTER TABLE finance.billing.mart_billing_by_stream SET TAGS (
  'measure_class' = 'operational_not_recognized',
  'grain' = 'period_x_entity_x_stream_x_business_unit',
  'do_not_reconcile_to' = 'income_statement'
);
