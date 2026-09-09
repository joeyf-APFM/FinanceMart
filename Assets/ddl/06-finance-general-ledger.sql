-- =====================================================================
-- Finance Catalog — 06 — finance.general_ledger
--
-- STATUS: NOT EXECUTED.
--
-- The posted ledger and everything derived from it. This is the ONLY
-- schema in the catalog where an amount may be called recognized revenue.
-- Operational referral amounts live in finance.billing and must never be
-- presented as the same measure.
-- =====================================================================

-- ---------------------------------------------------------------------
-- dim_gl_account
-- ---------------------------------------------------------------------
-- SY00300 is the reason the segment layout is VERIFIABLE rather than
-- assumed. It carries SGMTNUMB, SGMTNAME, LOFSGMNT, MXLENSEG and
-- SegmentWidth, so the number of segments actually in use, their names and
-- their lengths are readable from the replica. GL00100 physically has five
-- ACTNUMBR columns whether or not five are in use; do not infer the count
-- from the column list. Segment names below are denormalised from SY00300
-- onto every account row on purpose: a Genie agent answers far better
-- against a flat named column than against a join it has to discover.

CREATE TABLE IF NOT EXISTS finance.general_ledger.dim_gl_account (
  account_key         BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, account_index). Legal entity is IN the key because ACTINDX is company-scoped — the same index in APFM and CAPFM is a different account. Reserved members -1 Unknown, -2 Not Applicable, -3 Unresolved.',
  legal_entity_code   STRING               COMMENT 'APFM or CAPFM. Null on reserved members.',
  legal_entity_key    BIGINT               COMMENT 'FK to finance.reference.dim_legal_entity.',
  account_index       INT                  COMMENT 'GL00100.ACTINDX. GP''s internal account key and the column every GL fact actually carries. Retained because a surrogate never replaces the source key.',
  account_number      STRING               COMMENT 'The formatted account number, segments joined with SY01500.ACSEGSEP. Do not hardcode a hyphen.',
  account_alias       STRING               COMMENT 'GL00100.ACTALIAS.',
  account_description STRING               COMMENT 'GL00100.ACTDESCR.',
  segments_in_use     INT                  COMMENT 'From SY00300. Read this rather than assuming five. A pipeline that hardcodes five will keep working right up until the account format changes.',
  segment_1_code      STRING               COMMENT 'GL00100.ACTNUMBR_1.',
  segment_1_name      STRING               COMMENT 'SY00300.SGMTNAME for segment 1. For APFM this is the Company segment, which is 10 on 100% of activity — degenerate within the entity, so build no hierarchy on it.',
  segment_1_description STRING             COMMENT 'GL40200.DSCRIPTN for segment 1''s value.',
  segment_2_code      STRING               COMMENT 'GL00100.ACTNUMBR_2.',
  segment_2_name      STRING               COMMENT 'SY00300.SGMTNAME for segment 2.',
  segment_2_description STRING             COMMENT 'GL40200.DSCRIPTN for segment 2''s value.',
  segment_3_code      STRING               COMMENT 'GL00100.ACTNUMBR_3.',
  segment_3_name      STRING               COMMENT 'SY00300.SGMTNAME for segment 3.',
  segment_3_description STRING             COMMENT 'GL40200.DSCRIPTN for segment 3''s value.',
  segment_4_code      STRING               COMMENT 'GL00100.ACTNUMBR_4.',
  segment_4_name      STRING               COMMENT 'SY00300.SGMTNAME for segment 4.',
  segment_4_description STRING             COMMENT 'GL40200.DSCRIPTN for segment 4''s value.',
  segment_5_code      STRING               COMMENT 'GL00100.ACTNUMBR_5.',
  segment_5_name      STRING               COMMENT 'SY00300.SGMTNAME for segment 5.',
  segment_5_description STRING             COMMENT 'GL40200.DSCRIPTN for segment 5''s value.',
  main_account_segment STRING              COMMENT 'GL00100.MNACSGMT, the natural account. SY00300.MNSEGIND identifies which position is the main segment — read it rather than assuming a position.',
  account_type        INT                  COMMENT 'GL00100.ACCTTYPE. Coded; decode from the value lists in the GP reference.',
  posting_type        INT                  COMMENT 'GL00100.PSTNGTYP. Balance-sheet versus profit-and-loss. This is what determines whether a year-end close zeroes the account, so it drives the P/L close exclusion on the fact.',
  typical_balance     INT                  COMMENT 'GL00100.TPCLBLNC. Debit or credit. Needed to present a signed amount without guessing.',
  account_category_number INT              COMMENT 'GL00100.ACCATNUM.',
  account_category_description STRING      COMMENT 'GL00102.ACCATDSC.',
  fixed_or_variable   INT                  COMMENT 'GL00100.FXDORVAR.',
  decimal_places      INT                  COMMENT 'GL00100.DECPLACS. GP''s one-based offset, same encoding caveat as dim_currency.',
  is_active           BOOLEAN              COMMENT 'GL00100.ACTIVE.',
  allows_account_entry BOOLEAN             COMMENT 'GL00100.ACCTENTR.',
  user_defined_1      STRING               COMMENT 'GL00100.USERDEF1. Semantics are an open decision in the epic.',
  user_defined_2      STRING               COMMENT 'GL00100.USERDEF2. Same caveat.',
  gp_created_date     DATE                 COMMENT 'GL00100.CREATDDT. GP blank-date sentinel 1900-01-01 mapped to NULL.',
  gp_modified_date    DATE                 COMMENT 'GL00100.MODIFDT.',
  is_reserved_member  BOOLEAN     NOT NULL COMMENT 'True for the -1/-2/-3 rows.',
  history_type        STRING      NOT NULL COMMENT 'Always type_1 — the source replica carries current state only.',
  source_system       STRING      NOT NULL COMMENT 'GP, or SEED for reserved members.',
  source_table        STRING               COMMENT 'Guarded-layer tables the row was assembled from.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_dim_gl_account PRIMARY KEY (account_key),
  CONSTRAINT fk_gl_account_legal_entity FOREIGN KEY (legal_entity_key) REFERENCES finance.reference.dim_legal_entity
)
COMMENT 'One row per GP account index (ACTINDX) per legal entity. Assembled from GL00100 (account master), GL00102 (category descriptions), GL40200 (segment value descriptions) and SY00300 (account format). GL00105, the Account Index Master, is NOT replicated — where a join would normally go through it, this dimension is the substitute.'
CLUSTER BY (legal_entity_code, account_number);

