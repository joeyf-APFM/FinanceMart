-- =====================================================================
-- Finance Catalog — 09 — finance.plan
--
-- STATUS: NOT EXECUTED.
--
-- Named plan rather than budget on purpose. GP calls it a budget, the
-- business plans against several things that are not budgets, and the
-- schema will outlive whichever word is current — but the GP column names
-- below keep BUDGET so the lineage back to source stays obvious.
--
-- GL00200 CARRIES BUDPWRD, A BUDGET PASSWORD. It is not carried into any
-- table here, for the same reason SY01400.PASSWORD is not carried into
-- dim_gp_user: a secret that reaches a mart has effectively been published.
-- The exclusion is recorded in a table tag so it cannot be quietly undone
-- by someone adding "the rest of the header columns."
--
-- WHAT IS NOT HERE, AND IT IS THE FIRST QUESTION ANYONE WILL ASK:
-- COMMITMENTS. Plan versus actual answers "what did we plan and what did we
-- spend." It does not answer "what have we already committed but not yet
-- spent," because that lives in Purchase Order Processing and the POP
-- tables are not replicated. mart_plan_vs_actual therefore carries an
-- explicit committed_amount column that is always NULL, with the reason on
-- it. A missing column invites the assumption that spend is the whole
-- story; a null column with a reason does not.
-- =====================================================================

-- ---------------------------------------------------------------------
-- fact_plan_amount
-- ---------------------------------------------------------------------
-- GL00201 (budget detail) with the GL00200 (budget master) attributes
-- denormalized onto it. Denormalized rather than split into a dim_plan
-- because GL00200 has seven usable columns after BUDPWRD is dropped, and a
-- four-column dimension bought at the price of a join every Genie query has
-- to discover is a bad trade.

CREATE TABLE IF NOT EXISTS finance.plan.fact_plan_amount (
  plan_amount_key     BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, budget_id, fiscal_year, period_number, account_index). Test T-12 must confirm this is unique in gl00201 before any RELY.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM. In the key because BUDGETID and ACTINDX are both company-scoped.',
  legal_entity_key    BIGINT               COMMENT 'FK to finance.reference.dim_legal_entity.',
  budget_id           STRING      NOT NULL COMMENT 'GL00201.BUDGETID. GP allows many budgets per year, so this is part of the grain and not a filter to be forgotten. Two budgets summed together is a number that means nothing.',
  budget_comment      STRING               COMMENT 'GL00200.BUDCOMNT. Often the only human-readable statement of what a budget id represents; carry it so a consumer is not choosing between opaque codes.',
  budget_based_on     INT                  COMMENT 'GL00200.Based_On. What GP built the budget from — another budget, actuals, or nothing. Material to whether a variance is meaningful.',
  budget_from_date    DATE                 COMMENT 'GL00200.From_Date. GP blank-date sentinel 1900-01-01 mapped to NULL.',
  budget_to_date      DATE                 COMMENT 'GL00200.TODATE.',
  fiscal_year         INT         NOT NULL COMMENT 'GL00201.YEAR1.',
  period_number       INT         NOT NULL COMMENT 'GL00201.PERIODID. Period 0 carries beginning balances in GP and is not an error.',
  period_date         DATE                 COMMENT 'GL00201.PERIODDT.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar at period_level = period.',
  account_index       INT         NOT NULL COMMENT 'GL00201.ACTINDX. GP''s internal account key, company-scoped.',
  gl_account_key      BIGINT               COMMENT 'FK to finance.general_ledger.dim_gl_account. This is the join that makes plan and actual comparable, and it only works if both sides resolve the account the same way.',
  account_segment_1   STRING               COMMENT 'GL00201.ACTNUMBR_1. GP repeats the account segments on the budget detail row. Carried so that a plan figure can be read at segment grain without resolving the account dimension first.',
  account_segment_2   STRING               COMMENT 'GL00201.ACTNUMBR_2.',
  account_segment_3   STRING               COMMENT 'GL00201.ACTNUMBR_3.',
  account_segment_4   STRING               COMMENT 'GL00201.ACTNUMBR_4.',
  account_segment_5   STRING               COMMENT 'GL00201.ACTNUMBR_5.',
  account_category_number INT              COMMENT 'GL00201.ACCATNUM.',
  budget_amount       DECIMAL(19,5)        COMMENT 'GL00201.BUDGETAMT. The planned amount for the account and period. This is the posted, current plan — adjustments are separate, in fact_plan_adjustment, and whether a consumer wants the plan as originally set or as adjusted is a real question this split lets them answer.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table, e.g. main.prod_gp_apfm_dbo_live.gl00201.',
  _source_synced_at   TIMESTAMP            COMMENT '_fivetran_synced on the source row. NOT freshness.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_plan_amount PRIMARY KEY (plan_amount_key),
  CONSTRAINT fk_plan_amount_account FOREIGN KEY (gl_account_key)    REFERENCES finance.general_ledger.dim_gl_account,
  CONSTRAINT fk_plan_amount_period  FOREIGN KEY (fiscal_period_key) REFERENCES common.calendar.dim_fiscal_calendar,
  CONSTRAINT fk_plan_amount_entity  FOREIGN KEY (legal_entity_key)  REFERENCES finance.reference.dim_legal_entity
)
COMMENT 'One planned amount per legal entity, budget, fiscal year, period and account. Built from gl00201 with the gl00200 header attributes denormalized on. budget_id is part of the grain — GP permits many budgets per year and summing across them produces a meaningless total. GL00200.BUDPWRD is deliberately not carried.'
CLUSTER BY (legal_entity_code, fiscal_year, budget_id);

