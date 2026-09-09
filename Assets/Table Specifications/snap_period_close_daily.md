---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# common.calendar.snap_period_close_daily

> [!danger] The one table with a deadline
> Every day without this snapshot is a day of history that **cannot be recovered**. `SY40100.CLOSED` is a current-state boolean and Fivetran overwrites it — GP records "is this period closed now" and never "was this period closed as of last Tuesday." Nine BO 2.0 vintage revenue measures need the second question. This should start collecting into a scratch schema **before the catalog exists and before Finance reviews anything**.

> [!warning] Not built
> DDL: [[../ddl/03-common-calendar.sql|03-common-calendar.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Snapshot, append-only |
| **Grain** | Snapshot date × legal entity × fiscal year × period × **series** |
| **Source** | `sy40100`, both companies, observed daily |
| **Clustering** | `CLUSTER BY (snapshot_date, legal_entity_code)` |
| **Written by** | `sp-finance-snapshot` — a **separate** service principal from the mart build, so the snapshot can still run on a day the mart build is broken |
| **Readers** | `` `account users` `` |

## Why series is in the grain

**A period can be closed for Financial and open for Sales.** One close flag per period is silently wrong for whoever cares about the other series. This is the correction the design makes to the earlier vault claim that one flag per period would do.

Series codes, per the GP metadata reference: `1` All, `2` Financial, `3` Sales, `4` Purchasing, `5` Inventory, `6` Payroll - USA, `7` Project.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `snapshot_date` | DATE | No | `current_date()` | PK. **This column exists because GP does not** |
| `legal_entity_code` | STRING | No | Derived | PK. `APFM` or `CAPFM`. Each company maintains its own close state — do not assume they match |
| `fiscal_year` | INT | No | `SY40100.YEAR1` | PK |
| `period_number` | INT | No | `SY40100.PERIODID` | PK |
| `series_id` | INT | No | `SY40100.SERIES` | PK. See the code list above |
| `series_name` | STRING | Yes | Decoded | Decoded here rather than left to consumers, because the codes are not self-evident |
| `fiscal_period_key` | BIGINT | Yes | Derived | FK to [[dim_fiscal_calendar]] at `period_level = 'period'` |
| `is_closed` | BOOLEAN | No | `SY40100.CLOSED` | **As observed on `snapshot_date`. This is the whole point of the table** |
| `period_start_date` | DATE | Yes | `SY40100.PERIODDT` | As observed, so a period boundary edited in GP shows up as a change rather than being silently overwritten |
| `period_end_date` | DATE | Yes | `SY40100.PERDENDT` | As observed |
| `origin_flag` | STRING | Yes | `SY40100.FORIGIN` | Retained **unresolved** — semantics are undocumented in the vault. Profile before using |
| `source_table` | STRING | No | Literal | e.g. `main.prod_gp_apfm_dbo_live.sy40100` |
| `_source_synced_at` | TIMESTAMP | Yes | `_fivetran_synced` | **NOT a freshness signal** — it advances only when the row changes. Provenance only |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_snap_period_close_daily PRIMARY KEY (snapshot_date, legal_entity_code, fiscal_year, period_number, series_id)`; `fk_snap_close_period FOREIGN KEY (fiscal_period_key) REFERENCES common.calendar.dim_fiscal_calendar`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `append_only` | `true` | Never restate. A restatement destroys the only copy of the observation |
| `irrecoverable_if_delayed` | `true` | The tag that distinguishes this from [[snap_ar_aging_daily]], which has a reconstruction fallback. **This one has none** |
| `grain` | `snapshot_date_x_legal_entity_x_period_x_series` | |

## The load

`INSERT INTO` once per day, one `SELECT` per company `UNION ALL`ed. **Missing a day loses that day permanently.** The full statement is in the DDL, commented.

## Two convenience views ship with it

| View | Answers | Do not use it for |
|---|---|---|
| `vw_period_close_current` | "Is it closed now" — latest observation per entity, year, period, series via `QUALIFY row_number()` | "Was it closed as of date D." That is what the snapshot is for and this view cannot answer it |
| `vw_period_close_transitions` | One row per observed change in close state, from consecutive snapshots via `lag()` | Anything needing completeness. **A period closed and reopened within one day is invisible** — it only sees transitions that fall between two snapshots |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_fiscal_calendar]] | `s.fiscal_period_key = dfc.fiscal_period_key` | N:1 | |
| [[mart_period_summary]] | `(legal_entity_code, fiscal_year, fiscal_period)` + `snapshot_date = as_of_date` + `series_id` | N:1 per series | This mart is the primary consumer. It reads series 2 and 3 into two separate columns — `financial_series_is_closed` and `sales_series_is_closed` — rather than one flag |
| [[fact_gl_posting]] | `(legal_entity_code, fiscal_year, fiscal_period)` + `f.series_id = s.series_id` | N:M | The fact's `series_id` is the column that ties a posting to the close series governing it. **Joining without it is the classic error** |

### Series fan-out is the hazard

```sql
-- WRONG: multiplies every fact row by up to seven
JOIN common.calendar.snap_period_close_daily s
  ON  s.legal_entity_code = f.legal_entity_code
  AND s.fiscal_year       = f.fiscal_year
  AND s.period_number     = f.fiscal_period
  AND s.snapshot_date     = :as_of

-- RIGHT: pin the series, either from the fact or explicitly
  AND s.series_id = f.series_id      -- or: AND s.series_id = 2
```

There are up to seven series rows per period. A close-state join that omits `series_id` returns up to seven copies of every posting, and because the amounts are identical across the copies the resulting total is a clean multiple — the kind of error that survives review.

## Gotchas

- **A null close state is honest.** Rows whose `as_of_date` predates the start of snapshotting carry NULL in [[mart_period_summary]] on purpose: before the snapshot existed, the answer is *unknown*, not *open*.
- **`_source_synced_at` is not freshness.** A stale value means the row has not changed, not that the connector is broken.
- **Do not reconstruct this from `SY40100`.** There is nothing to reconstruct from. That is the entire reason the table exists.