ALTER TABLE finance.general_ledger.dim_gl_account SET TAGS ('history_type' = 'type_1', 'grain' = 'legal_entity_x_account_index', 'substitutes_for_unreplicated' = 'GL00105');

-- ---------------------------------------------------------------------
-- fact_gl_posting
-- ---------------------------------------------------------------------
-- One posted GL distribution line. gl20000 is the OPEN year, gl30000 is
-- CLOSED years. Union them and never present either alone — a report built
-- on gl20000 only silently covers one fiscal year.
--
-- The two tables are structurally identical apart from the year column:
-- gl20000.OPENYEAR versus gl30000.HSTYEAR. Both carry 64 columns. Only the
-- ones with a stated finance use are lifted here; the rest stay available
-- in the guarded layer rather than being copied for completeness.
--
-- DO NOT HARDCODE THE BBF AND P/L EXCLUSION. Query 03 in the query
-- research catalog excludes beginning-balance-forward and profit-and-loss
-- close entries by default. That is right for activity reporting and wrong
-- for an audit extract, so it is a FLAG on the fact, not a filter in a
-- view. The flags below are derived from SOURCDOC; the GP convention is
-- 'BBF' and 'P/L' but the actual distinct values in the replica must be
-- profiled before the derivation ships (test T-06).

