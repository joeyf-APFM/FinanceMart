---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.reference.dim_currency

> [!warning] Not built
> DDL: [04-finance-reference.sql](../ddl/04-finance-reference.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Conformed dimension |
| **Grain** | One currency |
| **Source** | `main.prod_gp_dynamics_dbo_live.mc40200` — the **system** database, which defines currency once rather than per company |
| **History** | Type 1 |
| **Readers** | `finance-analysts` |
| **Tests** | **T-04** (the `DECPLCUR` decode) |

## Why it exists here, and why it will not stay here

Built in `finance.reference` by decision, but the shared design says Commercial & Partner needs the identical product today. It is therefore built to the **shared-design contract now**, so the eventual move to `common` is a rename and a grant rather than a remodel. The tag `expected_to_move_to = 'common'` records that intent on the object itself.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `currency_key` | BIGINT | No | Derived | PK. `xxhash64(iso_currency_code)`. Reserved members −1/−2/−3 |
| `iso_currency_code` | STRING | Yes | `MC40200.ISOCURRC` | **The conformed key.** What other domains join on — not GP's internal id. Null on reserved members |
| `gp_currency_id` | STRING | Yes | `MC40200.CURNCYID` | GP's own identifier. Retained because a surrogate never replaces the source key |
| `gp_currency_index` | INT | Yes | `MC40200.CURRNIDX` | **The integer GP actually stores on transactions.** Needed to join facts back to currency |
| `currency_name` | STRING | Yes | `MC40200.CRNCYDSC` | |
| `currency_symbol` | STRING | Yes | `MC40200.CRNCYSYM` | |
| `decimal_places` | INT | Yes | Decoded from `MC40200.DECPLCUR` | GP stores a **one-based offset**, so 3 means 2 decimal places. Confirm against the replica — a wrong decode silently misstates every rounded amount |
| `language_id` | INT | Yes | `MC40200.CURLNGID` | |
| `is_reserved_member` | BOOLEAN | No | Derived | True for the −1/−2/−3 rows. **Filter on this, not on a negative key** |
| `source_system` | STRING | No | Literal | `GP`, or `SEED` for reserved members |
| `source_table` | STRING | Yes | Literal | |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraint:** `pk_dim_currency PRIMARY KEY (currency_key)`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `conformed` | `true` | Do not fork a copy |
| `grain` | `currency` | |
| `expected_to_move_to` | `common` | Commercial & Partner needs the same product; the move is planned, not hypothetical |

## Three keys, and which one to join on

This is the table's one real trap. It carries **three** identifiers for the same currency:

| Identifier | Use it for |
|---|---|
| `currency_key` | **All joins from facts in this catalog.** Every fact declares `currency_key BIGINT` and an FK to this table |
| `gp_currency_index` | Joining to a raw GP table that stores `CURRNIDX` — including `sop30300`, which carries the index and not the code |
| `iso_currency_code` | Joining **across domains**, to anything outside `finance` |
| `gp_currency_id` | Tracing a row back to GP. Not a join key of choice |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [fact_exchange_rate](fact_exchange_rate.md) | `f.currency_key = c.currency_key` | 1:N | |
| [dim_legal_entity](dim_legal_entity.md) | `le.functional_currency_key = c.currency_key` | 1:N | The entity's **functional** currency — the denominator for every unconverted amount in that entity's facts |
| [dim_customer](dim_customer.md) | `dc.currency_key = c.currency_key` | 1:N | From `RM00101.CURNCYID` |
| [fact_gl_posting](fact_gl_posting.md), [fact_gl_posting_work](fact_gl_posting_work.md) | `f.currency_key = c.currency_key` | 1:N | |
| [fact_ar_transaction](fact_ar_transaction.md), [fact_ar_apply](fact_ar_apply.md) | `f.currency_key = c.currency_key` | 1:N | |
| [fact_invoice_line](fact_invoice_line.md) | `f.currency_key = c.currency_key` | 1:N | Source carries `CURRNIDX`; resolve through `gp_currency_index` at load |
| [mart_account_period_activity](mart_account_period_activity.md), [mart_ar_aging](mart_ar_aging.md) | `m.currency_key = c.currency_key` | 1:N | `currency_key` is **in the primary key** of both marts |

### Reserved members change how you filter

Because the reserved rows exist, `currency_key` is never null on a fact — an unresolvable currency lands on −1 rather than NULL. That means:

```sql
-- Real currencies only
WHERE NOT c.is_reserved_member

-- WRONG: assumes null means unknown; nothing will be null
WHERE c.currency_key IS NOT NULL

-- WRONG: encodes the sentinel values in the query
WHERE c.currency_key > 0
```

The `is_reserved_member` flag exists precisely so consumers never hardcode −1, −2, −3.

## Gotchas

- **`decimal_places` is an offset, not a count.** T-04 confirms the decode. Until it does, do not round with it.
- **Currency is defined in the `dynamics` system database, not per company.** Reading `mc40200` out of `prod_gp_apfm_dbo` risks a per-company copy that may drift.
- **Money is `DECIMAL(19,5)` everywhere in this catalog, rates are `DECIMAL(19,7)`.** Never `DOUBLE`.
