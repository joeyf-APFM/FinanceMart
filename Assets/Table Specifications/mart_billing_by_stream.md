---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.billing.mart_billing_by_stream

> [!CAUTION]
> **Do not reconcile this to the income statement**
>
> `do_not_reconcile_to = 'income_statement'` is on the object. **This is billing activity, not revenue.** Reconciling it to the income statement will not tie *"because the two measure different things at different times, not because either is wrong."* Recognised revenue is in [fact_gl_posting](fact_gl_posting.md).

> [!WARNING]
> **Not built · blocked on T-11**
>
> DDL: [08-finance-billing.sql](../ddl/08-finance-billing.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).
>
> **`billing_stream`'s domain must be enumerated from `ipr` before this mart is built** (T-11). *"An unenumerated stream column becomes an ever-growing pivot no one can validate."*

| | |
|---|---|
| **Type** | Mart (aggregate) |
| **Grain** | Fiscal period × legal entity × billing stream × business unit |
| **Sources** | [fact_referral_charge](fact_referral_charge.md) and [fact_invoice_line](fact_invoice_line.md) |
| **Measure class** | `operational_not_recognized` — **carried as a data column too** |
| **Clustering** | `CLUSTER BY (fiscal_year, legal_entity_code)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-11** (stream domain), inherits **T-10** |

## The whole value of this mart

*"It aggregates over a bridge with a measured ceiling, so the ceiling is in the grain rather than in a note beside it."* Two columns do that work — `unbilled_charge_amount` and `ipr_matched_rate` — and both are first-class measures rather than metadata.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `fiscal_period_key` | BIGINT | No | Derived | **PK.** FK to [dim_fiscal_calendar](dim_fiscal_calendar.md) **at `period_level = 'period'`** |
| `fiscal_year` | INT | No | Denormalised | For query convenience |
| `period_number` | INT | No | Denormalised | For query convenience |
| `legal_entity_code` | STRING | No | Derived | **PK.** APFM or CAPFM. **A CAPFM row carries charge measures and null invoice measures, and that is correct rather than missing data** |
| `billing_stream` | STRING | No | `charge_type` | **PK.** Domain must be enumerated before build — **T-11** |
| `business_unit_id` | STRING | Yes | Resolved | **PK.** The community, where resolvable. PROFILE |
| `charge_amount` | DECIMAL(19,5) | Yes | `sum(fact_referral_charge.charge_amount)` | **What the charging platform says was charged** |
| `charge_count` | BIGINT | Yes | `count(*)` | |
| `invoiced_amount` | DECIMAL(19,5) | Yes | `sum(fact_invoice_line.extended_price)` | For lines matched to those charges. **NULL rather than zero where the invoice side is not available for the entity** — the APFM-only note |
| `invoiced_line_count` | BIGINT | Yes | Derived | Matched invoice lines |
| `unbilled_charge_amount` | DECIMAL(19,5) | Yes | Derived | Charges with no customer resolved — not yet invoiced. **A first-class measure, not a residual: the unbilled-move-in exposure, and what the 77.74% September blank rate means in dollars** |
| `ipr_matched_rate` | DECIMAL(9,6) | Yes | Derived | Proportion of the period's charges matched to a GP invoice line. **Carried per period because the estate-wide 98.7% and 60.6% figures are averages, and a period whose rate has collapsed should be visible before someone builds a forecast on it** |
| `measure_class` | STRING | No | Literal | Always `operational_not_recognized`. **Stated as data so a consumer reading only this table still learns it is not revenue** |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_mart_billing_by_stream PRIMARY KEY (fiscal_period_key, legal_entity_code, billing_stream, business_unit_id)`; `fk_billing_stream_period` → `common.calendar.dim_fiscal_calendar`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `measure_class` | `operational_not_recognized` | Also a column — the tag is for discovery, the column for whoever only reads the data |
| `grain` | `period_x_entity_x_stream_x_business_unit` | |
| `do_not_reconcile_to` | `income_statement` | **The instruction is on the object** |

## `business_unit_id` is in the primary key and nullable

That combination is worth stating explicitly: UC primary keys are **informational and non-enforced**, so a null `business_unit_id` does not fail anything. It means the community was not resolvable for that period and stream.

**Consequence for every consumer:** rows with a null `business_unit_id` are real activity that belongs in the entity total. Filtering them out makes the community breakdown internally consistent and smaller than the truth.

