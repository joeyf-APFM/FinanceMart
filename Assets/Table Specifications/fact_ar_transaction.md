---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.receivables.fact_ar_transaction

> [!warning] Not built
> DDL: [[../ddl/07-finance-receivables.sql|07-finance-receivables.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Fact |
| **Grain** | One receivables document |
| **Sources** | `rm20101` (outstanding) **∪** `rm30101` (fully applied) — both companies |
| **Clustering** | `CLUSTER BY (legal_entity_code, gp_customer_number, document_date)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-07** (key uniqueness across the union) |

## The two source tables are close but not identical

| Column | `rm20101` (open) | `rm30101` (history) |
|---|---|---|
| `AGNGBUKT` — GP's own aging bucket | ✅ | ❌ |
| `CBKIDCRD` / `CBKIDCSH` / `CBKIDCHK` — checkbooks | ✅ | ❌ |
| `DISAVTKN` | ✅ | ❌ |
| `BALFWDNM` | ❌ | ✅ |

The `AGNGBUKT` asymmetry is the one that matters: **GP's bucket assignment exists only for open documents**, so the bucket reconciliation that [[mart_ar_aging]] depends on (**T-09**) can be validated against open documents only. Reconstructed historical aging has no GP bucket to check itself against.

## `current_amount` is current state, and that corrects the initial plan

GP moves a document out of `rm20101` once fully applied, so today's open file cannot answer *"what was aged 60+ last March."* **That looks unrecoverable and is not** — [[fact_ar_apply]] carries `DATE1`, `GLPOSTDT`, `APTODCDT`, `ApplyToGLPostDate` and `APPTOAMT`, so:

> outstanding as of **D** = `original_amount` − applies dated on or before **D**

**The apply trail is the history.** `current_amount` is only ever the balance as of the last sync.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `ar_transaction_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, gp_customer_number, document_type_code, document_number)`. **T-07** must confirm uniqueness across the union |
| `legal_entity_code` | STRING | No | Derived | APFM or CAPFM |
| `legal_entity_key` | BIGINT | Yes | Derived | FK to [[dim_legal_entity]] |
| `customer_key` | BIGINT | Yes | Derived | FK to [[dim_customer]] |
| `gp_customer_number` | STRING | No | `CUSTNMBR` | **Trimmed. GP char columns are space-padded and an untrimmed join returns nothing** |
| `parent_customer_number` | STRING | Yes | `CPRCSTNM` | |
| `document_number` | STRING | No | `DOCNUMBR` | |
| `document_type_code` | INT | No | `RMDTYPAL` | Sale, scheduled payment, debit memo, finance charge, service repair, warranty, credit memo, return, payment. **The sign convention of every amount below depends on it** |
| `document_type_name` | STRING | Yes | Decoded | Decoded here so no consumer has to hold the code table |
| `document_date` | DATE | Yes | `DOCDATE` | Blank-date sentinel → NULL |
| `due_date` | DATE | Yes | `DUEDATE` | **The basis for every aging calculation.** A null puts a document in no bucket and must be surfaced, not defaulted |
| `post_date` | DATE | Yes | `POSTDATE` | |
| `gl_post_date` | DATE | Yes | `GLPOSTDT` | **What reconciles this fact to [[fact_gl_posting]]** |
| `sale_date` | DATE | Yes | `SALEDATE` | |
| `discount_date` | DATE | Yes | `DISCDATE` | |
| `date_paid_off` | DATE | Yes | `DINVPDOF` | Populated when fully applied — **the boundary between the open and history tables** |
| `date_key` | INT | Yes | Derived on `document_date` | FK to [[dim_date]] |
| `fiscal_period_key` | BIGINT | Yes | Derived on `gl_post_date` | FK to [[dim_fiscal_calendar]] |
| `original_amount` | DECIMAL(19,5) | Yes | `ORTRXAMT` | The document as issued. **The numerator for as-of aging reconstruction** |
| `current_amount` | DECIMAL(19,5) | Yes | `CURTRXAM` | **Outstanding as of the last sync — current state only** |
| `sales_amount` | DECIMAL(19,5) | Yes | `SLSAMNT` | |
| `cost_amount` | DECIMAL(19,5) | Yes | `COSTAMNT` | |
| `freight_amount` | DECIMAL(19,5) | Yes | `FRTAMNT` | |
| `miscellaneous_amount` | DECIMAL(19,5) | Yes | `MISCAMNT` | |
| `tax_amount` | DECIMAL(19,5) | Yes | `TAXAMNT` | |
| `trade_discount_amount` | DECIMAL(19,5) | Yes | `TRDISAMT` | |
| `cash_amount` | DECIMAL(19,5) | Yes | `CASHAMNT` | |
| `discount_taken_amount` | DECIMAL(19,5) | Yes | `DISTKNAM` | |
| `discount_available_amount` | DECIMAL(19,5) | Yes | `DISAVAMT` | |
| `writeoff_amount` | DECIMAL(19,5) | Yes | `WROFAMNT` | **Document level: "how much of this document was written off."** For *when*, use [[fact_ar_apply]] |
| `commission_amount` | DECIMAL(19,5) | Yes | `COMDLRAM` | |
| `currency_key` | BIGINT | Yes | Derived | FK to [[dim_currency]] |
| `gp_currency_id` | STRING | Yes | `CURNCYID` | |
| `gp_aging_bucket` | STRING | Yes | `rm20101.AGNGBUKT` | **NULL for every `rm30101` row.** The only independent check on [[mart_ar_aging]]'s cutoffs, available for open documents only |
| `payment_terms_id` | STRING | Yes | `PYMTRMID` | |
| `salesperson_id` | STRING | Yes | `SLPRSNID` | |
| `sales_territory` | STRING | Yes | `SLSTERCD` | |
| `check_number` | STRING | Yes | `CHEKNMBR` | |
| `batch_number` | STRING | Yes | `BACHNUMB` | |
| `batch_source` | STRING | Yes | `BCHSOURC` | |
| `trx_source` | STRING | Yes | `TRXSORCE` | **Ties the document to the GL batch that posted it** |
| `description` | STRING | Yes | `TRXDSCRN` | |
| `customer_po_number` | STRING | Yes | `CSPORNBR` | |
| `apply_with_code` | INT | Yes | `APLYWITH` | |
| `void_status` | INT | Yes | `VOIDSTTS` | **A voided document still has rows.** Excluding voids is an explicit consumer decision |
| `void_date` | DATE | Yes | `VOIDDATE` | |
| `gp_delete_flag` | BOOLEAN | Yes | `DELETE1` | **GP's own delete marker — a different concept from Fivetran's `_fivetran_deleted`.** The guarded layer removes the tombstone and leaves this; both must be considered |
| `is_direct_debit` | BOOLEAN | Yes | `DIRECTDEBIT` | |
| `is_electronic` | BOOLEAN | Yes | `Electronic` | |
| `is_factored` | BOOLEAN | Yes | `Factoring` | |
| `posted_by_user_id` | STRING | Yes | `PSTUSRID` | Joins to [[dim_gp_user]] |
| `last_edited_by_user_id` | STRING | Yes | `LSTUSRED` | |
| `is_history` | BOOLEAN | No | Derived | True from `rm30101`. **A document's presence in history is itself the fact that it was settled** |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | Guarded-layer table |
| `_source_synced_at` | TIMESTAMP | Yes | `_fivetran_synced` | **NOT freshness** |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_ar_transaction PRIMARY KEY (ar_transaction_key)`; FKs to `dim_customer`, `dim_legal_entity`, `dim_currency`, `common.calendar.dim_fiscal_calendar`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `ar_document` | |
| `unions` | `rm20101,rm30101` | |
| `current_state_column` | `current_amount` | Names the one column that is not safe for historical questions |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_customer]] | `f.customer_key = dc.customer_key` | N:1 | Declared FK. **PII-restricted schema** |
| [[dim_legal_entity]] | `f.legal_entity_key = le.legal_entity_key` | N:1 | Declared FK |
| [[dim_currency]] | `f.currency_key = c.currency_key` | N:1 | Declared FK |
| [[dim_fiscal_calendar]] | `f.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Declared FK. Filter `period_level = 'period'` |
| [[dim_date]] | `f.date_key = d.date_key` | N:1 | **On `document_date` only** — see below |
| [[fact_ar_apply]] | `ap.apply_to_transaction_key = f.ar_transaction_key` | 1:N | **The join that turns the apply trail into aging history** |
| [[dim_collections_attributes]] | `f.customer_key = ca.customer_key` | N:1 | **`LEFT JOIN` only.** Sparse satellite |
| [[fact_gl_posting]] | `trim(g.trx_source) = trim(f.trx_source)` + entity | N:M | The subledger tie. Answers *"what is behind this batch"* |
| [[snap_ar_aging_daily]] | `s.ar_transaction_key = f.ar_transaction_key` | 1:N | One row per snapshot date |
| [[mart_ar_aging]] | `(legal_entity_code, gp_customer_number)` | N:M | Aggregate — customer grain, not document grain |

### Seven date columns, one `date_key`

`date_key` resolves `document_date`. Aging works from **`due_date`**, which has no key column at all:

```sql
-- RIGHT: aging by due date, second aliased join
LEFT JOIN common.calendar.dim_date dd ON dd.date_key = f.date_key            -- document
LEFT JOIN common.calendar.dim_date du ON du.full_date = f.due_date           -- due

