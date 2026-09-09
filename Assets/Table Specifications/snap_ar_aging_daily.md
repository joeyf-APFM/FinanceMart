---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.receivables.snap_ar_aging_daily

> [!TIP]
> **Start this early — but it is not the irrecoverable one**
>
> Unlike [snap_period_close_daily](snap_period_close_daily.md), a missed day here is **recoverable at cost** from [fact_ar_apply](fact_ar_apply.md). This snapshot exists for **cost**, not recoverability: the reconstruction is an expensive window over two unioned tables and depends on the apply trail being complete across the open/history boundary. Snapshot for routine reporting; reconstruct to validate the snapshot and to answer questions predating it.

> [!WARNING]
> **Not built**
>
> DDL: [07-finance-receivables.sql](../ddl/07-finance-receivables.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Snapshot (**append-only**) |
| **Grain** | Snapshot date × legal entity × customer × document × document type |
| **Source** | The open AR file — `rm20101`, both companies, via the guarded views |
| **Clustering** | `CLUSTER BY (snapshot_date, legal_entity_code)` |
| **Written by** | `sp-finance-snapshot` — a separate principal from the mart build |
| **Readers** | `finance-analysts` |

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `snapshot_date` | DATE | No | Job | **PK.** The date this observation was taken |
| `legal_entity_code` | STRING | No | Derived | **PK** |
| `gp_customer_number` | STRING | No | `CUSTNMBR` | **PK.** Trimmed |
| `customer_key` | BIGINT | Yes | Derived | FK to [dim_customer](dim_customer.md) |
| `document_number` | STRING | No | `DOCNUMBR` | **PK** |
| `document_type_code` | INT | No | `RMDTYPAL` | **PK** |
| `ar_transaction_key` | BIGINT | Yes | Derived | FK to [fact_ar_transaction](fact_ar_transaction.md) |
| `document_date` | DATE | Yes | `DOCDATE` | **As observed** |
| `due_date` | DATE | Yes | `DUEDATE` | **As observed** — GP permits it to be changed |
| `original_amount` | DECIMAL(19,5) | Yes | `ORTRXAMT` | As observed |
| `outstanding_amount` | DECIMAL(19,5) | Yes | `CURTRXAM` | **As observed on `snapshot_date`. This is the value GP overwrites and the reason this table exists** |
| `gp_aging_bucket` | STRING | Yes | `AGNGBUKT` | GP's own assignment, **captured so a later change to the bucket setup does not silently rewrite history** |
| `days_past_due` | INT | Yes | Derived | `snapshot_date − due_date`. **Recorded rather than computed on read, so the figure does not shift if bucket definitions change** |
| `currency_key` | BIGINT | Yes | Derived | FK to [dim_currency](dim_currency.md) |
| `source_table` | STRING | No | Literal | e.g. `main.prod_gp_apfm_dbo_live.rm20101` |
| `_loaded_at` | TIMESTAMP | No | Job | |

**Constraint:** `pk_snap_ar_aging_daily PRIMARY KEY (snapshot_date, legal_entity_code, gp_customer_number, document_number, document_type_code)`. **No foreign keys are declared**, deliberately — a snapshot must be writable even when a dimension has not yet been rebuilt.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `append_only` | `true` | Never update a prior day's row. A restated figure is a new `snapshot_date`, not an edit |
| `has_reconstruction_fallback` | `fact_ar_apply` | **The reason this is not the irrecoverable snapshot** |

## A document's disappearance is data

The snapshot reads the **open** file. When GP moves a document to `rm30101`, it stops appearing:

> **The last `snapshot_date` on which a document appears is (within one day) its settlement date.**

That absence is a fact about the document, not a gap in the table — and it is why the snapshot is append-only rather than a current-state copy.

Same caveat as elsewhere: **a document settled and reopened within one day is invisible.** Daily granularity is the floor.

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [fact_ar_transaction](fact_ar_transaction.md) | `s.ar_transaction_key = t.ar_transaction_key` | N:1 | The current-state document |
| [dim_customer](dim_customer.md) | `s.customer_key = dc.customer_key` | N:1 | `LEFT JOIN` — no FK declared |
| [dim_currency](dim_currency.md) | `s.currency_key = c.currency_key` | N:1 | |
| [dim_date](dim_date.md) | `d.full_date = s.snapshot_date` | N:1 | **No `date_key` on this table** — join on the date |
| [mart_ar_aging](mart_ar_aging.md) | This snapshot is one of its two bases | — | `computation_basis = 'snapshot'` |
| [fact_ar_apply](fact_ar_apply.md) | Validation, not a join | — | The reconstruction that checks this table |

### `snapshot_date` must be pinned

```sql
-- RIGHT: one observation
WHERE snapshot_date = :d

-- RIGHT: a trend — the reason the table exists
WHERE snapshot_date BETWEEN :d1 AND :d2
GROUP BY snapshot_date

-- WRONG: sums every day ever snapshotted
SELECT gp_customer_number, sum(outstanding_amount) FROM ... GROUP BY 1
```

The wrong version grows every day the job runs. An open invoice snapshotted for 90 days contributes its balance 90 times.

### Validating the snapshot against the reconstruction

This is the check the snapshot exists to be measured by, not a redundant query:

```sql
SELECT s.snapshot_date,
       sum(s.outstanding_amount)                        AS snapshot_total,
       sum(r.outstanding)                               AS reconstructed_total,
       sum(s.outstanding_amount) - sum(r.outstanding)   AS delta
FROM      finance.receivables.snap_ar_aging_daily s
LEFT JOIN (/* the as-of reconstruction from fact_ar_apply, parameterised on the same date */) r
       ON  r.ar_transaction_key = s.ar_transaction_key
WHERE  s.snapshot_date = :d
GROUP BY 1
```

A non-zero delta is expected to be small and explainable. A large one usually means the apply trail is incomplete across the open/history boundary — which is the dependency the design already flags, and which would invalidate every reconstructed figure in [mart_ar_aging](mart_ar_aging.md).

### Reading `gp_aging_bucket` from here, not from the document

[fact_ar_transaction](fact_ar_transaction.md)`.gp_aging_bucket` is current state and null for history rows. **This table has the bucket as it stood on each date**, which is what T-09 needs for any period other than today.

## Gotchas

- **Only open documents are captured.** A customer's total here is the open balance, never lifetime receivables.
- **`days_past_due` is frozen at snapshot time.** Recomputing it from `snapshot_date − due_date` should agree — if it does not, `due_date` was changed in GP after the snapshot, which is itself worth knowing.
- **No `is_history` column.** Everything here was open when observed, by construction.
- **The first `snapshot_date` bounds the table.** Questions before it must be reconstructed, and reconstructions and snapshots coexist in [mart_ar_aging](mart_ar_aging.md) under `computation_basis` rather than being silently blended.
- **This is not the same risk profile as [snap_period_close_daily](snap_period_close_daily.md).** That one has no fallback and is tagged `irrecoverable_if_delayed`. This one has [fact_ar_apply](fact_ar_apply.md).
