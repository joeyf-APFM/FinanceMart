---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# common.calendar.dim_fiscal_calendar

> [!warning] Not built
> DDL: [[../ddl/03-common-calendar.sql|03-common-calendar.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Conformed dimension |
| **Grain** | Fiscal period **× period level** — not one row per calendar date |
| **Sources** | `sy40100` (periods), `sy40101` (fiscal years) |
| **Built by / owned by** | Finance / Data Platform |
| **Clustering** | `CLUSTER BY (fiscal_year, period_level)` |
| **Readers** | `` `account users` `` |
| **Tests** | **T-03** blocks publication |

## Why it exists

`SY40100` and `SY40101` mostly close the sourcing gap the vault previously recorded for a fiscal calendar. They supply period boundaries, period names, fiscal-year start and end, the number of periods in a year, and the historical-year flag.

**Close state is deliberately absent from this table.** GP grains period close on period **× series**, so a single close flag per period would be silently wrong for whoever cares about the other series. Close state lives in [[snap_period_close_daily]]. This is the correction the design makes to an earlier vault claim, and it is the reason this dimension is period-grained and stays that way.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `fiscal_period_key` | BIGINT | No | Derived | PK. `xxhash64(fiscal_year, period_level, period_number)`. Deterministic rather than identity because the table is rebuilt from a replica and identity would renumber on reload, orphaning every fact keyed to it |
| `fiscal_year` | INT | No | `SY40101.YEAR1` | The GP fiscal year |
| `period_level` | STRING | No | Derived | `period`, `quarter`, or `year`. **Only `period` rows come from GP.** Quarter and year rows are derived by rollup |
| `period_number` | INT | No | `SY40100.PERIODID` | 1–4 for quarters, 0 for the year row. **Period 0 at `period_level = 'period'` is not an error** — GP uses it for beginning-balance-forward |
| `period_name` | STRING | Yes | `SY40100.PERNAME` | As maintained in GP |
| `period_start_date` | DATE | Yes | `SY40100.PERIODDT` | Blank-date sentinel `1900-01-01` → NULL |
| `period_end_date` | DATE | Yes | `SY40100.PERDENDT` | |
| `fiscal_year_start_date` | DATE | Yes | `SY40101.FSTFSCDY` | First day of the fiscal year |
| `fiscal_year_end_date` | DATE | Yes | `SY40101.LSTFSCDY` | Last day |
| `periods_in_year` | INT | Yes | `SY40101.NUMOFPER` | **Read this rather than assuming twelve** |
| `is_historical_year` | BOOLEAN | Yes | `SY40101.HISTORYR` | True once GP moves the year to history. This is also the boundary between `gl20000` and `gl30000` |
| `is_derived_level` | BOOLEAN | No | Derived | True for quarter and year rows. **A consumer summing across levels without filtering will double count** |
| `source_calendar` | STRING | No | Derived | Which GP company supplied the boundaries. Expected to be a single shared value — publication is blocked on T-03 |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | Fully qualified guarded-layer table |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraint:** `pk_dim_fiscal_calendar PRIMARY KEY (fiscal_period_key)`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `conformed` | `true` | Shared across domains; do not fork a copy |
| `grain` | `fiscal_period_x_period_level` | Stated as a tag so a consumer sees it without reading a comment |
| `built_by` | `finance` | Finance's pipeline writes it |
| `owned_by` | `data_platform` | Finance does not own the contract |

## T-03: the test that can invalidate the table

**A conformed calendar cannot represent two different calendars.** T-03 confirms that APFM and CAPFM define identical fiscal periods in `SY40100`/`SY40101`. If they do not, this table has to be grained on legal entity as well, `source_calendar` becomes load-bearing rather than a provenance stamp, and every `fiscal_period_key` in every fact changes. Run T-03 before anything joins to this.

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_date]] | `dd.fiscal_period_key = dfc.fiscal_period_key` | 1:N | **Filter `period_level = 'period'`** |
| [[snap_period_close_daily]] | `s.fiscal_period_key = dfc.fiscal_period_key` | 1:N | The snapshot's own grain includes `series_id`; see the fan-out warning on that note |
| [[fact_gl_posting]] | `f.fiscal_period_key = dfc.fiscal_period_key` | 1:N | Filter `period_level = 'period'`. Note the fact carries **both** `fiscal_period_key` and `date_key`, deliberately separate — the period an amount is recognised in is not always the period its transaction date falls in |
| [[fact_ar_transaction]] | `f.fiscal_period_key = dfc.fiscal_period_key` | 1:N | Built on `gl_post_date`, not `document_date` |
| [[fact_ar_apply]], [[mart_writeoff]] | `f.fiscal_period_key = dfc.fiscal_period_key` | 1:N | Both on `gl_post_date` |
| [[fact_plan_amount]], [[fact_plan_adjustment]], [[mart_plan_vs_actual]] | `f.fiscal_period_key = dfc.fiscal_period_key` | 1:N | |
| [[mart_billing_by_stream]] | `m.fiscal_period_key = dfc.fiscal_period_key` | 1:N | `fiscal_period_key` is the leading column of that mart's PK |
| [[mart_account_period_activity]], [[mart_period_summary]] | `m.fiscal_period_key = dfc.fiscal_period_key` | 1:N | |

### The one join that is always wrong

**Filtering `period_level` is not optional.** Every fact keys to the `period` rows. A join without the filter matches the quarter and year rollup rows as well, tripling every fact row and producing a total that is roughly three times correct — plausible enough to ship.

## Gotchas

- **Period 0 is real.** It carries beginning-balance-forward. Do not filter it as invalid; filter it deliberately using the BBF flags on [[fact_gl_posting]].
- **`periods_in_year` may not be 12.** Read it.
- **`is_derived_level` distinguishes GP truth from this pipeline's rollup.** Anything reconciled back to GP must filter to `is_derived_level = false`.