ALTER TABLE finance.plan.fact_plan_amount SET TAGS (
  'grain' = 'entity_x_budget_x_year_x_period_x_account',
  'measure_class' = 'plan',
  'excludes_source_columns' = 'BUDPWRD',
  'budget_id_is_in_grain' = 'true'
);

-- ---------------------------------------------------------------------
-- fact_plan_adjustment
-- ---------------------------------------------------------------------
-- GL32000, budget transaction history — the posted adjustment trail — with
-- the unposted adjustments from GL12000 + GL12001 in the same table,
-- separated by is_posted.
--
-- Same-table-with-a-flag rather than two tables, and the reason is the
-- opposite of the reason used for the GL: fact_gl_posting and
-- fact_gl_posting_work are separate because their measure classes differ
-- (recognised versus not recognised), and mixing them would let unposted
-- amounts into a recognised total. A plan adjustment is not a recognised
-- measure either way, so the risk does not exist and the convenience of one
-- table wins.
--
-- NOTE THE SOURCE'S OWN TYPO: the column is BudgerAdjustment in GL32000 and
-- GL12001. Not BudgetAdjustment. Reproduced verbatim in the comments below
-- because a load script written from a corrected spelling will fail, and
-- the failure will look like a missing column rather than a typo.

CREATE TABLE IF NOT EXISTS finance.plan.fact_plan_adjustment (
  plan_adjustment_key BIGINT      NOT NULL COMMENT 'Surrogate. Deterministic: xxhash64(legal_entity_code, journal_entry_number, budget_id, fiscal_year, period_number, account_index, is_posted). is_posted is in the derivation because an unposted adjustment and the posted row it becomes are two observations of the same thing and must not collide.',
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  journal_entry_number BIGINT     NOT NULL COMMENT 'GL32000.JRNENTRY, or GL12000.JRNENTRY for unposted. Company-scoped, and reused across years in GP — never treat it as globally unique.',
  batch_number        STRING               COMMENT 'GL12000.BACHNUMB / GL12001.BACHNUMB. Present for unposted rows only; GL32000 does not carry it.',
  batch_source        STRING               COMMENT 'GL12000.BCHSOURC. Unposted only.',
  budget_id           STRING      NOT NULL COMMENT 'GL32000.BUDGETID.',
  fiscal_year         INT         NOT NULL COMMENT 'GL32000.YEAR1.',
  period_number       INT         NOT NULL COMMENT 'GL32000.PERIODID.',
  period_date         DATE                 COMMENT 'GL32000.PERIODDT.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar.',
  account_index       INT         NOT NULL COMMENT 'GL32000.ACTINDX.',
  gl_account_key      BIGINT               COMMENT 'FK to finance.general_ledger.dim_gl_account.',
  transaction_date    DATE                 COMMENT 'GL32000.TRXDATE / GL12000.TRXDATE.',
  date_key            INT                  COMMENT 'FK to common.calendar.dim_date, on transaction_date.',
  budget_amount       DECIMAL(19,5)        COMMENT 'GL32000.BUDGETAMT / GL12001.BUDGETAMT. The resulting budget amount.',
  adjustment_amount   DECIMAL(19,5)        COMMENT 'GL32000.BudgerAdjustment / GL12001.BudgerAdjustment — the source column name is misspelled in GP and is reproduced here verbatim so a load script written from this comment actually resolves. This is the delta; budget_amount is the level. Summing the two together double counts.',
  reference           STRING               COMMENT 'GL32000.REFRENCE. Note GP''s own misspelling of reference.',
  source_document     STRING               COMMENT 'GL32000.SOURCDOC.',
  trx_source          STRING               COMMENT 'GL32000.TRXSORCE.',
  posted_by_user_id   STRING               COMMENT 'GL32000.USWHPSTD / GL12000.USWHPSTD. Resolve through finance.reference.dim_gp_user rather than reading sy01400.',
  last_user_id        STRING               COMMENT 'GL12000.LASTUSER. Unposted only.',
  posting_status      INT                  COMMENT 'GL12000.PSTGSTUS. Unposted only.',
  error_state         INT                  COMMENT 'GL12000.ERRSTATE, with GLHDRVAL / GLHDRMSG / GLHDRMS2 as the header validation detail and GL12001.GLLINVAL at line level. Unposted only, and usually the answer to why an adjustment has not posted.',
  header_validation_message STRING          COMMENT 'GL12000.GLHDRMSG concatenated with GLHDRMS2 where both are populated. Unposted only.',
  line_validation_code INT                 COMMENT 'GL12001.GLLINVAL. Unposted only.',
  is_posted           BOOLEAN     NOT NULL COMMENT 'True for rows from gl32000, false for rows from gl12000 + gl12001. Every consumer must filter on this deliberately: an unposted adjustment is a proposal, not a plan change.',
  source_system       STRING      NOT NULL COMMENT 'GP.',
  source_table        STRING      NOT NULL COMMENT 'Guarded-layer table the row came from.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_fact_plan_adjustment PRIMARY KEY (plan_adjustment_key),
  CONSTRAINT fk_plan_adj_account FOREIGN KEY (gl_account_key)    REFERENCES finance.general_ledger.dim_gl_account,
  CONSTRAINT fk_plan_adj_period  FOREIGN KEY (fiscal_period_key) REFERENCES common.calendar.dim_fiscal_calendar
)
COMMENT 'One budget adjustment, posted (gl32000) and unposted (gl12000 + gl12001) in one table separated by is_posted. Kept together rather than split as the GL is, because a plan adjustment is not a recognised measure in either state so there is no total for unposted rows to contaminate. adjustment_amount is a delta and budget_amount is a level — do not sum both. The GP source column is spelled BudgerAdjustment.'
CLUSTER BY (legal_entity_code, fiscal_year, budget_id);

