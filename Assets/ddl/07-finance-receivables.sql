-- =====================================================================
-- Finance Catalog — 07 — finance.receivables
--
-- STATUS: NOT EXECUTED.
--
-- AR documents, the apply trail, aging, write-offs, and collections
-- attributes.
--
-- AGING HISTORY IS RECONSTRUCTABLE, and this corrects the initial plan. GP
-- moves a document out of RM20101 once it is fully applied, so today's open
-- file cannot answer "what was aged 60+ last March." That looks like
-- unrecoverable history and it is not: RM20201 and RM30201 carry DATE1,
-- GLPOSTDT, APTODCDT, ApplyToGLPostDate and APPTOAMT, so outstanding as of
-- date D is the document amount less applies dated on or before D. The
-- apply trail IS the history.
--
-- snap_ar_aging_daily is still worth building — for COST, not
-- recoverability. The reconstruction is an expensive window over two
-- unioned tables and it depends on the apply trail being complete across
-- the open/history boundary. Snapshot for routine reporting; reconstruct to
-- validate the snapshot and to answer questions predating it.
-- =====================================================================

-- ---------------------------------------------------------------------
-- fact_ar_transaction
-- ---------------------------------------------------------------------
-- One RM document, rm20101 (open) unioned with rm30101 (fully applied /
-- closed) across both companies.
--
-- The two are close but NOT identical, and one difference matters:
-- RM20101 carries AGNGBUKT — GP's own aging bucket — and RM30101 does not.
-- GP's bucket assignment therefore exists only for open documents, which
-- means the bucket reconciliation that mart_ar_aging depends on can only be
-- validated against open documents. Reconstructed historical aging has no
-- GP bucket to check itself against.
--
-- RM20101 also carries the checkbook columns (CBKIDCRD/CBKIDCSH/CBKIDCHK)
-- and DISAVTKN, which RM30101 drops; RM30101 carries BALFWDNM, which
-- RM20101 does not.

