---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# common.calendar.dim_date

> [!warning] Not built — and this one is a **promotion**, not a new build
> DDL: [03-common-calendar.sql](../ddl/03-common-calendar.sql), where every statement for this table is commented out. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Conformed dimension |
| **Grain** | One calendar date |
| **Source** | `main.prod_refined.dim_date`, promoted as-is |
| **History** | n/a — a calendar date is immutable |
| **Owner** | Data Platform. Finance builds it and does not own it |
| **Readers** | `` `account users` `` |
| **Tests** | **T-01**, which every fact in the catalog depends on |

## Why it exists, and why its columns are not listed here

There are already **at least three** date dimensions in the estate: `main.prod_refined.dim_date` feeds `main.prod.dim_date` (nine downstream consumers), and `main.prod_edw_dbo.dim_date` exists as well. Building a fourth inside `finance` is the exact failure this schema prevents — which is also why `dim_date` sits in `common` rather than in `finance`, where the most access-restricted content in the estate will live.

**The column list is deliberately absent from the DDL and from this note.** It belongs to the source. Inventing it here would create a fourth definition while claiming to prevent one. Inventory it first:

```sql
DESCRIBE TABLE EXTENDED main.prod_refined.dim_date;
```

Then promote as-is with `CREATE TABLE ... AS SELECT * FROM main.prod_refined.dim_date`, and inherit the column contract.

## The one column the design adds

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `fiscal_period_key` | BIGINT | Yes | Derived | FK to [dim_fiscal_calendar](dim_fiscal_calendar.md) at `period_level = 'period'`. Added by `ALTER TABLE` after promotion. `dim_date` **references** its fiscal period rather than absorbing the period's attributes, because a calendar date is immutable and a period's close state is not |

Plus two constraint changes: `date_key` set `NOT NULL`, and `pk_dim_date PRIMARY KEY (date_key)`.

## T-01 is the blocking test for the whole catalog

**Every `date_key` column in files 04–09 is declared `INT` on the assumption of a `yyyymmdd` surrogate.** If the promoted source uses `DATE` or `BIGINT`, change the facts — not this file. This is the first thing to check and the cheapest thing to get wrong, because a type mismatch across a dozen facts is a rewrite rather than an edit.

## Recommended joins

`dim_date` is the most-joined table in the catalog. Every fact carries exactly one `date_key`.

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_fiscal_calendar](dim_fiscal_calendar.md) | `dim_date.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Filter `dfc.period_level = 'period'`. Without the filter, the quarter and year rollup rows join too and every date fans out threefold |
| [fact_gl_posting](fact_gl_posting.md) | `f.date_key = d.date_key` | 1:N | `date_key` is built on `transaction_date`, **not** `document_date` or `originating_post_date` |
| [fact_ar_transaction](fact_ar_transaction.md) | `f.date_key = d.date_key` | 1:N | Built on `document_date` |
| [fact_ar_apply](fact_ar_apply.md) | `f.date_key = d.date_key` | 1:N | Built on `apply_date` |
| [fact_invoice_line](fact_invoice_line.md) | `f.date_key = d.date_key` | 1:N | Built on `actual_ship_date`, which is a **proxy** — the real document date lives on the unreplicated SOP30200 |
| [fact_referral_charge](fact_referral_charge.md), [fact_plan_adjustment](fact_plan_adjustment.md), [fact_gl_posting_work](fact_gl_posting_work.md) | `f.date_key = d.date_key` | 1:N | On `charge_date`, `transaction_date`, `transaction_date` respectively |

### Role-playing: one `date_key` is not enough

`fact_ar_transaction` carries **seven** date columns — `document_date`, `due_date`, `post_date`, `gl_post_date`, `sale_date`, `discount_date`, `date_paid_off` — and only one `date_key`, built on `document_date`. Aging is computed from `due_date`, so any aging query either joins `dim_date` a second time under an alias:

```sql
JOIN common.calendar.dim_date dd_due
  ON dd_due.date_key = cast(date_format(f.due_date, 'yyyyMMdd') AS INT)
```

or predicates directly on `f.due_date` and skips the dimension. Both are fine; mixing them across reports is not.

The same applies to [fact_gl_posting](fact_gl_posting.md) (`transaction_date` vs `document_date` vs `originating_post_date`) and [fact_ar_apply](fact_ar_apply.md) (`apply_date` vs both apply-from and apply-to document dates and GL post dates).

## Do not run yet: deprecating the existing copies

The DDL carries three `CREATE OR REPLACE VIEW` statements that would point the existing dimensions at this one. **`main.prod.dim_date` is a table with nine downstream consumers.** Replacing it with a view is a production change with nine blast-radius targets. Identify all nine, agree a schedule, then run them.
