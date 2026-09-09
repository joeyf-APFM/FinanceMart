---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.receivables.mart_writeoff

> [!tip] Servable today
> This directly serves the stated pain point — **write-offs and bad-debt recovery invisible to CAMs and Community Ops**. It **needs no ingestion that does not already exist.** It needs this table and a grant. `requires_no_new_ingestion = 'true'` is on the object.

> [!warning] Not built
> DDL: [07-finance-receivables.sql](../ddl/07-finance-receivables.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Mart (event log) |
| **Grain** | One write-off event = **one [fact_ar_apply](fact_ar_apply.md) row with a non-zero `WROFAMNT`** |
| **Source** | [fact_ar_apply](fact_ar_apply.md) |
| **Clustering** | `CLUSTER BY (legal_entity_code, writeoff_date)` |
| **Readers** | `finance-analysts` — **and the grant to CAM / Community Ops is the point** |

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `writeoff_key` | BIGINT | No | Derived | PK. **Inherited from the `fact_ar_apply` row that carries the write-off** — not a new hash |
| `ar_apply_key` | BIGINT | No | [fact_ar_apply](fact_ar_apply.md) | FK. One write-off event is one apply row |
| `legal_entity_code` | STRING | No | Derived | |
| `customer_key` | BIGINT | Yes | Derived | FK to [dim_customer](dim_customer.md) |
| `gp_customer_number` | STRING | No | `CUSTNMBR` | Trimmed |
| `document_number` | STRING | Yes | Apply-to doc | The document that was written off |
| `document_type_code` | INT | Yes | `RMDTYPAL` | Of the apply-to document |
| `writeoff_date` | DATE | Yes | `apply_date` | **The answer to "when was it written off" — which GP does record and nothing currently surfaces** |
| `gl_post_date` | DATE | Yes | `GLPOSTDT` | For reconciliation to [fact_gl_posting](fact_gl_posting.md) |
| `fiscal_period_key` | BIGINT | Yes | Derived | FK to [dim_fiscal_calendar](dim_fiscal_calendar.md) |
| `writeoff_amount` | DECIMAL(19,5) | Yes | `WROFAMNT` | |
| `originating_writeoff_amount` | DECIMAL(19,5) | Yes | `ORWROFAM` | Originating currency |
| `actual_writeoff_amount` | DECIMAL(19,5) | Yes | `ActualWriteOffAmount` | **Can differ from `WROFAMNT` when a rate moves between the two documents** |
| `currency_key` | BIGINT | Yes | Derived | FK to [dim_currency](dim_currency.md) |
| `business_unit_id` | STRING | Yes | Resolved | **Through [bridge_customer_to_business_unit](bridge_customer_to_business_unit.md) *as of `writeoff_date`*, not from the current mapping.** Present because the pain point is CAM and Community Ops visibility, and both work at **community grain rather than billing-account grain** |
| `source_system` | STRING | No | Literal | `GP` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_mart_writeoff PRIMARY KEY (writeoff_key)`; `fk_writeoff_apply` → `fact_ar_apply`; `fk_writeoff_customer` → `dim_customer`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `writeoff_event` | |
| `serves_stated_pain_point` | `writeoff_visibility` | Traceable back to the requirement |
| `requires_no_new_ingestion` | `true` | The write-off data is already replicated |

## `business_unit_id` is pre-resolved, and that is the whole design

The bridge is many-to-many **and** effective-dated. Resolving it once, in the pipeline, at `writeoff_date`, gives every consumer:

- **No fan-out.** One row per write-off event, so `sum(writeoff_amount)` by community is safe here in a way it is not on [mart_ar_aging](mart_ar_aging.md).
- **No as-of mistake.** A write-off from 2024 is attributed to the community the customer belonged to **in 2024**, not the current one.

That second point is the expensive one. Resolving the bridge at query time with `current_date` re-attributes every historical write-off to today's mapping — which does not error, does not change the row count, and quietly moves dollars between communities.

**Consequence: do not re-join the bridge to this table.** The column is already the answer.

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [fact_ar_apply](fact_ar_apply.md) | `w.ar_apply_key = a.ar_apply_key` | 1:1 | Declared FK. The full apply context |
| [fact_ar_transaction](fact_ar_transaction.md) | `(legal_entity_code, gp_customer_number, document_number, document_type_code)` | N:1 | **No FK** — natural-key join, all four parts |
| [dim_customer](dim_customer.md) | `w.customer_key = dc.customer_key` | N:1 | Declared FK |
| [dim_currency](dim_currency.md) | `w.currency_key = c.currency_key` | N:1 | |
| [dim_fiscal_calendar](dim_fiscal_calendar.md) | `w.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Filter `period_level = 'period'` |
| [dim_date](dim_date.md) | `d.full_date = w.writeoff_date` | N:1 | No `date_key` column |
| [dim_collections_attributes](dim_collections_attributes.md) | `w.customer_key = ca.customer_key` | N:1 | **`LEFT JOIN`.** Who owned the collections relationship |
| [mart_ar_aging](mart_ar_aging.md) | `(legal_entity_code, gp_customer_number)` | N:M | Aging beside write-offs — pin that mart's `as_of_date` and `computation_basis` |
| [bridge_customer_to_business_unit](bridge_customer_to_business_unit.md) | — | — | **Do not join.** `business_unit_id` is already resolved as of the date |
| [fact_gl_posting](fact_gl_posting.md) | via `gl_post_date` + the document's `trx_source` | N:M | Reconciliation |

### Recoveries are negative write-offs

```sql
-- RIGHT: the requirement is "write-offs AND bad-debt recovery"
WHERE coalesce(writeoff_amount, 0) <> 0

-- Split them explicitly
SELECT business_unit_id,
       sum(CASE WHEN writeoff_amount > 0 THEN writeoff_amount END) AS written_off,
       sum(CASE WHEN writeoff_amount < 0 THEN writeoff_amount END) AS recovered,
       sum(writeoff_amount)                                        AS net
FROM   finance.receivables.mart_writeoff
GROUP BY 1

-- WRONG: silently answers half the question
WHERE writeoff_amount > 0
```

A `> 0` filter drops recoveries entirely and reports gross write-offs as net. The report looks complete and overstates bad debt.

### The community view — the query the pain point is asking for

```sql
SELECT w.business_unit_id,
       date_trunc('month', w.writeoff_date) AS month,
       count(*)                             AS events,
       sum(w.writeoff_amount)               AS net_writeoff
FROM   finance.receivables.mart_writeoff w
WHERE  w.writeoff_date >= :from
GROUP BY 1, 2
ORDER BY 3 DESC
```

No bridge, no fan-out, no as-of predicate — because the pipeline did that work. This is the query a CAM should be able to run without knowing any of the above.

### Pick one write-off amount per query

`writeoff_amount` (`WROFAMNT`) to reconcile to the document; `actual_writeoff_amount` for the amount actually moved after a rate change; `originating_writeoff_amount` for the transaction currency. **They are three measurements of one event — never sum two together.**

## Gotchas

- **A null `business_unit_id`** means the bridge had no row covering `writeoff_date` — an unmapped or newly-mapped customer. **Surface it as its own group rather than dropping it**, or the community totals will not add up to the entity total.
- **`writeoff_key` is inherited from `ar_apply_key`.** If T-08 leaves apply-key collisions, write-off events are lost here too.
- **One document can be written off more than once**, in partial amounts. `count(*)` counts events, not documents.
- **`gl_post_date` is the reconciliation date, `writeoff_date` is the business date.** They can fall in different periods, and a period-close question needs the former.