CREATE TABLE IF NOT EXISTS finance.receivables.fact_ar_transaction (
  ar_transaction_key  BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, gp_customer_number, document_type_code, document_number). Test T-07 must confirm this combination is unique across the union before any RELY is added.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  legal_entity_key    BIGINT               COMMENT 'FK to finance.reference.dim_legal_entity.',
  customer_key        BIGINT               COMMENT 'FK to finance.identity.dim_customer.',
  gp_customer_number  STRING      NOT NULL COMMENT 'CUSTNMBR, trimmed. GP char columns are space-padded and an untrimmed join returns nothing.',
  parent_customer_number STRING            COMMENT 'CPRCSTNM.',
  document_number     STRING      NOT NULL COMMENT 'DOCNUMBR.',
  document_type_code  INT         NOT NULL COMMENT 'RMDTYPAL. GP''s receivables document type — sale, scheduled payment, debit memo, finance charge, service repair, warranty, credit memo, return, payment. Decode from the value lists in the GP reference; the sign convention of every amount below depends on it.',
  document_type_name  STRING               COMMENT 'Decoded document_type_code. Decoded here so that no consumer has to hold the code table.',
  document_date       DATE                 COMMENT 'DOCDATE. GP blank-date sentinel 1900-01-01 mapped to NULL.',
  due_date            DATE                 COMMENT 'DUEDATE. The basis for every aging calculation, so a null here puts a document in no bucket and must be surfaced rather than defaulted.',
  post_date           DATE                 COMMENT 'POSTDATE.',
  gl_post_date        DATE                 COMMENT 'GLPOSTDT. The date the document hit the GL, which is what reconciles this fact to fact_gl_posting.',
  sale_date           DATE                 COMMENT 'SALEDATE.',
  discount_date       DATE                 COMMENT 'DISCDATE.',
  date_paid_off       DATE                 COMMENT 'DINVPDOF. Populated when the document is fully applied; the boundary between the open and history tables.',
  date_key            INT                  COMMENT 'FK to common.calendar.dim_date, on document_date.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar, on gl_post_date.',
  original_amount     DECIMAL(19,5)        COMMENT 'ORTRXAMT. The document as issued. This is the numerator for the as-of aging reconstruction.',
  current_amount      DECIMAL(19,5)        COMMENT 'CURTRXAM. The amount still outstanding AS OF THE LAST SYNC — current state only. For any historical as-of question use original_amount less applies dated on or before the date, from fact_ar_apply.',
  sales_amount        DECIMAL(19,5)        COMMENT 'SLSAMNT.',
  cost_amount          DECIMAL(19,5)       COMMENT 'COSTAMNT.',
  freight_amount      DECIMAL(19,5)        COMMENT 'FRTAMNT.',
  miscellaneous_amount DECIMAL(19,5)       COMMENT 'MISCAMNT.',
  tax_amount          DECIMAL(19,5)        COMMENT 'TAXAMNT.',
  trade_discount_amount DECIMAL(19,5)      COMMENT 'TRDISAMT.',
  cash_amount         DECIMAL(19,5)        COMMENT 'CASHAMNT.',
  discount_taken_amount DECIMAL(19,5)      COMMENT 'DISTKNAM.',
  discount_available_amount DECIMAL(19,5)  COMMENT 'DISAVAMT.',
  writeoff_amount     DECIMAL(19,5)        COMMENT 'WROFAMNT on the document. The per-apply write-off in fact_ar_apply is the event-level version; use that for "when was it written off" and this for "how much of this document was".',
  commission_amount   DECIMAL(19,5)        COMMENT 'COMDLRAM.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency.',
  gp_currency_id      STRING               COMMENT 'CURNCYID as replicated.',
  gp_aging_bucket     STRING               COMMENT 'RM20101.AGNGBUKT. GP''s own bucket assignment. NULL for every row sourced from rm30101, because the history table does not carry it. This is the only independent check on the bucket cutoffs used in mart_ar_aging, and it is available for open documents only.',
  payment_terms_id    STRING               COMMENT 'PYMTRMID.',
  salesperson_id      STRING               COMMENT 'SLPRSNID.',
  sales_territory     STRING               COMMENT 'SLSTERCD.',
  check_number        STRING               COMMENT 'CHEKNMBR.',
  batch_number        STRING               COMMENT 'BACHNUMB.',
  batch_source        STRING               COMMENT 'BCHSOURC.',
  trx_source          STRING               COMMENT 'TRXSORCE. Ties the document to the GL batch that posted it.',
  description         STRING               COMMENT 'TRXDSCRN.',
  customer_po_number  STRING               COMMENT 'CSPORNBR.',
  apply_with_code     INT                  COMMENT 'APLYWITH.',
  void_status         INT                  COMMENT 'VOIDSTTS. A voided document still has rows; excluding voids is a decision the consumer must make explicitly.',
  void_date           DATE                 COMMENT 'VOIDDATE.',
  gp_delete_flag      BOOLEAN              COMMENT 'DELETE1. GP''s own delete marker, which is a DIFFERENT concept from Fivetran''s _fivetran_deleted tombstone — the guarded layer removes the latter and leaves this one, so both must be considered.',
  is_direct_debit     BOOLEAN              COMMENT 'DIRECTDEBIT.',
  is_electronic       BOOLEAN              COMMENT 'Electronic.',
  is_factored         BOOLEAN              COMMENT 'Factoring.',
  posted_by_user_id   STRING               COMMENT 'PSTUSRID.',
  last_edited_by_user_id STRING            COMMENT 'LSTUSRED.',
  is_history          BOOLEAN     NOT NULL COMMENT 'True where the row came from rm30101 (fully applied), false where it came from rm20101 (still outstanding). A document''s presence in history is itself the fact that it was settled.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table the row came from.',
  _source_synced_at   TIMESTAMP            COMMENT '_fivetran_synced on the source row. NOT freshness.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_ar_transaction PRIMARY KEY (ar_transaction_key),
  CONSTRAINT fk_ar_txn_customer     FOREIGN KEY (customer_key)      REFERENCES finance.identity.dim_customer,
  CONSTRAINT fk_ar_txn_legal_entity FOREIGN KEY (legal_entity_key)  REFERENCES finance.reference.dim_legal_entity,
  CONSTRAINT fk_ar_txn_currency     FOREIGN KEY (currency_key)      REFERENCES finance.reference.dim_currency,
  CONSTRAINT fk_ar_txn_period       FOREIGN KEY (fiscal_period_key) REFERENCES common.calendar.dim_fiscal_calendar
)
COMMENT 'One receivables document, rm20101 (outstanding) unioned with rm30101 (fully applied) across both companies. current_amount is current state only; any as-of-date balance must be computed from original_amount less applies from fact_ar_apply. GP''s own aging bucket is present for open documents only.'
CLUSTER BY (legal_entity_code, gp_customer_number, document_date);

