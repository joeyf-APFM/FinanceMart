---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.receivables.fact_ar_apply

> [!info] This table is the AR history
> It is also what makes write-off reporting servable **today**: `WROFAMNT` with a date, no new ingestion required. The stated pain point — write-offs and bad-debt recovery invisible to CAMs and Community Ops — needs **this fact and a grant**.

> [!warning] Not built
> DDL: [[../ddl/07-finance-receivables.sql|07-finance-receivables.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Fact |
| **Grain** | One apply relationship |
| **Sources** | `rm20201` **∪** `rm30201` — **59 identical columns, so the union is clean** |
| **Clustering** | `CLUSTER BY (legal_entity_code, gp_customer_number, apply_date)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-08** (key uniqueness including date **and** time) |

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `ar_apply_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, gp_customer_number, apply_from_document_number, apply_from_document_type, apply_to_document_number, apply_to_document_type, apply_date, apply_time)`. **GP permits multiple partial applies between the same two documents — which is why date and time are in the key.** T-08 |
| `legal_entity_code` | STRING | No | Derived | |
| `customer_key` | BIGINT | Yes | Derived | FK to [[dim_customer]] |
| `gp_customer_number` | STRING | No | `CUSTNMBR` | Trimmed |
| `apply_from_document_number` | STRING | Yes | `APFRDCNM` | **The document doing the applying** — typically a payment or credit memo |
| `apply_from_document_type` | INT | Yes | `APFRDCTY` | |
| `apply_from_document_date` | DATE | Yes | `APFRDCDT` | |
| `apply_from_gl_post_date` | DATE | Yes | `ApplyFromGLPostDate` | |
| `apply_to_document_number` | STRING | Yes | `APTODCNM` | **The document being applied to** — typically an invoice |
| `apply_to_document_type` | INT | Yes | `APTODCTY` | |
| `apply_to_document_date` | DATE | Yes | `APTODCDT` | |
| `apply_to_gl_post_date` | DATE | Yes | `ApplyToGLPostDate` | With `apply_date`, **what makes as-of aging reconstructable** |
| `apply_to_transaction_key` | BIGINT | Yes | Derived | FK to [[fact_ar_transaction]], on the **apply-to** document. **The join that turns the apply trail into an aging history** |
| `apply_date` | DATE | Yes | `DATE1` | The date the apply was recorded |
| `apply_time` | TIMESTAMP | Yes | `TIME1` | **GP stores date and time separately**, and both are needed because several applies can share a date |
| `gl_post_date` | DATE | Yes | `GLPOSTDT` | |
| `date_key` | INT | Yes | Derived on `apply_date` | FK to [[dim_date]] |
| `fiscal_period_key` | BIGINT | Yes | Derived on `gl_post_date` | FK to [[dim_fiscal_calendar]] |
| `applied_amount` | DECIMAL(19,5) | Yes | `APPTOAMT` | **The as-of aging subtrahend** |
| `discount_taken_amount` | DECIMAL(19,5) | Yes | `DISTKNAM` | |
| `discount_available_taken` | DECIMAL(19,5) | Yes | `DISAVTKN` | |
| `writeoff_amount` | DECIMAL(19,5) | Yes | `WROFAMNT` | **A non-zero value here *is* the write-off event, and its date is known** |
| `originating_applied_amount` | DECIMAL(19,5) | Yes | `ORAPTOAM` | Originating currency |
| `originating_discount_taken` | DECIMAL(19,5) | Yes | `ORDISTKN` | |
| `originating_writeoff_amount` | DECIMAL(19,5) | Yes | `ORWROFAM` | |
| `actual_applied_amount` | DECIMAL(19,5) | Yes | `ActualApplyToAmount` | **Genuinely different from `applied_amount`** — they diverge when a rate changes between the two documents. Not the same column under two names |
| `actual_writeoff_amount` | DECIMAL(19,5) | Yes | `ActualWriteOffAmount` | |
| `realized_gain_loss` | DECIMAL(19,5) | Yes | `RLGANLOS` | Realised FX gain/loss. **Non-zero only in a multicurrency context, which for APFM means CAPFM** |
| `apply_to_exchange_rate` | DECIMAL(19,7) | Yes | `APTOEXRATE` | |
| `apply_from_exchange_rate` | DECIMAL(19,7) | Yes | `APFRMEXRATE` | |
| `apply_to_rate_calc_method` | INT | Yes | `APTORTCLCMETH` | Multiply or divide. **Backwards inverts the translated amount** |
| `from_currency_id` | STRING | Yes | `FROMCURR` | |
| `currency_key` | BIGINT | Yes | Derived | FK to [[dim_currency]], **on the apply-to currency** |
| `gp_currency_id` | STRING | Yes | `CURNCYID` | |
| `is_posted` | BOOLEAN | Yes | `POSTED` | |
| `revaluation_status` | INT | Yes | `Revaluation_Status` | |
| `is_history` | BOOLEAN | No | Derived | True from `rm30201`. **The trail must be read across both: an apply can be in history while the document it applies to is still open, and vice versa** |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | Guarded-layer table |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_ar_apply PRIMARY KEY (ar_apply_key)`; `fk_ar_apply_customer` → `dim_customer`; `fk_ar_apply_document FOREIGN KEY (apply_to_transaction_key)` → `fact_ar_transaction`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `apply_relationship` | |
| `unions` | `rm20201,rm30201` | |
| `is_aging_history_source` | `true` | **Stated on the object**: this is where historical aging comes from |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[fact_ar_transaction]] (apply-**to**) | `a.apply_to_transaction_key = t.ar_transaction_key` | N:1 | **Declared FK.** The aging-history join |
| [[fact_ar_transaction]] (apply-**from**) | natural key — **no FK exists** | N:1 | See below |
| [[dim_customer]] | `a.customer_key = dc.customer_key` | N:1 | Declared FK |
| [[dim_currency]] | `a.currency_key = c.currency_key` | N:1 | Apply-**to** currency |
| [[dim_fiscal_calendar]] | `a.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Filter `period_level = 'period'` |
| [[dim_date]] | `a.date_key = d.date_key` | N:1 | On `apply_date` |
| [[mart_writeoff]] | `w.ar_apply_key = a.ar_apply_key` | 1:1 | Only the non-zero-`WROFAMNT` subset |
| [[snap_ar_aging_daily]] | Validation, not a join | — | The reconstruction checks the snapshot |
| [[fact_gl_posting]] | via `gl_post_date` + the document's `trx_source` | N:M | No `trx_source` on this table — go through the document |

### The apply-**from** document has no foreign key

`apply_to_transaction_key` is resolved and constrained. The apply-**from** side is not, so reaching the payment or credit memo needs a natural-key join — and the entity must be in it:

```sql
-- RIGHT
LEFT JOIN finance.receivables.fact_ar_transaction tf
       ON  tf.legal_entity_code       =  a.legal_entity_code
       AND trim(tf.gp_customer_number) = trim(a.gp_customer_number)
       AND trim(tf.document_number)    = trim(a.apply_from_document_number)
       AND tf.document_type_code       =  a.apply_from_document_type