CREATE TABLE IF NOT EXISTS finance.general_ledger.fact_gl_posting (
  gl_posting_key      BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, fiscal_year, journal_entry_number, receipt_trx_sequence, sequence_number). Deterministic rather than an identity column so that a full reload does not renumber and orphan downstream references — and because Delta identity columns cannot be populated by CTAS, which would constrain the load pattern for no benefit.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM. Stamped on every row because both companies are unioned into this fact. GP identifiers are company-scoped, so this belongs in every natural key.',
  legal_entity_key    BIGINT               COMMENT 'FK to finance.reference.dim_legal_entity.',
  fiscal_year         INT         NOT NULL COMMENT 'gl20000.OPENYEAR for open-year rows, gl30000.HSTYEAR for closed-year rows. The single column that reconciles the two source tables.',
  fiscal_period       INT                  COMMENT 'PERIODID. Period 0 carries beginning-balance-forward and is not a data error.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar at period_level = period. Deliberately separate from date_key: the period an amount is recognized in is not always the period its transaction date falls in, and collapsing the two is what makes a restated amount impossible to explain.',
  journal_entry_number BIGINT     NOT NULL COMMENT 'JRNENTRY. Unique within a company and year, not across them.',
  receipt_trx_sequence BIGINT              COMMENT 'RCTRXSEQ.',
  sequence_number     BIGINT      NOT NULL COMMENT 'SEQNUMBR. The distribution line within the journal entry. This is what makes the grain a line rather than an entry.',
  account_key         BIGINT               COMMENT 'FK to dim_gl_account.',
  account_index       INT                  COMMENT 'ACTINDX as replicated.',
  transaction_date    DATE                 COMMENT 'TRXDATE. GP blank-date sentinel 1900-01-01 mapped to NULL.',
  document_date       DATE                 COMMENT 'DOCDATE.',
  originating_post_date DATE               COMMENT 'ORPSTDDT.',
  date_key            INT                  COMMENT 'FK to common.calendar.dim_date, on transaction_date. Declared INT on the assumption of a yyyymmdd surrogate; confirm against the promoted dim_date before building.',
  debit_amount        DECIMAL(19,5)        COMMENT 'DEBITAMT, functional currency.',
  credit_amount       DECIMAL(19,5)        COMMENT 'CRDTAMNT, functional currency.',
  net_amount          DECIMAL(19,5)        COMMENT 'Derived: debit_amount - credit_amount. Present so that no consumer has to choose a sign convention, and so that every consumer chooses the same one.',
  originating_debit_amount  DECIMAL(19,5)  COMMENT 'ORDBTAMT, originating (transaction) currency.',
  originating_credit_amount DECIMAL(19,5)  COMMENT 'ORCRDAMT, originating currency.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency.',
  gp_currency_id      STRING               COMMENT 'CURNCYID as replicated.',
  gp_currency_index   INT                  COMMENT 'CURRNIDX as replicated.',
  exchange_rate       DECIMAL(19,7)        COMMENT 'XCHGRATE.',
  denomination_exchange_rate DECIMAL(19,7) COMMENT 'DENXRATE.',
  exchange_rate_date  DATE                 COMMENT 'EXCHDATE.',
  rate_calculation_method INT              COMMENT 'RTCLCMTD. Multiply or divide. Applying the wrong direction inverts every translated amount, so it must be read rather than assumed.',
  rate_type_id        STRING               COMMENT 'RATETPID.',
  exchange_table_id   STRING               COMMENT 'EXGTBLID. Joins to finance.reference.fact_exchange_rate for rate provenance.',
  multicurrency_state INT                  COMMENT 'MCTRXSTT.',
  source_document     STRING               COMMENT 'SOURCDOC. The column the BBF and P/L flags are derived from.',
  reference_text      STRING               COMMENT 'REFRENCE.',
  description         STRING               COMMENT 'DSCRIPTN.',
  trx_source          STRING               COMMENT 'TRXSORCE. The audit-trail code, which is how a posting is traced back to the subledger batch that created it.',
  series_id           INT                  COMMENT 'SERIES. Same code set as SY40100.SERIES: 1 All, 2 Financial, 3 Sales, 4 Purchasing, 5 Inventory, 6 Payroll - USA, 7 Project. This is the column that ties a posting to the period-close series that governs it.',
  originating_trx_type INT                 COMMENT 'ORTRXTYP.',
  originating_document_number STRING       COMMENT 'ORDOCNUM.',
  originating_control_number  STRING       COMMENT 'ORCTRNUM.',
  originating_master_id   STRING           COMMENT 'ORMSTRID. For receivables postings this is the GP customer number, which is how a GL row is attributed to a customer without a subledger join.',
  originating_master_name STRING           COMMENT 'ORMSTRNM. PII-adjacent: for receivables postings this is a customer name.',
  originating_source  STRING               COMMENT 'ORGNTSRC.',
  ledger_id           INT                  COMMENT 'Ledger_ID.',
  posting_number      INT                  COMMENT 'PSTGNMBR.',
  posted_by_user_id   STRING               COMMENT 'USWHPSTD. Joins to finance.reference.dim_gp_user.',
  last_modified_by_user_id STRING          COMMENT 'LASTUSER.',
  approval_user_id    STRING               COMMENT 'APRVLUSERID.',
  approval_date       DATE                 COMMENT 'APPRVLDT.',
  is_voided           BOOLEAN              COMMENT 'VOIDED.',
  is_adjustment       BOOLEAN              COMMENT 'Adjustment_Transaction.',
  is_intercompany     BOOLEAN              COMMENT 'ICTRX.',
  originating_company_id STRING            COMMENT 'ORCOMID.',
  is_beginning_balance_forward BOOLEAN NOT NULL COMMENT 'Derived from SOURCDOC. True for the year-end beginning-balance-forward entries. A FLAG, not a filter: excluding these is right for activity reporting and wrong for an audit extract. Derivation must be validated against the actual distinct SOURCDOC values in the replica (test T-06).',
  is_profit_loss_close BOOLEAN    NOT NULL COMMENT 'Derived from SOURCDOC. True for the year-end profit-and-loss close entries. Same flag-not-filter rule.',
  is_history          BOOLEAN     NOT NULL COMMENT 'True where the row came from gl30000 (a closed year), false where it came from gl20000 (the open year). Lets a consumer reproduce a single-table query without losing the union.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table the row came from, e.g. main.prod_gp_apfm_dbo_live.gl20000.',
  _source_synced_at   TIMESTAMP            COMMENT '_fivetran_synced on the source row. NOT freshness. A stale value on gl30000 rows is the fiscal-year close, not a broken connector.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_gl_posting PRIMARY KEY (gl_posting_key),
  CONSTRAINT fk_gl_posting_account      FOREIGN KEY (account_key)       REFERENCES finance.general_ledger.dim_gl_account,
  CONSTRAINT fk_gl_posting_legal_entity FOREIGN KEY (legal_entity_key)  REFERENCES finance.reference.dim_legal_entity,
  CONSTRAINT fk_gl_posting_currency     FOREIGN KEY (currency_key)      REFERENCES finance.reference.dim_currency,
  CONSTRAINT fk_gl_posting_period       FOREIGN KEY (fiscal_period_key) REFERENCES common.calendar.dim_fiscal_calendar
)
COMMENT 'One posted GL distribution line, gl20000 (open year) unioned with gl30000 (closed years) across both companies. This is where recognized revenue lives. BBF and P/L close entries are flagged, not filtered. Do not query gl20000 alone: it covers one fiscal year and looks complete.'
CLUSTER BY (legal_entity_code, fiscal_year, fiscal_period, account_index);