```sql
-- RIGHT: unresolved is its own bucket
SELECT coalesce(business_unit_id, '(unresolved)') AS community, sum(charge_amount)
FROM   finance.billing.mart_billing_by_stream
WHERE  fiscal_year = :y
GROUP BY 1

-- WRONG: the community totals no longer sum to the entity total
WHERE business_unit_id IS NOT NULL
```

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_fiscal_calendar](dim_fiscal_calendar.md) | `m.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Declared FK. **Filter `period_level = 'period'`** |
| [dim_legal_entity](dim_legal_entity.md) | `m.legal_entity_code = le.legal_entity_code` | N:1 | No surrogate carried |
| [fact_referral_charge](fact_referral_charge.md) | Drill-down | — | This mart's charge source |
| [fact_invoice_line](fact_invoice_line.md) | Drill-down | — | This mart's invoice source |
| [mart_period_summary](mart_period_summary.md) | **Do not join** | — | Different measure classes. See below |
| [mart_plan_vs_actual](mart_plan_vs_actual.md) | **Do not join** | — | Plan is compared to *recognised* actuals, not to billing |
| [dim_customer](dim_customer.md) | Not reachable | — | This mart is community grain, not customer grain |

### Never join or union this to a GL product

```sql
-- WRONG in a way that produces a plausible number
SELECT m.billing_stream, m.charge_amount, p.net_activity_amount
FROM   finance.billing.mart_billing_by_stream m
JOIN   finance.general_ledger.mart_period_summary p USING (fiscal_period_key, legal_entity_code)
```

This joins `operational_not_recognized` to `recognized` at period grain and invites the reader to treat the difference as a variance. It is not one — the two measure different events at different times. If a comparison is genuinely wanted, present the two figures **side by side with their measure classes labelled**, and state that the difference is timing and scope rather than error.

That is exactly what `measure_class` being a **column** rather than only a tag is for: it travels into the result set.

### `invoiced_amount IS NULL` means "not available", not zero

```sql
-- RIGHT
CASE WHEN invoiced_amount IS NULL THEN 'invoice side not replicated for this entity'
     ELSE format_number(invoiced_amount, 2) END

-- WRONG: reports CAPFM as having invoiced nothing
coalesce(invoiced_amount, 0)
```

[fact_invoice_line](fact_invoice_line.md) is **APFM only** — `sop30300` is not replicated for CAPFM. Coalescing the null to zero turns a known gap into a confident claim that CAPFM billed nothing, which is the specific failure the DDL comment warns about.

### `ipr_matched_rate` is the health check, not a footnote

```sql
SELECT fiscal_year, period_number, legal_entity_code, billing_stream,
       ipr_matched_rate, charge_amount, unbilled_charge_amount
FROM   finance.billing.mart_billing_by_stream
WHERE  ipr_matched_rate < 0.5        -- tune against the 0.606 estate-wide figure
ORDER BY fiscal_year DESC, period_number DESC
```

A period whose rate has fallen below its historical norm means the bridge degraded, and every amount for that period is understated by an unknown margin. **Check this before quoting any figure from a recent period.**

### Sum `charge_amount` and `unbilled_charge_amount`, or neither

They are **disjoint populations**: `charge_amount` is all charges over the grain, `unbilled_charge_amount` is the subset with no customer resolved. Confirm against the load logic which of the two definitions the build uses — if `unbilled_charge_amount` is a **subset** of `charge_amount`, adding them double counts; if it is disjoint, adding them is the total. The DDL comment ("Sum of charges with no customer resolved") reads as a subset, so treat it as one until the load code says otherwise.

## Gotchas

- **The grain has no customer.** Customer-level billing questions go to [fact_referral_charge](fact_referral_charge.md).
- **`billing_stream` is unenumerated today.** Any dashboard pivot built on it will grow silently as new charge types appear in `ipr`.
- **T-10 propagates.** If [fact_referral_charge](fact_referral_charge.md)'s grain is wrong, every measure here is wrong by the same factor, and nothing in this mart can detect it.
- **`period_number` and `fiscal_year` are denormalised copies.** Convenient, and they can drift from `fiscal_period_key` if the calendar is rebuilt — reconcile them, do not assume.
- **No `source_system` column**, unlike most tables here. Provenance is `_loaded_at` plus the two named source facts.