ALTER TABLE finance.receivables.fact_ar_transaction SET TAGS ('grain' = 'ar_document', 'unions' = 'rm20101,rm30101', 'current_state_column' = 'current_amount');

-- ---------------------------------------------------------------------
-- fact_ar_apply
-- ---------------------------------------------------------------------
-- One apply relationship, rm20201 unioned with rm30201. THIS TABLE IS THE
-- AGING HISTORY. It is also what makes write-offs servable today: WROFAMNT
-- is the write-off amount and ORWROFAM its originating-currency
-- counterpart, so the stated pain point — write-offs and bad-debt recovery
-- invisible to CAMs and Community Ops — needs no new ingestion. It needs
-- this fact and a grant.
--
-- Both source tables carry 59 identical columns, so the union is clean.

CREATE TABLE IF NOT EXISTS finance.receivables.fact_ar_apply (
  ar_apply_key        BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, gp_customer_number, apply_from_document_number, apply_from_document_type, apply_to_document_number, apply_to_document_type, apply_date, apply_time). Test T-08 must confirm uniqueness; GP permits multiple partial applies between the same two documents, which is why date and time are in the key.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  customer_key        BIGINT               COMMENT 'FK to finance.identity.dim_customer.',
  gp_customer_number  STRING      NOT NULL COMMENT 'CUSTNMBR, trimmed.',
  apply_from_document_number STRING        COMMENT 'APFRDCNM. The document doing the applying — typically a payment or credit memo.',
  apply_from_document_type   INT           COMMENT 'APFRDCTY.',
  apply_from_document_date   DATE          COMMENT 'APFRDCDT.',
  apply_from_gl_post_date    DATE          COMMENT 'ApplyFromGLPostDate.',
  apply_to_document_number   STRING        COMMENT 'APTODCNM. The document being applied to — typically an invoice.',
  apply_to_document_type     INT           COMMENT 'APTODCTY.',
  apply_to_document_date     DATE          COMMENT 'APTODCDT.',
  apply_to_gl_post_date      DATE          COMMENT 'ApplyToGLPostDate. Together with apply_date this is what makes as-of aging reconstructable: an apply counts against a document only from the date it happened.',
  apply_to_transaction_key   BIGINT        COMMENT 'FK to fact_ar_transaction, resolved on the apply-to document. This is the join that turns the apply trail into an aging history.',
  apply_date          DATE                 COMMENT 'DATE1. The date the apply was recorded.',
  apply_time          TIMESTAMP            COMMENT 'TIME1. GP stores date and time separately, and both are needed because several applies can share a date.',
  gl_post_date        DATE                 COMMENT 'GLPOSTDT.',
  date_key            INT                  COMMENT 'FK to common.calendar.dim_date, on apply_date.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar, on gl_post_date.',
  applied_amount      DECIMAL(19,5)        COMMENT 'APPTOAMT. The amount applied. Subtracting the applies dated on or before D from the document''s original amount is the as-of outstanding balance.',
  discount_taken_amount DECIMAL(19,5)      COMMENT 'DISTKNAM.',
  discount_available_taken DECIMAL(19,5)   COMMENT 'DISAVTKN.',
  writeoff_amount     DECIMAL(19,5)        COMMENT 'WROFAMNT. The write-off recorded on this apply. A non-zero value here IS the write-off event, and its date is known — which is what makes write-off reporting available without new ingestion.',
  originating_applied_amount DECIMAL(19,5) COMMENT 'ORAPTOAM, originating currency.',
  originating_discount_taken DECIMAL(19,5) COMMENT 'ORDISTKN.',
  originating_writeoff_amount DECIMAL(19,5) COMMENT 'ORWROFAM.',
  actual_applied_amount DECIMAL(19,5)      COMMENT 'ActualApplyToAmount. GP records both the nominal and the actual applied amount; they differ when a rate changes between the two documents. Do not assume they are the same column under two names.',
  actual_writeoff_amount DECIMAL(19,5)     COMMENT 'ActualWriteOffAmount.',
  realized_gain_loss  DECIMAL(19,5)        COMMENT 'RLGANLOS. The realised exchange gain or loss on the apply. Non-zero only in a multicurrency context, which for APFM means CAPFM.',
  apply_to_exchange_rate DECIMAL(19,7)     COMMENT 'APTOEXRATE.',
  apply_from_exchange_rate DECIMAL(19,7)   COMMENT 'APFRMEXRATE.',
  apply_to_rate_calc_method INT            COMMENT 'APTORTCLCMETH. Multiply or divide; getting it backwards inverts the translated amount.',
  from_currency_id    STRING               COMMENT 'FROMCURR.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency, on the apply-to currency.',
  gp_currency_id      STRING               COMMENT 'CURNCYID as replicated.',
  is_posted           BOOLEAN              COMMENT 'POSTED.',
  revaluation_status  INT                  COMMENT 'Revaluation_Status.',
  is_history          BOOLEAN     NOT NULL COMMENT 'True where the row came from rm30201, false from rm20201. The apply trail must be read across BOTH: an apply can be in history while the document it applies to is still open, and vice versa.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table the row came from.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_ar_apply PRIMARY KEY (ar_apply_key),
  CONSTRAINT fk_ar_apply_customer FOREIGN KEY (customer_key)            REFERENCES finance.identity.dim_customer,
  CONSTRAINT fk_ar_apply_document FOREIGN KEY (apply_to_transaction_key) REFERENCES finance.receivables.fact_ar_transaction
)
COMMENT 'One apply relationship between receivables documents, rm20201 unioned with rm30201. This is the AR history: outstanding as of date D equals the document original amount less the applies dated on or before D. It is also the write-off event log — WROFAMNT with a date, which is what the CAM and Community Ops visibility gap actually needs.'
CLUSTER BY (legal_entity_code, gp_customer_number, apply_date);