-- WRONG: document numbers repeat across customers and companies
LEFT JOIN ... ON trim(tf.document_number) = trim(a.apply_from_document_number)
```

`LEFT`, not inner — an apply can reference a from-document that has aged out of both source tables.

### Reconstructing aging: the reason this table exists

```sql
WITH as_of_balance AS (
  SELECT t.ar_transaction_key,
         t.legal_entity_code,
         t.gp_customer_number,
         t.due_date,
         t.original_amount
           - coalesce(sum(a.applied_amount),   0)
           - coalesce(sum(a.writeoff_amount),  0) AS outstanding
  FROM      finance.receivables.fact_ar_transaction t
  LEFT JOIN finance.receivables.fact_ar_apply       a
         ON  a.apply_to_transaction_key = t.ar_transaction_key
         AND a.apply_date <= :as_of                 -- the load-bearing predicate
  WHERE t.document_date <= :as_of
  GROUP BY 1,2,3,4,5
)
SELECT * FROM as_of_balance WHERE outstanding <> 0
```

**`a.apply_date <= :as_of` must be in the `ON` clause, not the `WHERE`.** In the `WHERE` it converts the `LEFT JOIN` to an inner one and drops every document with no applies — i.e. every fully-unpaid invoice, which is precisely the population an aging report is about.

### Write-offs, servable with no new ingestion

```sql
SELECT a.legal_entity_code, a.gp_customer_number,
       a.apply_to_document_number, a.apply_date AS writeoff_date,
       a.writeoff_amount, a.actual_writeoff_amount
FROM   finance.receivables.fact_ar_apply a
WHERE  coalesce(a.writeoff_amount, 0) <> 0
```

`<> 0`, not `> 0` — a **recovery** is a negative write-off, and bad-debt recovery is half the stated requirement. [[mart_writeoff]] is this query materialised with `business_unit_id` resolved as of the date.

### Do not sum `applied_amount` and `actual_applied_amount`

They are two measurements of one event. Pick one per query: `applied_amount` (`APPTOAMT`) to reconcile to the document, `actual_applied_amount` for the amount actually moved after a rate change.

## Gotchas

- **`apply_time` is a separate column** and part of the key. A `DISTINCT` on `(from, to, date)` collapses legitimate multiple partial applies.
- **`is_history` on the apply and `is_history` on the document are independent.** Filtering both to the same value drops valid combinations.
- **`realized_gain_loss` is CAPFM-only in practice.** An all-zero column for APFM is correct, not broken.
- **No `_source_synced_at`.** Provenance is `source_table` + `_loaded_at`.
- **T-08 is unresolved.** If date and time are still not enough to make the key unique, the surrogate collides and applies vanish — which corrupts every reconstructed balance downstream.
