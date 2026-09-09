---
tags:
  - finance
  - semantic-layer
  - table-spec
  - pii
created: 2026-09-09
updated: 2026-09-09
---

# finance.identity.bridge_customer_to_business_unit

> [!warning] Not built, and partly unprofiled
> DDL: [05-finance-identity.sql](../ddl/05-finance-identity.sql) · `STATUS: NOT EXECUTED`. `main.prod_ygl_apfm.great_plains_customer_mapping` is **not in the GP metadata reference**; columns marked **PROFILE** are placeholders. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Bridge, **many-to-many, effective-dated** |
| **Grain** | Customer × business unit × validity window |
| **Source** | `main.prod_ygl_apfm.great_plains_customer_mapping` |
| **Clustering** | `CLUSTER BY (gp_customer_number, business_unit_id)` |
| **Readers** | `finance-pii-readers` |

## Why this table settles the grain argument

The YGL mapping resolves a GP customer at `business_unit_id` grain — **a community.** This is the table that proves [dim_customer](dim_customer.md) is a billing account rather than a partner: **one GP customer can bill for several communities, and a community can change which customer bills it.** Both halves of that sentence are why the bridge is many-to-many *and* effective-dated.

It is also the only path from a finance figure to a community, which makes it the dependency behind `business_unit_id` on [mart_writeoff](mart_writeoff.md) and [mart_billing_by_stream](mart_billing_by_stream.md), and behind the row-filter proposal for the CAM audience in [Collections in the Finance Catalog](../Collections%20in%20the%20Finance%20Catalog.md).

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `customer_key` | BIGINT | Yes | Derived | FK to [dim_customer](dim_customer.md) |
| `gp_customer_number` | STRING | Yes | mapping, trimmed | |
| `business_unit_id` | STRING | Yes | mapping | A community. **PROFILE** — confirm the landed type and whether it is unique across YGL tenants |
| `valid_from` | DATE | Yes | `begin_date` | **The mapping is effective-dated, which is why this bridge is not a simple lookup** |
| `valid_to` | DATE | Yes | `end_date` | Null means currently effective. **PROFILE** — confirm whether the source uses null or a high-date sentinel |
| `is_current` | BOOLEAN | No | Derived | True where the row is effective as of the load date |
| `source_system` | STRING | No | Literal | `YGL` |
| `source_table` | STRING | No | Literal | `main.prod_ygl_apfm.great_plains_customer_mapping` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraint:** `fk_bridge_bu_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer`.

**No primary key.** Many-to-many.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `cardinality` | `many_to_many` | |
| `effective_dated` | `true` | The join is a predicate, not an equality |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_customer](dim_customer.md) | `b.customer_key = dc.customer_key` | N:1 | Declared FK |
| Community / business-unit dimension | `b.business_unit_id = …` | N:1 | Outside this catalog |
| [mart_writeoff](mart_writeoff.md) | `business_unit_id` already resolved on the mart | — | **Do not re-derive it.** The mart resolves it as of `writeoff_date`; re-joining as-of today gives a different answer |
| Any AR or billing fact | as-of predicate on the fact's own date | **N:M** | See below |

### This is an as-of join

**Any point-in-time question must filter on `valid_from` / `valid_to` rather than taking the current row.**

```sql
-- RIGHT: which community did this customer belong to when the charge happened
LEFT JOIN finance.identity.bridge_customer_to_business_unit b
  ON  b.customer_key = f.customer_key
  AND b.valid_from  <= f.charge_date
  AND (b.valid_to IS NULL OR b.valid_to > f.charge_date)

-- WRONG: attributes history to today's community
LEFT JOIN ... ON b.customer_key = f.customer_key AND b.is_current
```

The wrong version does not error and does not return fewer rows. It re-attributes every historical amount to the current mapping — so a community that changed billing customers last quarter absorbs the other community's history, and both totals are wrong while the grand total still ties. This is the single most expensive mistake available in this catalog.

`is_current` is a convenience for *"who bills this community now"* and nothing else.

### Fan-out survives the as-of predicate

The as-of predicate reduces overlap but does not eliminate it: a customer that bills **several communities simultaneously** matches multiple rows for the same date. Summing an amount through this bridge still double counts.

```sql
-- WRONG when a customer bills more than one community at once
SELECT b.business_unit_id, sum(f.original_amount) ...

-- RIGHT: either allocate with a rule Finance supplies, or report the fan-out
SELECT f.customer_key, sum(f.original_amount) AS amount,
       count(DISTINCT b.business_unit_id)     AS community_count
```

A `community_count > 1` population is worth surfacing on its own — those are the customers for whom any per-community finance number requires an allocation decision.

### Check for overlapping windows at load

Nothing in the source guarantees non-overlapping validity per customer. If `begin_date`/`end_date` overlap, the as-of predicate returns more than one row for a single date and the "correct" query above quietly fans out too:

```sql
-- Profile before trusting the as-of join
SELECT gp_customer_number, count(*) AS overlapping
FROM   finance.identity.bridge_customer_to_business_unit a
WHERE  EXISTS (SELECT 1 FROM finance.identity.bridge_customer_to_business_unit c
               WHERE c.gp_customer_number = a.gp_customer_number
                 AND c.business_unit_id  <> a.business_unit_id
                 AND c.valid_from < coalesce(a.valid_to, DATE'9999-12-31')
                 AND coalesce(c.valid_to, DATE'9999-12-31') > a.valid_from)
GROUP BY 1 ORDER BY 2 DESC
```

## Gotchas

- **`valid_to` may be a high-date sentinel, not null.** The DDL declares null-means-current; if the source uses `9999-12-31` or GP's `1900-01-01`, the `IS NULL` half of every as-of predicate matches nothing and every historical join returns empty.
- **Only APFM.** The source is `prod_ygl_apfm`. There is no CAPFM equivalent named anywhere, so CAPFM customers resolve to no community.
- **`business_unit_id` uniqueness across YGL tenants is unconfirmed.** If it is tenant-scoped, this bridge needs a tenant column and every community-level total is currently ambiguous.