ALTER TABLE finance.receivables.fact_ar_apply SET TAGS ('grain' = 'apply_relationship', 'unions' = 'rm20201,rm30201', 'is_aging_history_source' = 'true');

-- ---------------------------------------------------------------------
-- snap_ar_aging_daily — START THIS EARLY
-- ---------------------------------------------------------------------
-- One row per customer x document x snapshot date. Built for cost, not
-- recoverability: the reconstruction from the apply trail is an expensive
-- window over two unioned tables and depends on that trail being complete
-- across the open/history boundary. Snapshot for routine reporting;
-- reconstruct to validate the snapshot and to answer questions predating it.

CREATE TABLE IF NOT EXISTS finance.receivables.snap_ar_aging_daily (
  snapshot_date       DATE        NOT NULL COMMENT 'The date this observation was taken.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  gp_customer_number  STRING      NOT NULL COMMENT 'CUSTNMBR, trimmed.',
  customer_key        BIGINT               COMMENT 'FK to finance.identity.dim_customer.',
  document_number     STRING      NOT NULL COMMENT 'DOCNUMBR.',
  document_type_code  INT         NOT NULL COMMENT 'RMDTYPAL.',
  ar_transaction_key  BIGINT               COMMENT 'FK to fact_ar_transaction.',
  document_date       DATE                 COMMENT 'DOCDATE as observed.',
  due_date            DATE                 COMMENT 'DUEDATE as observed.',
  original_amount     DECIMAL(19,5)        COMMENT 'ORTRXAMT as observed.',
  outstanding_amount  DECIMAL(19,5)        COMMENT 'CURTRXAM as observed on snapshot_date. This is the value that GP overwrites and the reason this table exists.',
  gp_aging_bucket     STRING               COMMENT 'AGNGBUKT as observed. GP''s own assignment, captured so that a later change to the bucket setup does not silently rewrite history.',
  days_past_due       INT                  COMMENT 'Derived: snapshot_date minus due_date. Recorded rather than computed on read, so that the figure does not shift if the bucket definitions change.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table observed, e.g. main.prod_gp_apfm_dbo_live.rm20101.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When the snapshot job wrote the row.',
  CONSTRAINT pk_snap_ar_aging_daily PRIMARY KEY (snapshot_date, legal_entity_code, gp_customer_number, document_number, document_type_code)
)
COMMENT 'Daily snapshot of the open AR file, one row per snapshot date x customer x document. Append-only. A document disappears from later snapshots when GP moves it to history, and that disappearance is meaningful — it is the settlement date. Unlike snap_period_close_daily, the history here has a fallback in fact_ar_apply, so a missed day is recoverable at cost rather than lost.'
CLUSTER BY (snapshot_date, legal_entity_code);

