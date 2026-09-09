---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.receivables.mart_ar_aging

> [!CAUTION]
> **Publication is blocked**
>
> **Bucket cutoffs must be reconciled to GP's own aging setup before this is published.** The query research catalog flags it twice. Cutoffs that disagree with GP produce a report that is **defensibly wrong, which is worse than one that is obviously wrong** — it survives review and gets quoted. The check is [fact_ar_transaction](fact_ar_transaction.md)`.gp_aging_bucket`, and it exists **for open documents only**. Test **T-09**.

> [!WARNING]
> **Not built**
>
> DDL: [07-finance-receivables.sql](../ddl/07-finance-receivables.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Mart (aggregate, **vintaged**) |
| **Grain** | As-of date × legal entity × customer × bucket × currency × **`computation_basis`** |
| **Sources** | [snap_ar_aging_daily](snap_ar_aging_daily.md) **and** [fact_ar_apply](fact_ar_apply.md) — both, distinguished |
| **Clustering** | `CLUSTER BY (as_of_date, legal_entity_code)` |
| **Readers** | `finance-analysts` |

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `as_of_date` | DATE | No | Pipeline | **PK.** *"Aging is a vintage measure and the same customer aged on two dates is two legitimate answers"* |
| `legal_entity_code` | STRING | No | Derived | **PK** |
| `customer_key` | BIGINT | Yes | Derived | FK to [dim_customer](dim_customer.md) |
| `gp_customer_number` | STRING | No | `CUSTNMBR` | **PK.** Trimmed |
| `aging_bucket` | STRING | No | Derived | **PK.** The bucket label. **Cutoffs must match GP's setup — T-09** |
| `aging_bucket_order` | INT | No | Derived | Sort position, **so a consumer never sorts bucket labels alphabetically and gets `30-60` before `current`** |
| `currency_key` | BIGINT | Yes | Derived | **PK.** FK to [dim_currency](dim_currency.md). **Aging is computed per currency; a total across currencies without translation is meaningless** |
| `outstanding_amount` | DECIMAL(19,5) | Yes | Derived | Sum of the as-of outstanding balance over the grain |
| `document_count` | BIGINT | Yes | Derived | Documents in the bucket |
| `computation_basis` | STRING | No | Derived | **PK.** `snapshot` (from [snap_ar_aging_daily](snap_ar_aging_daily.md)) or `reconstructed` (original amount less applies dated on or before `as_of_date`). **Carried because the two can legitimately differ, and knowing which produced a figure is the first question anyone will ask about a discrepancy** |
| `source_system` | STRING | No | Literal | `GP` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_mart_ar_aging PRIMARY KEY (as_of_date, legal_entity_code, gp_customer_number, aging_bucket, currency_key, computation_basis)`; `fk_ar_aging_customer` → `dim_customer`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `as_of_x_entity_x_customer_x_bucket_x_currency` | |
| `publication_blocked_on` | `gp_aging_setup_reconciliation` | **On the object**, so the block cannot be lost in a doc |

## Two figures for one key, on purpose

Both a snapshot-derived and a reconstructed row can exist for the same `(as_of_date, entity, customer, bucket, currency)`. That is not duplication:

- The **reconstruction validates the snapshot.** Hiding a disagreement between them would defeat the purpose of computing both.
- The snapshot **cannot answer questions before its first day**; the reconstruction can.
- The reconstruction **depends on the apply trail being complete across the open/history boundary**; the snapshot does not.

Neither is designated correct. `computation_basis` is in the primary key so a consumer must choose.

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_customer](dim_customer.md) | `m.customer_key = dc.customer_key` | N:1 | Declared FK. **PII-restricted schema** |
| [dim_currency](dim_currency.md) | `m.currency_key = c.currency_key` | N:1 | |
| [dim_date](dim_date.md) | `d.full_date = m.as_of_date` | N:1 | No `date_key` column |
| [dim_collections_attributes](dim_collections_attributes.md) | `m.customer_key = ca.customer_key` | N:1 | **`LEFT JOIN` only.** The natural pairing: aging plus who owns the collections relationship |
| [bridge_customer_to_business_unit](bridge_customer_to_business_unit.md) | as-of on `m.as_of_date` | **1:N** | **Fan-out *and* as-of.** See below |
| [bridge_customer_to_family](bridge_customer_to_family.md) | `m.customer_key = b.customer_key` | **1:N** | Fan-out. Do not group amounts by family |
| [fact_ar_transaction](fact_ar_transaction.md) | `(legal_entity_code, gp_customer_number)` | 1:N | Drill-down only — this mart is customer grain, not document grain |
| [mart_writeoff](mart_writeoff.md) | `(legal_entity_code, gp_customer_number)` | 1:N | Aging beside write-offs on the same customer |

### Every query pins `computation_basis` — or names it

```sql
-- RIGHT: routine reporting
WHERE computation_basis = 'snapshot'

-- RIGHT: a historical question predating the snapshot
WHERE computation_basis = 'reconstructed'

-- RIGHT: the validation, which is why both exist
SELECT aging_bucket, computation_basis, sum(outstanding_amount)
FROM   finance.receivables.mart_ar_aging
WHERE  as_of_date = :d
GROUP BY 1, 2

-- WRONG: doubles the receivable
SELECT aging_bucket, sum(outstanding_amount) FROM ... WHERE as_of_date = :d GROUP BY 1
```

The wrong version returns **almost exactly twice** the real balance, with a plausible bucket distribution and a plausible customer list. It is the most likely way to misuse this table, and it is why `computation_basis` sits in the key rather than in a `_meta` column.

### And pins `as_of_date`

```sql
-- WRONG: sums every vintage
SELECT gp_customer_number, sum(outstanding_amount) FROM ... GROUP BY 1
```

Combined with an unpinned `computation_basis`, a query can be wrong by a factor of *2 × the number of days loaded*.

### Sort on `aging_bucket_order`, never on the label

```sql
ORDER BY aging_bucket_order        -- current, 1-30, 31-60, 61-90, 91+
-- not
ORDER BY aging_bucket              -- 1-30, 31-60, 61-90, 91+, current
```

The column exists for exactly this. An alphabetical bucket order reads as a data error to Finance and undermines the whole report.

### Resolving to a community is an as-of join

```sql
LEFT JOIN finance.identity.bridge_customer_to_business_unit b
       ON  b.customer_key = m.customer_key
       AND b.valid_from  <= m.as_of_date
       AND (b.valid_to IS NULL OR b.valid_to > m.as_of_date)
```

Two hazards compose here: the as-of predicate must use **`m.as_of_date`, not `current_date`** (otherwise historical aging is re-attributed to today's community), **and** the bridge is many-to-many, so `outstanding_amount` fans out. Use it to *filter* by community, not to *group* amounts by one — or split the amount deliberately and say so.

## Gotchas

- **A customer with a null `due_date` on a document lands in no bucket.** The design says surface it rather than default it, so expect a bucket for it or a documented exclusion — not silence.
- **GP's bucket is only checkable on open documents.** For historical `as_of_date` values, the check comes from [snap_ar_aging_daily](snap_ar_aging_daily.md)`.gp_aging_bucket`, and before the snapshot's first day there is nothing to check against at all.
- **Credit memos and unapplied payments** carry negative outstanding amounts. A bucket total can legitimately be negative.
- **Reconstructed rows inherit T-08.** If the apply key collides, applies are lost, and the reconstruction **overstates** the receivable — in the direction nobody questions.
