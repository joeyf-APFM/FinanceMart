---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.general_ledger.mart_period_summary

> [!warning] Not built
> DDL: [[../ddl/06-finance-general-ledger.sql|06-finance-general-ledger.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Mart (summary, **vintaged**) |
| **Grain** | Legal entity × fiscal year × period × account **category** × as-of date × currency |
| **Sources** | [[fact_gl_posting]] via [[dim_gl_account]]; close state from [[snap_period_close_daily]] |
| **Clustering** | `CLUSTER BY (legal_entity_code, fiscal_year, as_of_date)` |
| **Readers** | `finance-analysts` |
| **Depends on** | `common.calendar.snap_period_close_daily` — **stated as a tag** |

## Why it exists next to `mart_account_period_activity`

Two differences, both deliberate:

1. **It rolls up on `account_category_number`**, not the raw account. Chosen so this table is a *summary* rather than a second copy of [[mart_account_period_activity]].
2. **It carries as-of close state.** Read from [[snap_period_close_daily]], **not from `SY40100` directly** — which is the whole reason the snapshot exists. `SY40100` answers *"is it closed now"*; every vintage measure needs *"was it closed as of the reporting date."*

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `legal_entity_code` | STRING | No | Fact | **PK** |
| `fiscal_year` | INT | No | Fact | **PK** |
| `fiscal_period` | INT | No | Fact | **PK** |
| `fiscal_period_key` | BIGINT | Yes | Fact | FK to [[dim_fiscal_calendar]] |
| `account_category_number` | INT | Yes | `GL00100.ACCATNUM` | **PK.** The rollup level |
| `account_category_description` | STRING | Yes | `GL00102.ACCATDSC` | Denormalised so the summary reads without a join |
| `posting_type` | INT | Yes | [[dim_gl_account]] | Balance-sheet vs P&L |
| `as_of_date` | DATE | No | Pipeline | **PK. The vintage of this row.** Part of the grain because the same period summarised on two dates can legitimately differ — *that is what a vintage measure is* |
| `financial_series_is_closed` | BOOLEAN | Yes | Snapshot, `SERIES = 2` | As observed on `as_of_date`. **Null where no snapshot exists for that date, which is honest: before the snapshot started, the answer is unknown rather than open** |
| `sales_series_is_closed` | BOOLEAN | Yes | Snapshot, `SERIES = 3` | **Carried separately** because a period can be closed for Financial and open for Sales — one close flag per period is silently wrong for whoever cares about the other series |
| `net_activity_amount` | DECIMAL(19,5) | Yes | Fact | Net activity **excluding** BBF and P&L close rows |
| `net_activity_amount_with_close` | DECIMAL(19,5) | Yes | Fact | Net activity **including** them, for audit extracts |
| `currency_key` | BIGINT | Yes | Fact | **PK.** FK to [[dim_currency]] |
| `source_system` | STRING | No | Literal | `GP` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraint:** `pk_mart_period_summary PRIMARY KEY (legal_entity_code, fiscal_year, fiscal_period, account_category_number, as_of_date, currency_key)`. **No foreign keys are declared on this table.**

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `period_x_entity_x_category_x_as_of` | |
| `depends_on_snapshot` | `common.calendar.snap_period_close_daily` | The dependency is on the object, so breaking the snapshot has a discoverable consequence |

## The two amount columns replace a flag pair

Where [[mart_account_period_activity]] puts `includes_bbf` and `includes_pl_close` **in the grain**, this mart resolves the same choice as **two named measures on one row**. Both approaches avoid a hidden default; this one is cheaper to query and coarser — you get the with-close and without-close figures, not the four combinations.

Consequence: **there is no flag to pin here.** Pick the column instead.

```sql
-- Activity reporting
SELECT ..., net_activity_amount            FROM ...
-- Audit extract
SELECT ..., net_activity_amount_with_close FROM ...
```

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_fiscal_calendar]] | `m.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Filter `period_level = 'period'` |
| [[dim_currency]] | `m.currency_key = c.currency_key` | N:1 | |
| [[dim_legal_entity]] | `m.legal_entity_code = le.legal_entity_code` | N:1 | |
| [[snap_period_close_daily]] | Already resolved onto the mart | — | **Do not re-join it.** The two close columns are the resolved answer |
| [[dim_gl_account]] | `m.account_category_number = a.account_category_number` | **1:N** | **Not an account-grain join.** See below |
| [[mart_account_period_activity]] | `(legal_entity_code, fiscal_year, fiscal_period, currency_key)` | 1:N | Only as a drill-down, and only after pinning the other mart's flags |

### Do not join to `dim_gl_account` on the category

The grain is the category, not the account. Joining the dimension on `account_category_number` fans one summary row out to **every account in the category** — and because `net_activity_amount` is then repeated per account, any `sum()` multiplies by the account count.

`account_category_description` and `posting_type` are already denormalised onto the mart precisely so this join is never needed.

### `as_of_date` must be pinned in every query

```sql
-- RIGHT: one vintage
WHERE as_of_date = :d

-- RIGHT: deliberate vintage comparison — the reason the column is in the key
WHERE as_of_date IN (:d1, :d2)

-- WRONG: sums every vintage ever computed
SELECT fiscal_period, sum(net_activity_amount) FROM ... GROUP BY 1
```

Unpinned, the total grows every day the mart runs. Unlike the flag traps elsewhere, this one gets **worse over time** — it looks fine in week one and is off by a factor of thirty by month two.

### Null close state is not "open"

```sql
-- RIGHT: three-state
CASE WHEN financial_series_is_closed IS NULL THEN 'unknown (pre-snapshot)'
     WHEN financial_series_is_closed        THEN 'closed'
     ELSE 'open' END

-- WRONG: reports every pre-snapshot period as open
coalesce(financial_series_is_closed, false)
```

The nulls are a deliberate statement about what the snapshot can and cannot know. Coalescing them away converts *unknown* into a confident wrong answer — for exactly the historical periods most likely to be audited.

## Gotchas

- **The category rollup depends on `ACCATNUM` being populated and meaningful.** An account with a null or default category collapses into one bucket.
- **Both close columns can be null while the amounts are populated.** That is a period summarised before snapshotting began, not a load failure.
- **Only series 2 and 3 are carried.** Purchasing, Inventory, Payroll and Project close state is in [[snap_period_close_daily]] and not here — if a consumer needs those, the mart needs new columns rather than a join.
- **No FK constraints.** Referential expectations here are documented only in this note and the DDL comments.
