---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.billing.fact_referral_charge

> [!danger] The grain is UNCONFIRMED
> The vault establishes that `ipr` carries `fin_customer_id`, `lead_id` and `move_in` on one row, and that 99.28% of live rows carry both keys. **It does not establish whether one row is one charge, one charge period, or one move-in.** Test **T-10** must profile the grain before this is built. **Do not guess the key: a wrong grain here double counts every downstream billing figure.**

> [!warning] Not built · most columns are PLACEHOLDERS
> DDL: [[../ddl/08-finance-billing.sql|08-finance-billing.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].
>
> `main.prod_fin_ipr_ipr.ipr` is **not in the Dynamics GP metadata reference.** Only the columns the spine validation touched are confirmed: `fin_customer_id`, `lead_id`, `move_in`, `gp_invoice_num`, `salesforce_id`, `customer_billing_id`, `business_unit_id`, `begin_date`, `end_date`, `family_file_id`. **Every column marked PROFILE below must be replaced from a `DESCRIBE` before a line of load code is written.**
>
> ```sql
> DESCRIBE TABLE EXTENDED main.prod_fin_ipr_ipr.ipr;
> DESCRIBE TABLE EXTENDED main.prod_fin_ipr_ipr.ipr_invoice;
> ```

> [!info] Nothing in this schema is named revenue
> Referral charges are **billing activity**. Recognised revenue is what posts to the general ledger and lives in [[fact_gl_posting]]. *"The moment a column here is called revenue, someone will reconcile it against the income statement and it will not tie — because these two measure different things at different times, not because either is wrong."*

| | |
|---|---|
| **Type** | Fact |
| **Grain** | **UNCONFIRMED** — T-10 |
| **Source** | `main.prod_fin_ipr_ipr.ipr` |
| **Measure class** | `operational_not_recognized` |
| **Clustering** | `CLUSTER BY (charge_date, gp_customer_number)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-10** (grain), **T-11** (`charge_type` domain) |

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `referral_charge_key` | BIGINT | No | Derived | PK, deterministic over the natural key — **which is UNCONFIRMED (T-10)** |
| `customer_key` | BIGINT | Yes | Derived on `fin_customer_id` | FK to [[dim_customer]]. **NULL IS MEANINGFUL AND MUST NOT BE FILTERED AWAY** — see below |
| `gp_customer_number` | STRING | Yes | `ipr.fin_customer_id` | Trimmed. **97.92% row coverage, 97.24% distinct coverage** against GP |
| `lead_id` | STRING | Yes | `ipr.lead_id` | **PROFILE the landed type** — declared STRING rather than asserting an integer |
| `family_file_id` | STRING | Yes | Via [[bridge_customer_to_family]] | **100.00% for FY2023-2026, roughly 1.8% before mid-2022.** PROFILE |
| `business_unit_id` | STRING | Yes | PROFILE | The community. **Confirm whether `ipr` carries it directly or it must come through [[bridge_customer_to_business_unit]] as of the charge date** |
| `move_in_date` | DATE | Yes | `ipr.move_in` | **A populated `move_in` with a null `customer_key` is the unbilled-move-in population — a use case rather than a data quality problem** |
| `charge_date` | DATE | Yes | **PROFILE** | The date the charge was raised. **Confirm which of the several date columns in `ipr` this is before choosing** |
| `charge_period_start` | DATE | Yes | **PROFILE** | |
| `charge_period_end` | DATE | Yes | **PROFILE** | |
| `date_key` | INT | Yes | Derived on `charge_date` | FK to [[dim_date]] |
| `charge_type` | STRING | Yes | **PROFILE** | The billing stream. **[[mart_billing_by_stream]] aggregates on it, so its domain must be enumerated *before* that mart is built rather than after** (T-11) |
| `charge_amount` | DECIMAL(19,5) | Yes | **PROFILE** | Confirm source type and scale. **DECIMAL, never DOUBLE: a float amount will not reconcile to GP and the difference will be blamed on the mapping** |
| `currency_key` | BIGINT | Yes | Derived | FK to [[dim_currency]]. **PROFILE whether `ipr` records a currency at all**; if not, default to the entity's functional currency **and say so here rather than assuming USD silently** |
| `gp_invoice_number` | STRING | Yes | Via `ipr_invoice.gp_invoice_num` | The GP invoice this charge was billed on. **Null until invoiced** |
| `invoice_line_key` | BIGINT | Yes | Derived | FK to [[fact_invoice_line]] where matched. Null where not — see that table's coverage figures |
| `is_invoiced` | BOOLEAN | No | Derived | Whether `fin_customer_id` is populated. **Distinguishes not-yet-invoiced from failed-to-match — different problems with different owners** |
| `source_system` | STRING | No | Literal | `IPR` |
| `source_table` | STRING | No | Literal | `main.prod_fin_ipr_ipr.ipr` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_referral_charge PRIMARY KEY (referral_charge_key)`; `fk_referral_charge_customer` → `finance.identity.dim_customer`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `measure_class` | `operational_not_recognized` | |
| `grain` | `unconfirmed_profile_first` | **The uncertainty is on the object, not just in a doc** |
| `schema_source` | `not_in_gp_reference` | The source table's columns are not documented anywhere authoritative |
| `null_key_is_meaningful` | `customer_key` | Names the specific null that must not be filtered |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_customer]] | `f.customer_key = dc.customer_key` | N:1 | Declared FK. **`LEFT JOIN` — see below** |
| [[fact_invoice_line]] | `f.invoice_line_key = il.invoice_line_key` | N:1 | `LEFT JOIN`. Only matched charges |
| [[dim_date]] | `f.date_key = d.date_key` | N:1 | On `charge_date`, once T-10 confirms which column that is |
| [[dim_currency]] | `f.currency_key = c.currency_key` | N:1 | May be entirely derived rather than sourced |
| [[bridge_customer_to_family]] | `f.customer_key = b.customer_key` | **1:N** | `family_file_id` may already be resolved — **do not resolve twice** |
| [[bridge_customer_to_business_unit]] | as-of `charge_date` | **1:N** | Fan-out **and** as-of. Only if `ipr` does not carry it directly |
| [[mart_billing_by_stream]] | This fact is its source | — | Aggregate |
| [[fact_gl_posting]] | — | — | **No join, and no reconciliation.** Different measure classes |