ALTER TABLE finance.general_ledger.fact_gl_posting SET TAGS (
  'grain' = 'posted_gl_distribution_line',
  'measure_class' = 'recognized',
  'unions' = 'gl20000,gl30000',
  'both_legal_entities' = 'true'
);

-- ---------------------------------------------------------------------
-- fact_gl_posting_work
-- ---------------------------------------------------------------------
-- One UNPOSTED GL distribution line. Two source pairs with different
-- shapes, distinguished by work_source rather than blended:
--   gl10000 + gl10001   general journal batches
--   gl10100 + gl10101   quick journals
-- Quick journals are materially thinner — gl10101 has 13 columns against
-- gl10001's 37, no multicurrency, and a single TRXAMNT instead of separate
-- debit and credit — so the flag is load-bearing, not cosmetic.
--
-- Unposted amounts are NOT recognized revenue and must never be summed
-- together with fact_gl_posting into one measure.

CREATE TABLE IF NOT EXISTS finance.general_ledger.fact_gl_posting_work (
  gl_work_key         BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, work_source, batch_number, journal_entry_number, sequence_number).',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  legal_entity_key    BIGINT               COMMENT 'FK to finance.reference.dim_legal_entity.',
  work_source         STRING      NOT NULL COMMENT 'general_journal (gl10000 + gl10001) or quick_journal (gl10100 + gl10101). Quick-journal rows have no multicurrency columns and a single signed amount, so any consumer that ignores this flag will produce nulls it cannot explain.',
  batch_number        STRING               COMMENT 'BACHNUMB. Null for quick journals, which are keyed on BSNSFMID instead.',
  business_form_id    STRING               COMMENT 'BSNSFMID. Quick journals only.',
  journal_entry_number BIGINT     NOT NULL COMMENT 'JRNENTRY.',
  sequence_number     BIGINT      NOT NULL COMMENT 'SQNCLINE.',
  account_key         BIGINT               COMMENT 'FK to dim_gl_account.',
  account_index       INT                  COMMENT 'ACTINDX as replicated.',
  transaction_date    DATE                 COMMENT 'TRXDATE.',
  document_date       DATE                 COMMENT 'DOCDATE.',
  date_key            INT                  COMMENT 'FK to common.calendar.dim_date.',
  fiscal_year         INT                  COMMENT 'OPENYEAR.',
  fiscal_period       INT                  COMMENT 'PERIODID.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar.',
  debit_amount        DECIMAL(19,5)        COMMENT 'gl10001.DEBITAMT. Null for quick journals — see signed_amount.',
  credit_amount       DECIMAL(19,5)        COMMENT 'gl10001.CRDTAMNT. Null for quick journals.',
  signed_amount       DECIMAL(19,5)        COMMENT 'gl10101.TRXAMNT for quick journals; derived as debit minus credit for general journals. The one amount column that is populated for every row.',
  originating_debit_amount  DECIMAL(19,5)  COMMENT 'gl10001.ORDBTAMT. General journals only.',
  originating_credit_amount DECIMAL(19,5)  COMMENT 'gl10001.ORCRDAMT. General journals only.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency. Null for quick journals.',
  exchange_rate       DECIMAL(19,7)        COMMENT 'XCHGRATE. General journals only.',
  posting_status      INT                  COMMENT 'PSTGSTUS. Where the batch is in GP''s posting workflow.',
  error_state         INT                  COMMENT 'ERRSTATE. A non-zero value means GP itself considers the batch unpostable, which is usually the answer to "why has this not posted".',
  is_voided           BOOLEAN              COMMENT 'VOIDED.',
  source_document     STRING               COMMENT 'SOURCDOC.',
  reference_text      STRING               COMMENT 'REFRENCE.',
  description         STRING               COMMENT 'DSCRIPTN.',
  trx_source          STRING               COMMENT 'TRXSORCE.',
  series_id           INT                  COMMENT 'SERIES. General journals only.',
  last_modified_by_user_id STRING          COMMENT 'LASTUSER.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer tables the row was assembled from.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_gl_posting_work PRIMARY KEY (gl_work_key),
  CONSTRAINT fk_gl_work_account FOREIGN KEY (account_key) REFERENCES finance.general_ledger.dim_gl_account
)
COMMENT 'One unposted GL distribution line, from the general-journal work pair and the quick-journal work pair, distinguished by work_source. Unposted amounts are not recognized and must never be added to fact_gl_posting in a single measure. Useful for "what is sitting unposted at period end", which is a close-readiness question rather than a reporting one.'
CLUSTER BY (legal_entity_code, work_source, fiscal_year);

