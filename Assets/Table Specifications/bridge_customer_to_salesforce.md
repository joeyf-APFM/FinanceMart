---
tags:
  - finance
  - semantic-layer
  - table-spec
  - pii
created: 2026-09-09
updated: 2026-09-09
---

# finance.identity.bridge_customer_to_salesforce

> [!CAUTION]
> **A bridge only — never the identity spine**
>
> `mir.customer_billing_id` matches a GP customer on **22.19% of rows.** Using it as the spine means silently losing roughly four rows in five. The tag `never_use_as_spine = 'true'` is on the object for this reason.

> [!WARNING]
> **Not built, and mostly unprofiled**
>
> DDL: [05-finance-identity.sql](../ddl/05-finance-identity.sql) · `STATUS: NOT EXECUTED`. `main.prod_fin_01_cst.mir` is **not in the GP metadata reference**; columns marked **PROFILE** are placeholders. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Bridge, **many-to-many** |
| **Grain** | Customer × Salesforce id |
| **Source** | `main.prod_fin_01_cst.mir` |
| **Measured match rate** | **0.2219** |
| **Clustering** | `CLUSTER BY (gp_customer_number)` |
| **Readers** | `finance-pii-readers` |

## Why a 22% match rate is still worth building

The epic's Salesforce-to-GP reconciliation use case is **served by exposing the mismatch, not by hiding it.** The unmatched rows are the deliverable, not the error. That is why `match_status` is a first-class column rather than a load-time filter — a 22.19% match rate means **the unmatched rows are the normal case** and must be visible rather than lost to an inner join.

Contrast with [bridge_customer_to_family](bridge_customer_to_family.md), which resolves at 99.28% on the same kind of join and is therefore usable as a traversal. This one is usable only as a reconciliation subject.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `customer_key` | BIGINT | Yes | Derived | FK to [dim_customer](dim_customer.md). **Null where the Salesforce record carries a billing id GP does not recognise, which is most of them** |
| `gp_customer_number` | STRING | Yes | `mir.customer_billing_id`, trimmed | Matches a GP customer on only 22.19% of rows |
| `salesforce_id` | STRING | Yes | `mir.salesforce_id` | **PROFILE** — confirm which Salesforce object this identifies before a consumer assumes `Account` |
| `match_status` | STRING | No | Derived | `matched`, `unmatched_in_gp`, or `ambiguous` |
| `source_system` | STRING | No | Literal | `CST` |
| `source_table` | STRING | No | Literal | `main.prod_fin_01_cst.mir` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraint:** `fk_bridge_sfdc_customer FOREIGN KEY (customer_key) REFERENCES finance.identity.dim_customer`.

**No primary key.** Many-to-many.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `cardinality` | `many_to_many` | |
| `measured_match_rate` | `0.2219` | Measured, not estimated. On the object so nobody has to find the note |
| `never_use_as_spine` | `true` | |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_customer](dim_customer.md) | `b.customer_key = dc.customer_key` | N:1 | Declared FK |
| Salesforce Account/Opportunity | `b.salesforce_id = …` | N:1 | Outside this catalog. **PROFILE which object first** |
| Any AR fact | via `customer_key` | **N:M** | Fan-out, and only 22% resolvable |

### The reconciliation query is the point

```sql
-- What the epic actually asks for: where Salesforce and GP disagree
SELECT match_status, count(*) AS rows, count(DISTINCT salesforce_id) AS sfdc_ids
FROM   finance.identity.bridge_customer_to_salesforce
GROUP BY 1
```

Expect `unmatched_in_gp` to dominate. That is the finding, not a load failure.

### Pushing an AR balance into Salesforce

This is the *"balance and past-due invisible in Salesforce"* pain point, and this bridge is the only path — with a ceiling that has to be stated alongside the number:

```sql
SELECT b.salesforce_id,
       sum(m.past_due_amount) AS past_due
FROM   finance.receivables.mart_ar_aging m
JOIN   finance.identity.bridge_customer_to_salesforce b
       ON  b.customer_key = m.customer_key
       AND b.match_status = 'matched'          -- pin it, or ambiguous rows fan out
WHERE  m.as_of_date         = :d
  AND  m.computation_basis  = 'snapshot'       -- flags-in-the-grain; see mart_ar_aging
GROUP BY 1
```

**Whatever this returns covers at most 22.19% of the Salesforce population.** A dashboard built on it must say so, or the first question will be why most accounts show no balance — and the answer will look like a data-quality incident rather than a known match ceiling.

### `ambiguous` must be pinned or excluded

An `ambiguous` row is one billing id resolving to more than one Salesforce id, or vice versa. Left in, it fans out; filtered out silently, it disappears from a reconciliation whose entire purpose is to surface it. Pin `match_status` explicitly in every query, including when the answer is `IN ('matched','ambiguous')`.

## Gotchas

- **Never join `mir` to GP to establish identity.** Use [bridge_customer_to_family](bridge_customer_to_family.md) or [dim_customer](dim_customer.md) directly for that.
- **`salesforce_id`'s object is unconfirmed.** If it is a Contact or a Lead rather than an Account, every downstream join changes.
- **22.19% is measured on today's data.** Re-measure rather than assuming the rate improves or degrades; the tag value should be updated when it does.