### The `INNER JOIN` that drops most of the current month

`fin_customer_id` is assigned **at invoicing**, so a null `customer_key` means *not yet invoiced* — and that population is heavily concentrated in the current month:

| Rows created in | Blank `fin_customer_id` |
|---|---|
| January | **0.02%** |
| September | **77.74%** |

```sql
-- RIGHT
LEFT JOIN finance.identity.dim_customer dc ON dc.customer_key = f.customer_key

-- WRONG: silently drops 77.74% of September-created charges
JOIN finance.identity.dim_customer dc ON dc.customer_key = f.customer_key
```

The wrong version returns a coherent charge report that is **missing three quarters of the current month**. The shortfall looks like a slow month, not a broken join — which is why the null is tagged on the object as meaningful.

### The unbilled-move-in population comes free

```sql
SELECT business_unit_id, count(*) AS unbilled_move_ins, sum(charge_amount) AS exposure
FROM   finance.billing.fact_referral_charge
WHERE  customer_key IS NULL
  AND  move_in_date IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC
```

A populated `move_in_date` with no `customer_key` is a resident who moved in and has not been billed. **This is a use case, not a defect**, and it is available the moment the fact exists. `unbilled_charge_amount` on [[mart_billing_by_stream]] is this figure materialised.

### `is_invoiced` versus a null `invoice_line_key`

Two different failures, and the pair distinguishes them:

| `is_invoiced` | `invoice_line_key` | Meaning | Owner |
|---|---|---|---|
| `false` | null | **Not yet invoiced** | Billing operations |
| `true` | null | **Invoiced but did not match a GP line** | Data / integration |
| `true` | populated | Matched | — |

Collapsing these into "no invoice line" sends every case to the wrong team.

## Gotchas

- **Almost every column here is a placeholder.** Treat this note as the *intended* shape. The DDL says PROFILE on each one, and so does this table.
- **Do not build [[mart_billing_by_stream]] before T-11.** *"An unenumerated stream column becomes an ever-growing pivot no one can validate."*
- **`family_file_id` coverage is bounded by era, not by rate.** 100% recent, ~1.8% pre-mid-2022. Quote the bound or not at all.
- **`charge_amount` must be DECIMAL end to end.** A DOUBLE anywhere in the pipeline reintroduces the reconciliation problem the type choice exists to prevent.
- **`business_unit_id` may need the as-of bridge.** If it does, the resolution belongs in the pipeline as it does on [[mart_writeoff]], not in every consumer's query.