-- Or skip the dimension entirely and predicate directly
WHERE f.due_date < :as_of

-- WRONG: ages by document date and calls it days past due
WHERE dd.full_date < :as_of
```

An invoice dated the 1st with 30-day terms is not past due on the 15th. Ageing off `date_key` reports it as 14 days overdue.

### The as-of balance, which is the whole point of this schema

```sql
-- RIGHT: as-of outstanding, reconstructed
SELECT t.ar_transaction_key,
       t.original_amount
         - coalesce(sum(a.applied_amount), 0)
         - coalesce(sum(a.writeoff_amount), 0) AS outstanding_as_of
FROM   finance.receivables.fact_ar_transaction t
LEFT JOIN finance.receivables.fact_ar_apply a
       ON  a.apply_to_transaction_key = t.ar_transaction_key
       AND a.apply_date <= :as_of
WHERE  t.document_date <= :as_of
GROUP BY t.ar_transaction_key, t.original_amount

-- WRONG for any historical date: current_amount is today's balance
SELECT sum(current_amount) FROM ... WHERE document_date <= :as_of
```

The wrong version understates every historical aging figure, because documents settled *since* `:as_of` now show a zero or near-zero `current_amount` — and documents settled *and moved to history* still carry their last-known value. Neither is the balance that existed on the date.

### Reconciling to the GL

```sql
-- gl_post_date, not document_date — the GL sees the posting date
JOIN finance.general_ledger.fact_gl_posting g
  ON  g.legal_entity_code = f.legal_entity_code
  AND trim(g.trx_source)  = trim(f.trx_source)
WHERE g.series_id = 3   -- Sales
```

Many-to-many: one batch, many GL lines, many AR documents. It does **not** produce a per-invoice GL amount.

## Gotchas

- **Always `trim()` `gp_customer_number`.** Space-padded `char` on both sides.
- **`gp_aging_bucket` being null is not a data-quality issue** — it is a history row. Filtering on `gp_aging_bucket IS NOT NULL` silently restricts to open documents.
- **`is_history` and `void_status` and `gp_delete_flag` are three independent exclusions.** None is applied for you.
- **Payments and credit memos are in here too**, as their own `document_type_code` values. Summing `original_amount` across all types nets receipts against invoices — sometimes wanted, never by accident.
- **T-07 is unresolved.** If `(entity, customer, type, number)` is not unique across the union, the surrogate collides and rows are lost on the load, not flagged.