ALTER TABLE finance.general_ledger.fact_gl_posting_work SET TAGS ('grain' = 'unposted_gl_distribution_line', 'measure_class' = 'not_recognized');

-- ---------------------------------------------------------------------
-- mart_account_period_activity
-- ---------------------------------------------------------------------
-- NAMED FOR WHAT IT IS. The design doc lists this slot as
-- mart_trial_balance and then instructs, in the same paragraph, to name it
-- for what it is: GP's summary and beginning-balance tables are not
-- replicated, so this is NET PERIOD ACTIVITY and not a trial balance. A
-- table called mart_trial_balance would be reconciled against a real trial
-- balance and lose. The rename implements the design rather than departing
-- from it.

CREATE TABLE IF NOT EXISTS finance.general_ledger.mart_account_period_activity (
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  fiscal_year         INT         NOT NULL COMMENT 'From fact_gl_posting.',
  fiscal_period       INT         NOT NULL COMMENT 'From fact_gl_posting. Period 0 carries beginning-balance-forward.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar.',
  account_key         BIGINT      NOT NULL COMMENT 'FK to dim_gl_account.',
  account_index       INT                  COMMENT 'ACTINDX as replicated.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency. Activity is summarised per currency; summing across currencies without translation is the most likely way to misuse this table.',
  includes_bbf        BOOLEAN     NOT NULL COMMENT 'Whether beginning-balance-forward rows are included in this aggregate. Part of the grain, not a footnote: the same account and period appears once with and once without.',
  includes_pl_close   BOOLEAN     NOT NULL COMMENT 'Whether profit-and-loss close rows are included. Same rule.',
  debit_amount        DECIMAL(19,5)        COMMENT 'Sum of DEBITAMT over the grain.',
  credit_amount       DECIMAL(19,5)        COMMENT 'Sum of CRDTAMNT over the grain.',
  net_activity_amount DECIMAL(19,5)        COMMENT 'Sum of net_amount over the grain. NET PERIOD ACTIVITY — not an ending balance and not a trial balance. There is no replicated opening balance to add to it.',
  posting_line_count  BIGINT               COMMENT 'Number of distribution lines behind the aggregate. Present so a suspicious figure can be traced to a row count before anyone reruns the source query.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_mart_account_period_activity PRIMARY KEY (legal_entity_code, fiscal_year, fiscal_period, account_key, currency_key, includes_bbf, includes_pl_close),
  CONSTRAINT fk_activity_account FOREIGN KEY (account_key) REFERENCES finance.general_ledger.dim_gl_account
)
COMMENT 'Net GL activity per legal entity, fiscal year, period, account and currency. THIS IS NOT A TRIAL BALANCE. GP''s account summary and beginning-balance tables are not replicated, so no opening balance exists to roll forward and no ending balance can be derived. Named accordingly, because a table called trial balance will be reconciled against one.'
CLUSTER BY (legal_entity_code, fiscal_year, fiscal_period);

