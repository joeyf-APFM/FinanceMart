---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.general_ledger.fact_gl_posting_work

> [!warning] Not built
> DDL: [06-finance-general-ledger.sql](../ddl/06-finance-general-ledger.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Fact |
| **Grain** | One **unposted** GL distribution line |
| **Sources** | `gl10000 + gl10001` (general journal) and `gl10100 + gl10101` (quick journal) |
| **Measure class** | `not_recognized` |
| **Clustering** | `CLUSTER BY (legal_entity_code, work_source, fiscal_year)` |
| **Readers** | `finance-analysts` |

## What it is for

*"What is sitting unposted at period end"* — a **close-readiness question rather than a reporting one.**

> [!danger] Never sum this with [fact_gl_posting](fact_gl_posting.md)
> Unposted amounts are **not recognized** and must never be added to the posted fact in a single measure. The `measure_class = 'not_recognized'` tag exists to make that visible on the object.

## `work_source` is load-bearing, not cosmetic

Two source pairs with **materially different shapes**, distinguished rather than blended:

| `work_source` | Tables | Shape |
|---|---|---|
| `general_journal` | `gl10000` + `gl10001` | `gl10001` has **37 columns**, full multicurrency, separate debit and credit |
| `quick_journal` | `gl10100` + `gl10101` | `gl10101` has **13 columns**, **no multicurrency**, a **single `TRXAMNT`** |

**Any consumer that ignores this flag will produce nulls it cannot explain** — every multicurrency column and both debit/credit columns are null on quick-journal rows by construction, not by data quality.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `gl_work_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, work_source, batch_number, journal_entry_number, sequence_number)` |
| `legal_entity_code` | STRING | No | Derived | |
| `legal_entity_key` | BIGINT | Yes | Derived | FK to [dim_legal_entity](dim_legal_entity.md) |
| `work_source` | STRING | No | Derived | `general_journal` or `quick_journal` |
| `batch_number` | STRING | Yes | `BACHNUMB` | **Null for quick journals**, which are keyed on `BSNSFMID` instead |
| `business_form_id` | STRING | Yes | `BSNSFMID` | **Quick journals only** |
| `journal_entry_number` | BIGINT | No | `JRNENTRY` | |
| `sequence_number` | BIGINT | No | `SQNCLINE` | Note: `SQNCLINE`, not `SEQNUMBR` as on the posted fact |
| `account_key` | BIGINT | Yes | Derived | FK to [dim_gl_account](dim_gl_account.md) |
| `account_index` | INT | Yes | `ACTINDX` | |
| `transaction_date` | DATE | Yes | `TRXDATE` | |
| `document_date` | DATE | Yes | `DOCDATE` | |
| `date_key` | INT | Yes | Derived | FK to [dim_date](dim_date.md) |
| `fiscal_year` | INT | Yes | `OPENYEAR` | |
| `fiscal_period` | INT | Yes | `PERIODID` | |
| `fiscal_period_key` | BIGINT | Yes | Derived | FK to [dim_fiscal_calendar](dim_fiscal_calendar.md) — **not declared as a constraint** on this table |
| `debit_amount` | DECIMAL(19,5) | Yes | `gl10001.DEBITAMT` | **Null for quick journals** |
| `credit_amount` | DECIMAL(19,5) | Yes | `gl10001.CRDTAMNT` | **Null for quick journals** |
| `signed_amount` | DECIMAL(19,5) | Yes | `gl10101.TRXAMNT` / derived | **The one amount column populated for every row.** `TRXAMNT` for quick journals; debit − credit for general journals |
| `originating_debit_amount` | DECIMAL(19,5) | Yes | `gl10001.ORDBTAMT` | General journals only |
| `originating_credit_amount` | DECIMAL(19,5) | Yes | `gl10001.ORCRDAMT` | General journals only |
| `currency_key` | BIGINT | Yes | Derived | FK to [dim_currency](dim_currency.md). **Null for quick journals** |
| `exchange_rate` | DECIMAL(19,7) | Yes | `XCHGRATE` | General journals only |
| `posting_status` | INT | Yes | `PSTGSTUS` | Where the batch is in GP's posting workflow |
| `error_state` | INT | Yes | `ERRSTATE` | **A non-zero value means GP itself considers the batch unpostable — usually the answer to "why has this not posted"** |
| `is_voided` | BOOLEAN | Yes | `VOIDED` | |
| `source_document` | STRING | Yes | `SOURCDOC` | |
| `reference_text` | STRING | Yes | `REFRENCE` | |
| `description` | STRING | Yes | `DSCRIPTN` | |
| `trx_source` | STRING | Yes | `TRXSORCE` | |
| `series_id` | INT | Yes | `SERIES` | **General journals only** |
| `last_modified_by_user_id` | STRING | Yes | `LASTUSER` | Joins to [dim_gp_user](dim_gp_user.md) |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | The tables the row was assembled from |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_gl_posting_work PRIMARY KEY (gl_work_key)`; `fk_gl_work_account FOREIGN KEY (account_key) REFERENCES finance.general_ledger.dim_gl_account`. **Only one FK is declared** — no legal-entity, currency or period constraint, unlike the posted fact.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `unposted_gl_distribution_line` | |
| `measure_class` | `not_recognized` | |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_gl_account](dim_gl_account.md) | `f.account_key = a.account_key` | N:1 | Declared FK |
| [dim_legal_entity](dim_legal_entity.md) | `f.legal_entity_key = le.legal_entity_key` | N:1 | Not declared, but the column is there |
| [dim_currency](dim_currency.md) | `f.currency_key = c.currency_key` | N:1 | **Matches nothing on quick-journal rows.** `LEFT JOIN` |
| [dim_date](dim_date.md) | `f.date_key = d.date_key` | N:1 | |
| [dim_fiscal_calendar](dim_fiscal_calendar.md) | `f.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Filter `period_level = 'period'` |
| [dim_gp_user](dim_gp_user.md) | `trim(u.gp_user_id) = trim(f.last_modified_by_user_id)` | N:1 | `LEFT JOIN` |
| [fact_gl_posting](fact_gl_posting.md) | — | — | **Do not union or sum together.** See below |

### Always sum `signed_amount`, never debit/credit

```sql
-- RIGHT: works for both work_sources
SELECT work_source, sum(signed_amount) AS unposted
FROM   finance.general_ledger.fact_gl_posting_work
GROUP BY 1

-- WRONG: silently returns only general-journal amounts
SELECT sum(debit_amount) - sum(credit_amount) FROM ...
```

The wrong version does not error. `sum()` skips nulls, so quick journals simply contribute zero and the unposted total is understated by however much sits in quick journals — which is exactly the population a close-readiness check exists to find.

### Comparing unposted to posted without adding them

The legitimate cross-fact question is *"what would change if this posted"*, which is a **side-by-side**, not a union:

```sql
SELECT a.account_key,
       p.posted_activity,
       w.unposted_activity
FROM      (SELECT account_key, sum(net_amount) AS posted_activity
           FROM finance.general_ledger.fact_gl_posting
           WHERE fiscal_year = :y AND fiscal_period = :p
             AND NOT is_beginning_balance_forward AND NOT is_profit_loss_close
           GROUP BY 1) p
FULL OUTER JOIN
          (SELECT account_key, sum(signed_amount) AS unposted_activity
           FROM finance.general_ledger.fact_gl_posting_work
           WHERE fiscal_year = :y AND fiscal_period = :p
           GROUP BY 1) w USING (account_key)
JOIN finance.general_ledger.dim_gl_account a USING (account_key)
```

Two named columns, never one summed measure. The moment they are added the result is neither recognized nor not-recognized, and nothing in the schema records which.

### The close-readiness query

```sql
SELECT legal_entity_code, work_source, batch_number, business_form_id,
       error_state, posting_status, count(*) AS lines, sum(signed_amount) AS amount
FROM   finance.general_ledger.fact_gl_posting_work
WHERE  fiscal_year = :y AND fiscal_period = :p
GROUP BY 1,2,3,4,5,6
ORDER BY error_state DESC, abs(sum(signed_amount)) DESC
```

`error_state` first, because a non-zero value is GP telling you the batch cannot post — that is the answer, not a symptom to investigate further.

## Gotchas

- **`batch_number` is null for quick journals** and `business_form_id` is null for general journals. Neither is a key on its own; the surrogate covers both.
- **`series_id` is null on quick journals**, so a close-series join drops them.
- **There is no `is_history` here.** Unposted rows have no open/closed-year split — all four source tables are current-state work tables.
- **No `_source_synced_at`.** Work rows churn; provenance is `_loaded_at` only.
