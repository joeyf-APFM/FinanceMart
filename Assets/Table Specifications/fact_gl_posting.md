---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.general_ledger.fact_gl_posting

> [!WARNING]
> **Not built**
>
> DDL: [06-finance-general-ledger.sql](../ddl/06-finance-general-ledger.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Fact |
| **Grain** | One **posted GL distribution line** |
| **Sources** | `gl20000` (open year) **∪** `gl30000` (closed years), both companies |
| **Measure class** | `recognized` — **this is where recognized revenue lives** |
| **Clustering** | `CLUSTER BY (legal_entity_code, fiscal_year, fiscal_period, account_index)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-05** (key uniqueness), **T-06** (BBF/P&L derivation), **T-01** (`date_key`) |

## The union is not optional

`gl20000` is the **open** year, `gl30000` is **closed** years. **Do not query `gl20000` alone: it covers one fiscal year and looks complete.** A report built on it silently covers twelve months and reconciles internally.

The two tables are structurally identical apart from the year column — `gl20000.OPENYEAR` versus `gl30000.HSTYEAR`, both 64 columns. Only columns with a stated finance use are lifted here; the rest stay available in the guarded layer rather than being copied for completeness. `is_history` lets a consumer reproduce a single-table query **without losing the union**.

## BBF and P&L close are flags, not filters

Query 03 in the query research catalog excludes beginning-balance-forward and profit-and-loss close entries by default. **That is right for activity reporting and wrong for an audit extract**, so it is a flag on the fact rather than a filter in a view.

The flags derive from `SOURCDOC`. The GP convention is `'BBF'` and `'P/L'`, **but the actual distinct values in the replica must be profiled before the derivation ships (T-06).**

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `gl_posting_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, fiscal_year, journal_entry_number, receipt_trx_sequence, sequence_number)`. Deterministic rather than identity: a full reload must not renumber and orphan downstream references, and Delta identity columns cannot be populated by CTAS |
| `legal_entity_code` | STRING | No | Derived | Both companies are unioned in. GP identifiers are company-scoped, so this belongs in every natural key |
| `legal_entity_key` | BIGINT | Yes | Derived | FK to [dim_legal_entity](dim_legal_entity.md) |
| `fiscal_year` | INT | No | `OPENYEAR` / `HSTYEAR` | **The single column that reconciles the two source tables** |
| `fiscal_period` | INT | Yes | `PERIODID` | **Period 0 carries beginning-balance-forward and is not a data error** |
| `fiscal_period_key` | BIGINT | Yes | Derived | FK to [dim_fiscal_calendar](dim_fiscal_calendar.md) at `period_level = 'period'`. **Deliberately separate from `date_key`** — the period an amount is recognized in is not always the period its transaction date falls in, and collapsing the two makes a restated amount impossible to explain |
| `journal_entry_number` | BIGINT | No | `JRNENTRY` | **Unique within a company and year, not across them** |
| `receipt_trx_sequence` | BIGINT | Yes | `RCTRXSEQ` | |
| `sequence_number` | BIGINT | No | `SEQNUMBR` | The distribution line within the entry. **This is what makes the grain a line rather than an entry** |
| `account_key` | BIGINT | Yes | Derived | FK to [dim_gl_account](dim_gl_account.md) |
| `account_index` | INT | Yes | `ACTINDX` | As replicated |
| `transaction_date` | DATE | Yes | `TRXDATE` | Blank-date sentinel → NULL |
| `document_date` | DATE | Yes | `DOCDATE` | |
| `originating_post_date` | DATE | Yes | `ORPSTDDT` | |
| `date_key` | INT | Yes | Derived on `transaction_date` | FK to [dim_date](dim_date.md). Declared INT on a `yyyymmdd` assumption — **T-01** |
| `debit_amount` | DECIMAL(19,5) | Yes | `DEBITAMT` | Functional currency |
| `credit_amount` | DECIMAL(19,5) | Yes | `CRDTAMNT` | Functional currency |
| `net_amount` | DECIMAL(19,5) | Yes | Derived | `debit_amount − credit_amount`. Present so **no consumer has to choose a sign convention, and every consumer chooses the same one** |
| `originating_debit_amount` | DECIMAL(19,5) | Yes | `ORDBTAMT` | Originating (transaction) currency |
| `originating_credit_amount` | DECIMAL(19,5) | Yes | `ORCRDAMT` | Originating currency |
| `currency_key` | BIGINT | Yes | Derived | FK to [dim_currency](dim_currency.md) |
| `gp_currency_id` | STRING | Yes | `CURNCYID` | |
| `gp_currency_index` | INT | Yes | `CURRNIDX` | |
| `exchange_rate` | DECIMAL(19,7) | Yes | `XCHGRATE` | |
| `denomination_exchange_rate` | DECIMAL(19,7) | Yes | `DENXRATE` | |
| `exchange_rate_date` | DATE | Yes | `EXCHDATE` | |
| `rate_calculation_method` | INT | Yes | `RTCLCMTD` | Multiply or divide. **Applying the wrong direction inverts every translated amount**, so it must be read rather than assumed |
| `rate_type_id` | STRING | Yes | `RATETPID` | |
| `exchange_table_id` | STRING | Yes | `EXGTBLID` | Joins to [fact_exchange_rate](fact_exchange_rate.md) for rate provenance |
| `multicurrency_state` | INT | Yes | `MCTRXSTT` | |
| `source_document` | STRING | Yes | `SOURCDOC` | **The column the BBF and P/L flags are derived from** |
| `reference_text` | STRING | Yes | `REFRENCE` | |
| `description` | STRING | Yes | `DSCRIPTN` | |
| `trx_source` | STRING | Yes | `TRXSORCE` | The audit-trail code — **how a posting is traced back to the subledger batch that created it** |
| `series_id` | INT | Yes | `SERIES` | `1` All, `2` Financial, `3` Sales, `4` Purchasing, `5` Inventory, `6` Payroll - USA, `7` Project. **Ties a posting to the period-close series that governs it** |
| `originating_trx_type` | INT | Yes | `ORTRXTYP` | |
| `originating_document_number` | STRING | Yes | `ORDOCNUM` | |
| `originating_control_number` | STRING | Yes | `ORCTRNUM` | |
| `originating_master_id` | STRING | Yes | `ORMSTRID` | **For receivables postings this is the GP customer number** — how a GL row is attributed to a customer without a subledger join |
| `originating_master_name` | STRING | Yes | `ORMSTRNM` | **PII-adjacent**: for receivables postings this is a customer name |
| `originating_source` | STRING | Yes | `ORGNTSRC` | |
| `ledger_id` | INT | Yes | `Ledger_ID` | |
| `posting_number` | INT | Yes | `PSTGNMBR` | |
| `posted_by_user_id` | STRING | Yes | `USWHPSTD` | Joins to [dim_gp_user](dim_gp_user.md) |
| `last_modified_by_user_id` | STRING | Yes | `LASTUSER` | |
| `approval_user_id` | STRING | Yes | `APRVLUSERID` | |
| `approval_date` | DATE | Yes | `APPRVLDT` | |
| `is_voided` | BOOLEAN | Yes | `VOIDED` | |
| `is_adjustment` | BOOLEAN | Yes | `Adjustment_Transaction` | |
| `is_intercompany` | BOOLEAN | Yes | `ICTRX` | |
| `originating_company_id` | STRING | Yes | `ORCOMID` | |
| `is_beginning_balance_forward` | BOOLEAN | No | Derived from `SOURCDOC` | **A flag, not a filter.** T-06 |
| `is_profit_loss_close` | BOOLEAN | No | Derived from `SOURCDOC` | Same rule |
| `is_history` | BOOLEAN | No | Derived | True from `gl30000`, false from `gl20000` |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | e.g. `main.prod_gp_apfm_dbo_live.gl20000` |
| `_source_synced_at` | TIMESTAMP | Yes | `_fivetran_synced` | **NOT freshness. A stale value on `gl30000` rows is the fiscal-year close, not a broken connector** |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_gl_posting PRIMARY KEY (gl_posting_key)`; FKs to `dim_gl_account`, `dim_legal_entity`, `dim_currency`, `common.calendar.dim_fiscal_calendar`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `posted_gl_distribution_line` | |
| `measure_class` | `recognized` | The only schema where an amount may be called recognized revenue |
| `unions` | `gl20000,gl30000` | |
| `both_legal_entities` | `true` | |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_gl_account](dim_gl_account.md) | `f.account_key = a.account_key` | N:1 | Declared FK |
| [dim_legal_entity](dim_legal_entity.md) | `f.legal_entity_key = le.legal_entity_key` | N:1 | Declared FK |
| [dim_currency](dim_currency.md) | `f.currency_key = c.currency_key` | N:1 | Declared FK |
| [dim_fiscal_calendar](dim_fiscal_calendar.md) | `f.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Declared FK. **Filter `period_level = 'period'`** |
| [dim_date](dim_date.md) | `f.date_key = d.date_key` | N:1 | On `transaction_date` |
| [dim_gp_user](dim_gp_user.md) | `trim(u.gp_user_id) = trim(f.posted_by_user_id)` | N:1 | **`LEFT JOIN`, aliased per role.** Three user columns |
| [fact_exchange_rate](fact_exchange_rate.md) | as-of, on `(legal_entity_code, exchange_table_id, gp_currency_id)` + `rate_date <= transaction_date` | N:1 | **Not an equijoin** — see [fact_exchange_rate](fact_exchange_rate.md) |
| [snap_period_close_daily](snap_period_close_daily.md) | `(legal_entity_code, fiscal_year, fiscal_period)` **+ `series_id`** | N:1 | **Omitting `series_id` fans out sevenfold** |
| [fact_ar_transaction](fact_ar_transaction.md) | `trim(f.trx_source) = trim(ar.trx_source)` | N:M | The subledger tie. See below |
| [dim_customer](dim_customer.md) | via `originating_master_id` | N:1 | Only for receivables postings. See below |
| [mart_account_period_activity](mart_account_period_activity.md) | This fact is its source | — | Aggregate, not join |

### The subledger tie: `trx_source`

`TRXSORCE` is the audit-trail code, and it is the **only** link from a GL posting back to the receivables batch that created it. It is not a foreign key and no constraint declares it:

```sql
-- Which AR documents produced this GL batch
SELECT g.journal_entry_number, g.net_amount, ar.document_number, ar.document_amount
FROM   finance.general_ledger.fact_gl_posting  g
JOIN   finance.receivables.fact_ar_transaction ar
       ON  ar.legal_entity_code = g.legal_entity_code
       AND trim(ar.trx_source)  = trim(g.trx_source)