ALTER TABLE finance.receivables.snap_ar_aging_daily SET TAGS ('append_only' = 'true', 'has_reconstruction_fallback' = 'fact_ar_apply');

-- ---------------------------------------------------------------------
-- mart_ar_aging
-- ---------------------------------------------------------------------
-- BUCKET CUTOFFS MUST BE RECONCILED TO GP'S OWN AGING SETUP BEFORE THIS IS
-- PUBLISHED. The query research catalog flags it twice. Cutoffs that
-- disagree with GP produce a report that is defensibly wrong, which is
-- worse than one that is obviously wrong. gp_aging_bucket on
-- fact_ar_transaction is the check, and it exists for open documents only.

CREATE TABLE IF NOT EXISTS finance.receivables.mart_ar_aging (
  as_of_date          DATE        NOT NULL COMMENT 'The date the aging is computed as of. Part of the grain: aging is a vintage measure and the same customer aged on two dates is two legitimate answers.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  customer_key        BIGINT               COMMENT 'FK to finance.identity.dim_customer.',
  gp_customer_number  STRING      NOT NULL COMMENT 'CUSTNMBR, trimmed.',
  aging_bucket        STRING      NOT NULL COMMENT 'The bucket label. Cutoffs must match GP''s aging setup; publication is blocked on test T-09 reconciling this against fact_ar_transaction.gp_aging_bucket for open documents.',
  aging_bucket_order  INT         NOT NULL COMMENT 'Sort position, so that a consumer never has to sort bucket labels alphabetically and get 30-60 before current.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency. Aging is computed per currency; a total across currencies without translation is meaningless.',
  outstanding_amount  DECIMAL(19,5)        COMMENT 'Sum of the as-of outstanding balance over the grain.',
  document_count      BIGINT               COMMENT 'Number of documents in the bucket.',
  computation_basis   STRING      NOT NULL COMMENT 'One of snapshot (read from snap_ar_aging_daily) or reconstructed (original amount less applies dated on or before as_of_date). Carried because the two can legitimately differ, and knowing which produced a figure is the first question anyone will ask about a discrepancy.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_mart_ar_aging PRIMARY KEY (as_of_date, legal_entity_code, gp_customer_number, aging_bucket, currency_key, computation_basis),
  CONSTRAINT fk_ar_aging_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer
)
COMMENT 'AR aging by customer and bucket as of a date. Grain is as-of date x legal entity x customer x bucket x currency x computation basis. Both a snapshot-derived and a reconstructed figure can coexist for the same key, on purpose: the reconstruction validates the snapshot, and hiding a disagreement between them would defeat that.'
CLUSTER BY (as_of_date, legal_entity_code);

ALTER TABLE finance.receivables.mart_ar_aging SET TAGS ('grain' = 'as_of_x_entity_x_customer_x_bucket_x_currency', 'publication_blocked_on' = 'gp_aging_setup_reconciliation');

-- ---------------------------------------------------------------------
-- mart_writeoff
-- ---------------------------------------------------------------------
-- Servable today, from fact_ar_apply. No new ingestion required.

