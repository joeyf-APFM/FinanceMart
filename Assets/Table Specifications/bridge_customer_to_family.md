---
tags:
  - finance
  - semantic-layer
  - table-spec
  - pii
created: 2026-09-09
updated: 2026-09-09
---

# finance.identity.bridge_customer_to_family

> [!warning] Not built, and mostly unprofiled
> DDL: [05-finance-identity.sql](../ddl/05-finance-identity.sql) · `STATUS: NOT EXECUTED`. Its source, `main.prod_fin_ipr_ipr.ipr`, is **not in the GP metadata reference**. Only the columns named in the spine validation are confirmed; the rest are marked **PROFILE** — placeholders to be replaced by a `DESCRIBE`, not assertions. Blocked on **T-10** and **T-11**.

| | |
|---|---|
| **Type** | Bridge, **many-to-many** |
| **Grain** | Customer × `family_file_id` |
| **Source** | `main.prod_fin_ipr_ipr.ipr` — **one table, not a chain** |
| **Clustering** | `CLUSTER BY (gp_customer_number)` |
| **Readers** | `finance-pii-readers` |

## Why it is one table and not a chain

`ipr` carries the GP key and the funnel key **on the same row for 99.28% of live rows.** No intermediate hop is needed.

**Do not route it through YGL.** `prod_ygl_apfm` has 481 tables, 94 lead-keyed, **exactly one** family-keyed, and the GP mapping's grain is `business_unit_id` — a community, not a family. Routing through YGL trades a 99.28% direct join for a longer path to a coarser grain. The tag `do_not_route_through = 'ygl'` records this on the object.

## Coverage is a property of the model, not a caveat

Documented up front rather than discovered in month three:

| Era | Resolution |
|---|---|
| FY2023–2026 | **100.00%** |
| Before mid-2022 | **roughly 1.8%** |
| All-time | 51.85% |

**Quote the bound or not at all.** The bare all-time figure of 51.85% undersells it; an unqualified "100%" promises history that does not exist. `coverage_era` is carried as a column so any consumer aggregating across eras **sees the discontinuity instead of averaging through it**.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `customer_key` | BIGINT | Yes | Derived | FK to [dim_customer](dim_customer.md). **NULL is meaningful and must not be filtered away** — it means the charge has not been invoiced yet, which is the unbilled-move-in population |
| `gp_customer_number` | STRING | Yes | `ipr.fin_customer_id` | The GP spine key. 97.92% row coverage, 97.24% distinct coverage |
| `lead_id` | STRING | Yes | `ipr.lead_id` | **PROFILE** — confirm the landed type. Declared STRING to avoid asserting an integer that may be a code |
| `family_file_id` | STRING | Yes | Reached from `lead_id` | The funnel family key. Resolves at 100.00% for FY2023–2026. **PROFILE** |
| `move_in_date` | DATE | Yes | `ipr.move_in` | **Populated with a null `customer_key` is the definition of an unbilled move-in** |
| `first_charge_date` | DATE | Yes | **PROFILE** | Earliest `ipr` charge date for the pair, used to place the relationship in time |
| `coverage_era` | STRING | No | Derived | `fy2023_plus`, `pre_mid_2022`, or `transitional` |
| `is_spine_resolved` | BOOLEAN | No | Derived | False where `fin_customer_id` is blank. Distinguishes **"not yet invoiced" from "failed to match"** — different problems with different owners |
| `source_system` | STRING | No | Literal | `IPR` |
| `source_table` | STRING | No | Literal | `main.prod_fin_ipr_ipr.ipr` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraint:** `fk_bridge_family_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer`.

**No primary key is declared.** A customer legitimately maps to many families and a family to more than one customer, so this is a many-to-many bridge and asserting uniqueness would be false.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `cardinality` | `many_to_many` | Read before joining |
| `coverage_floor` | `fy2023` | Below this, resolution is ~1.8% |
| `do_not_route_through` | `ygl` | |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_customer](dim_customer.md) | `b.customer_key = dc.customer_key` | N:1 | Declared FK |
| Funnel family dimension | `b.family_file_id = …` | N:1 | Outside this catalog. **PROFILE** the key first |
| Any AR fact | via `customer_key` | **N:M** | See the fan-out warning |

### The `INNER JOIN` that drops most of the current month

**`fin_customer_id` is assigned at invoicing**, so blank is a lifecycle stage rather than a defect:

| Rows created in | Blank `fin_customer_id` |
|---|---|
| January | 0.02% |
| September | **77.74%** |

An inner join from `ipr` to GP therefore silently drops most of the current month, and the loss grows through the month — a report that looked right in February looks broken in September for reasons nothing in the data explains.

```sql
-- WRONG: drops 77.74% of September-created rows
JOIN finance.identity.dim_customer dc ON dc.customer_key = b.customer_key

-- RIGHT
LEFT JOIN finance.identity.dim_customer dc ON dc.customer_key = b.customer_key
```

The corollary is a **free use case**: unbilled move-ins are exactly the rows where the spine is null and `move_in_date` is populated.

```sql
SELECT * FROM finance.identity.bridge_customer_to_family
WHERE  customer_key IS NULL AND move_in_date IS NOT NULL
```

Use `is_spine_resolved = false` rather than `customer_key IS NULL` where the distinction between *not yet invoiced* and *failed to match* matters.

### Fan-out: never join a fact through this bridge and sum

One customer, three families. Joining an AR balance through the bridge triples the balance:

```sql
-- WRONG: sum(amount) is now 3x for a customer with 3 families
SELECT b.family_file_id, sum(f.original_amount)
FROM   finance.receivables.fact_ar_transaction f
JOIN   finance.identity.bridge_customer_to_family b USING (customer_key)
GROUP BY 1
```

That query is not fixable by a `DISTINCT` — the amount genuinely belongs to the customer, not to a family, and splitting it needs an allocation rule Finance has to supply. Two defensible patterns:

```sql
-- (a) Count/list families per customer without touching amounts
SELECT f.customer_key, sum(f.original_amount) AS amount,
       count(DISTINCT b.family_file_id)       AS family_count
FROM   finance.receivables.fact_ar_transaction f
LEFT JOIN finance.identity.bridge_customer_to_family b USING (customer_key)
GROUP BY 1

-- (b) Filter by family, do not group by it
WHERE f.customer_key IN (
  SELECT customer_key FROM finance.identity.bridge_customer_to_family
  WHERE family_file_id = :fid)
```

### Always carry the era into the output

Any aggregate spanning mid-2022 mixes a 100% resolved population with a 1.8% resolved one. Group by `coverage_era`, or filter to `fy2023_plus` and say so in the title.

## Gotchas

- **Every column except `fin_customer_id`, `lead_id` and `move_in` is a placeholder.** Run T-10 (grain of `ipr`) and T-11 (the `charge_type` domain) before treating this spec as a contract.
- **The grain of `ipr` itself is unconfirmed.** If `ipr` is charge-grained rather than relationship-grained, this bridge needs a `DISTINCT` at load and `first_charge_date` becomes a `min()`.
- **51.85% is the number not to quote.**