ALTER TABLE finance.general_ledger.mart_account_period_activity SET TAGS (
  'grain' = 'legal_entity_x_year_x_period_x_account_x_currency',
  'is_not_a_trial_balance' = 'true',
  'design_slot' = 'mart_trial_balance'
);

-- ---------------------------------------------------------------------
-- mart_period_summary
-- ---------------------------------------------------------------------
-- Period x legal entity x account rollup, WITH close state. The close
-- state is read as-of, from common.calendar.snap_period_close_daily, not
-- from SY40100 directly — which is the whole reason the snapshot exists.

CREATE TABLE IF NOT EXISTS finance.general_ledger.mart_period_summary (
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  fiscal_year         INT         NOT NULL COMMENT 'GP fiscal year.',
  fiscal_period       INT         NOT NULL COMMENT 'GP fiscal period.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar.',
  account_category_number INT              COMMENT 'The rollup level: GL00100.ACCATNUM. Chosen over the raw account so that this table is a summary rather than a second copy of mart_account_period_activity.',
  account_category_description STRING      COMMENT 'GL00102.ACCATDSC.',
  posting_type        INT                  COMMENT 'Balance-sheet versus profit-and-loss, from dim_gl_account.',
  as_of_date          DATE        NOT NULL COMMENT 'The vintage of this row. Part of the grain, because the same period summarised on two dates can legitimately differ — that is what a vintage measure is.',
  financial_series_is_closed BOOLEAN       COMMENT 'Close state of the Financial series (SERIES = 2) as observed on as_of_date, from common.calendar.snap_period_close_daily. Null where no snapshot exists for that date, which is honest: before the snapshot started, the answer is unknown rather than open.',
  sales_series_is_closed BOOLEAN           COMMENT 'Close state of the Sales series (SERIES = 3) as observed on as_of_date. Carried separately because a period can be closed for Financial and open for Sales — one close flag per period is silently wrong for whoever cares about the other series.',
  net_activity_amount DECIMAL(19,5)        COMMENT 'Net activity over the grain, excluding BBF and P/L close rows.',
  net_activity_amount_with_close DECIMAL(19,5) COMMENT 'Net activity including BBF and P/L close rows, for audit extracts.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_mart_period_summary PRIMARY KEY (legal_entity_code, fiscal_year, fiscal_period, account_category_number, as_of_date, currency_key)
)
COMMENT 'Period-level financial summary with as-of close state. Grain is legal entity x fiscal year x period x account category x as-of date x currency. Close state comes from the daily close snapshot rather than from SY40100, because SY40100 answers "is it closed now" and every vintage measure needs "was it closed as of the reporting date". Rows whose as_of_date predates the snapshot carry a null close state on purpose.'
CLUSTER BY (legal_entity_code, fiscal_year, as_of_date);

ALTER TABLE finance.general_ledger.mart_period_summary SET TAGS ('grain' = 'period_x_entity_x_category_x_as_of', 'depends_on_snapshot' = 'common.calendar.snap_period_close_daily');