ALTER TABLE finance.plan.fact_plan_adjustment SET TAGS (
  'grain' = 'plan_adjustment_line',
  'measure_class' = 'plan',
  'unions' = 'gl32000,gl12000+gl12001',
  'source_column_typo' = 'BudgerAdjustment'
);

-- ---------------------------------------------------------------------
-- mart_plan_vs_actual
-- ---------------------------------------------------------------------
-- The variance product. Actual comes from
-- finance.general_ledger.mart_account_period_activity, NOT from
-- fact_gl_posting directly, so that plan-versus-actual and any activity
-- report agree by construction rather than by coincidence.
--
-- Note what that inherits: mart_account_period_activity carries includes_bbf
-- and includes_pl_close in its grain. A variance computed against an actual
-- that includes beginning-balance-forward entries is wrong in a way that
-- looks plausible, so those flags are carried through here rather than
-- collapsed.

CREATE TABLE IF NOT EXISTS finance.plan.mart_plan_vs_actual (
  legal_entity_code   STRING      NOT NULL COMMENT 'APFM or CAPFM.',
  budget_id           STRING      NOT NULL COMMENT 'Which plan the actuals are being compared against. In the grain, because comparing one period''s actuals to two budgets is two answers and both are legitimate.',
  fiscal_year         INT         NOT NULL COMMENT 'Fiscal year.',
  period_number       INT         NOT NULL COMMENT 'Fiscal period.',
  fiscal_period_key   BIGINT               COMMENT 'FK to common.calendar.dim_fiscal_calendar.',
  gl_account_key      BIGINT      NOT NULL COMMENT 'FK to finance.general_ledger.dim_gl_account.',
  account_index       INT         NOT NULL COMMENT 'GP''s account index, denormalized so a consumer can trace a row back to source without a join.',
  includes_bbf        BOOLEAN     NOT NULL COMMENT 'Inherited from mart_account_period_activity: whether the actual figure includes beginning-balance-forward entries. In the grain rather than a footnote, because a variance against an actual that includes BBF is wrong in a way that looks reasonable.',
  includes_pl_close   BOOLEAN     NOT NULL COMMENT 'Inherited likewise: whether the actual includes profit-and-loss close entries.',
  plan_amount         DECIMAL(19,5)        COMMENT 'From fact_plan_amount. The plan as currently held in GP, which is the plan after posted adjustments.',
  plan_adjustment_amount DECIMAL(19,5)     COMMENT 'Sum of posted adjustments from fact_plan_adjustment for the same key. Carried separately so that "plan as originally set" and "plan as adjusted" are both answerable.',
  actual_amount       DECIMAL(19,5)        COMMENT 'From finance.general_ledger.mart_account_period_activity. Sourced from that mart rather than from fact_gl_posting so that this and any activity report agree by construction.',
  committed_amount    DECIMAL(19,5)        COMMENT 'ALWAYS NULL TODAY, and present on purpose. Commitments live in Purchase Order Processing and the POP tables are not replicated, so there is no source for open commitments. The column exists so that a reader sees the gap rather than assuming actual spend is the whole picture. Populating it requires new ingestion, not new SQL.',
  variance_amount     DECIMAL(19,5)        COMMENT 'actual_amount minus plan_amount. Sign convention documented here once: positive means actual exceeds plan, regardless of whether the account is an income or expense account. Do not flip the sign per account type in this table — do it in the presentation layer where the audience is known.',
  variance_pct        DECIMAL(9,6)         COMMENT 'variance_amount divided by plan_amount. NULL where plan_amount is zero, rather than zero or infinity. A null percentage against a zero plan is the honest answer.',
  has_plan            BOOLEAN     NOT NULL COMMENT 'False where actuals exist for an account with no planned amount. This is a FULL OUTER JOIN, not an inner one: an unplanned account with spend is exactly what a variance report exists to surface, and an inner join would hide it.',
  has_actual          BOOLEAN     NOT NULL COMMENT 'False where a plan exists with no activity. Also a legitimate finding rather than a defect.',
  _loaded_at          TIMESTAMP   NOT NULL COMMENT 'When this pipeline wrote the row.',
  CONSTRAINT pk_mart_plan_vs_actual PRIMARY KEY (legal_entity_code, budget_id, fiscal_year, period_number, gl_account_key, includes_bbf, includes_pl_close),
  CONSTRAINT fk_pva_account FOREIGN KEY (gl_account_key)    REFERENCES finance.general_ledger.dim_gl_account,
  CONSTRAINT fk_pva_period  FOREIGN KEY (fiscal_period_key) REFERENCES common.calendar.dim_fiscal_calendar
)
COMMENT 'Plan versus actual by legal entity, budget, period and account. A FULL OUTER JOIN of plan and actual — accounts with spend and no plan, and plans with no spend, both appear, because both are the point. Actual is taken from mart_account_period_activity so the two products cannot disagree. committed_amount is always null: commitments require POP tables that are not replicated, and the column exists to make that visible.'
CLUSTER BY (legal_entity_code, fiscal_year, budget_id);

ALTER TABLE finance.plan.mart_plan_vs_actual SET TAGS (
  'grain' = 'entity_x_budget_x_period_x_account',
  'join_type' = 'full_outer',
  'known_gap' = 'committed_amount_requires_pop_ingestion',
  'actual_sourced_from' = 'finance.general_ledger.mart_account_period_activity'
);