WHERE  g.trx_source IS NOT NULL
```

**This is many-to-many.** One batch produces many GL lines and covers many AR documents. It answers *"what is behind this batch"*, not *"what is the GL amount for this invoice"* — that second question needs an allocation and this column does not supply one.

### Attributing a GL row to a customer without a subledger join

`ORMSTRID` carries the GP customer number on receivables postings:

```sql
LEFT JOIN finance.identity.dim_customer dc
       ON  dc.legal_entity_code       =  g.legal_entity_code
       AND trim(dc.gp_customer_number) = trim(g.originating_master_id)
WHERE g.series_id = 3        -- Sales; ORMSTRID means something else on other series
```

Pin the series. `ORMSTRID` is an *originating master* — on a purchasing posting it is a vendor, not a customer, and the join will match nothing or, worse, coincidentally match something.

### The filter every activity query needs

```sql
WHERE NOT f.is_beginning_balance_forward
  AND NOT f.is_profit_loss_close
```

Omit it and period 0 BBF entries plus the year-end close land in the same total as real activity. Include it in an audit extract and the extract does not tie to GP. Neither is a default — that is why they are flags.

## Gotchas

- **`journal_entry_number` is not globally unique.** It repeats across years and companies. Any natural-key join needs entity + year.
- **`net_amount` is derived, `debit_amount`/`credit_amount` are source.** Reconcile to GP on the source pair.
- **A stale `_source_synced_at` on history rows is expected.** Closed-year rows stop changing.
- **`is_voided` is retained, not filtered.** Decide per query.