CREATE TABLE IF NOT EXISTS finance.receivables.mart_writeoff (
  writeoff_key        BIGINT      NOT NULL COMMENT 'Surrogate, inherited from the fact_ar_apply row that carries the write-off.',
  ar_apply_key        BIGINT      NOT NULL COMMENT 'FK to fact_ar_apply. One write-off event is one apply row with a non-zero WROFAMNT.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  customer_key        BIGINT               COMMENT 'FK to finance.identity.dim_customer.',
  gp_customer_number  STRING      NOT NULL COMMENT 'CUSTNMBR, trimmed.',
  document_number     STRING               COMMENT 'The apply-to document that was written off.',
  document_type_code  INT                  COMMENT 'RMDTYPAL of the apply-to document.',
  writeoff_date       DATE                 COMMENT 'The apply date. This is the answer to "when was it written off", which GP does record and which nothing currently surfaces.',
  gl_post_date        DATE                 COMMENT 'GLPOSTDT of the apply, for reconciliation to fact_gl_posting.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar.',
  writeoff_amount     DECIMAL(19,5)        COMMENT 'WROFAMNT.',
  originating_writeoff_amount DECIMAL(19,5) COMMENT 'ORWROFAM, originating currency.',
  actual_writeoff_amount DECIMAL(19,5)     COMMENT 'ActualWriteOffAmount, which can differ from WROFAMNT when a rate moves between the two documents.',
  currency_key        BIGINT               COMMENT 'FK to finance.reference.dim_currency.',
  business_unit_id    STRING               COMMENT 'Resolved through finance.identity.bridge_customer_to_business_unit as of writeoff_date. Present because the stated pain point is write-offs being invisible to CAMs and Community Ops, and both work at community grain rather than billing-account grain.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_mart_writeoff PRIMARY KEY (writeoff_key),
  CONSTRAINT fk_writeoff_apply    FOREIGN KEY (ar_apply_key) REFERENCES finance.receivables.fact_ar_apply,
  CONSTRAINT fk_writeoff_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer
)
COMMENT 'One write-off event, derived from the non-zero WROFAMNT rows in fact_ar_apply. Directly serves the pain point that write-offs and bad-debt recovery are invisible to CAMs and Community Ops. Needs no ingestion that does not already exist — it needs this table and a grant. business_unit_id is resolved as of the write-off date, not from the current mapping.'
CLUSTER BY (legal_entity_code, writeoff_date);

ALTER TABLE finance.receivables.mart_writeoff SET TAGS ('grain' = 'writeoff_event', 'serves_stated_pain_point' = 'writeoff_visibility', 'requires_no_new_ingestion' = 'true');

-- ---------------------------------------------------------------------
-- dim_collections_attributes
-- ---------------------------------------------------------------------
-- A satellite on dim_customer rather than columns added to it, because
-- CN00500 is a Collections Management add-on table that may be sparsely
-- populated. Merging sparse add-on columns into the customer dimension
-- makes it impossible to tell "not set" from "module not used".

CREATE TABLE IF NOT EXISTS finance.receivables.dim_collections_attributes (
  customer_key        BIGINT      NOT NULL COMMENT 'FK to finance.identity.dim_customer. One row per customer that has a CN00500 record — not one per customer.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  gp_customer_number  STRING      NOT NULL COMMENT 'CN00500.CUSTNMBR, trimmed.',
  credit_manager_id   STRING               COMMENT 'CN00500.CRDTMGR. Who owns the collections relationship.',
  preferred_contact_method STRING          COMMENT 'CN00500.PreferredContactMethod.',
  no_mail_flag        BOOLEAN              COMMENT 'CN00500.NOMAIL. A contact-preference suppression flag; respect it in any outbound collections process.',
  address_code        STRING               COMMENT 'CN00500.ADRSCODE.',
  time_zone           STRING               COMMENT 'CN00500.Time_Zone.',
  credit_control_cycle STRING              COMMENT 'CN00500.CN_Credit_Control_Cycle.',
  user_table_01       STRING               COMMENT 'CN00500.USRTAB01. Undocumented user field; profile before use.',
  user_table_09       STRING               COMMENT 'CN00500.USRTAB09. Undocumented user field; profile before use.',
  user_defined_1      STRING               COMMENT 'CN00500.USERDEF1. Distinct from RM00101.USERDEF1 — do not conflate them.',
  user_defined_2      STRING               COMMENT 'CN00500.USERDEF2.',
  user_defined_date_1 DATE                 COMMENT 'CN00500.USRDAT01.',
  history_type        STRING      NOT NULL COMMENT 'Always type_1 — current state only from the replica.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table, e.g. main.prod_gp_apfm_dbo_live.cn00500.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_dim_collections_attributes PRIMARY KEY (customer_key),
  CONSTRAINT fk_collections_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer
)
COMMENT 'Collections Management attributes from CN00500, as a satellite on dim_customer rather than columns merged into it. Absence of a row means no CN00500 record exists, which is different from an attribute being blank — a distinction that merging would destroy. Profile the population rate before building anything on top of it.';
