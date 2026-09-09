---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.plan.mart_plan_vs_actual

> [!danger] `includes_bbf` and `includes_pl_close` are in the primary key — pin both
> They are **inherited from [[mart_account_period_activity]]**, whose grain carries them. Every account and period therefore appears **up to four times**, and an unpinned query returns a variance two to four times too large with a correct-looking sign, a correct-looking account list and a correct-looking period.
>
> *"A variance computed against an actual that includes beginning-balance-forward entries is wrong in a way that looks plausible"* — which is why the flags were carried through rather than collapsed.

> [!warning] Not built
> DDL: [[../ddl/09-finance-plan.sql|09-finance-plan.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Mart (aggregate) |
| **Grain** | Legal entity × budget × fiscal year × period × account × `includes_bbf` × `includes_pl_close` |
| **Sources** | [[fact_plan_amount]], [[fact_plan_adjustment]] (posted), and **[[mart_account_period_activity]]** for actual |
| **Join type** | **`FULL OUTER`** — tagged as such |
| **Clustering** | `CLUSTER BY (legal_entity_code, fiscal_year, budget_id)` |
| **Readers** | `finance-analysts` |
| **Known gap** | `committed_amount` — requires POP ingestion |

## Actual comes from the mart, not from the fact

*"Actual comes from `finance.general_ledger.mart_account_period_activity`, **NOT** from [[fact_gl_posting]] directly, so that plan-versus-actual and any activity report agree by construction rather than by coincidence."*

The consequence is a real dependency, not just a preference: **a change to how [[mart_account_period_activity]] aggregates changes this mart's `actual_amount`.** Anyone editing that mart's flag derivation is editing every variance in this one.

## Commitments are the first question anyone will ask

Plan versus actual answers *what did we plan and what did we spend.* It does not answer *what have we already committed but not yet spent* — that lives in Purchase Order Processing, and **the POP tables are not replicated.**

So `committed_amount` is a real column that is **always NULL, with the reason on it**:

> *"A missing column invites the assumption that spend is the whole story; a null column with a reason does not."*

**Populating it requires new ingestion, not new SQL.** The gap is also on the object as `known_gap = 'committed_amount_requires_pop_ingestion'`.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `legal_entity_code` | STRING | No | Derived | **PK.** APFM or CAPFM |
| `budget_id` | STRING | No | [[fact_plan_amount]] | **PK.** *"Comparing one period's actuals to two budgets is two answers and both are legitimate"* |
| `fiscal_year` | INT | No | Derived | **PK** |
| `period_number` | INT | No | Derived | **PK** |
| `fiscal_period_key` | BIGINT | Yes | Derived | FK to [[dim_fiscal_calendar]]. **Not in the PK** |
| `gl_account_key` | BIGINT | No | Derived | **PK.** FK to [[dim_gl_account]] |
| `account_index` | INT | No | Denormalised | **GP's account index, carried so a consumer can trace a row back to source without a join** |
| `includes_bbf` | BOOLEAN | No | Inherited | **PK.** Whether `actual_amount` includes beginning-balance-forward entries. **In the grain rather than a footnote** |
| `includes_pl_close` | BOOLEAN | No | Inherited | **PK.** Whether `actual_amount` includes profit-and-loss close entries |
| `plan_amount` | DECIMAL(19,5) | Yes | [[fact_plan_amount]] | **The plan as currently held in GP, which is the plan *after* posted adjustments** |
| `plan_adjustment_amount` | DECIMAL(19,5) | Yes | [[fact_plan_adjustment]], posted | Sum of posted adjustments for the same key. **Carried separately so that "plan as originally set" and "plan as adjusted" are both answerable.** Not additive to `plan_amount` |
| `actual_amount` | DECIMAL(19,5) | Yes | [[mart_account_period_activity]] | **Sourced from that mart rather than from `fact_gl_posting` so that this and any activity report agree by construction** |
| `committed_amount` | DECIMAL(19,5) | Yes | — | **ALWAYS NULL TODAY, and present on purpose.** See above |
| `variance_amount` | DECIMAL(19,5) | Yes | Derived | `actual_amount − plan_amount`. **Sign convention fixed here: positive means actual exceeds plan, regardless of whether the account is income or expense. Do not flip the sign per account type in this table — do it in the presentation layer where the audience is known** |
| `variance_pct` | DECIMAL(9,6) | Yes | Derived | `variance_amount / plan_amount`. **NULL where `plan_amount` is zero, rather than zero or infinity — a null percentage against a zero plan is the honest answer** |
| `has_plan` | BOOLEAN | No | Derived | False where actuals exist for an unplanned account. **This is a `FULL OUTER JOIN`, not an inner one: an unplanned account with spend is exactly what a variance report exists to surface, and an inner join would hide it** |
| `has_actual` | BOOLEAN | No | Derived | False where a plan exists with no activity. **Also a legitimate finding rather than a defect** |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_mart_plan_vs_actual PRIMARY KEY (legal_entity_code, budget_id, fiscal_year, period_number, gl_account_key, includes_bbf, includes_pl_close)`; `fk_pva_account` → `dim_gl_account`; `fk_pva_period` → `common.calendar.dim_fiscal_calendar`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `entity_x_budget_x_period_x_account` | **Note the tag omits the two flags the PK carries — the PK is the authority** |
| `join_type` | `full_outer` | So `has_plan = false` rows are not read as corruption |
| `known_gap` | `committed_amount_requires_pop_ingestion` | The gap is discoverable from the object |
| `actual_sourced_from` | `finance.general_ledger.mart_account_period_activity` | **The dependency is on the object** |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_gl_account]] | `m.gl_account_key = a.account_key` | N:1 | Declared FK. **Where plan and actual meet** |
| [[dim_fiscal_calendar]] | `m.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Declared FK. Filter `period_level = 'period'` |
| [[dim_legal_entity]] | `m.legal_entity_code = le.legal_entity_code` | N:1 | **No surrogate carried** |
| [[fact_plan_amount]] | `(legal_entity_code, budget_id, fiscal_year, period_number, account_index)` | 1:N | Drill-down to the plan side |
| [[fact_plan_adjustment]] | same natural key + `is_posted` | 1:N | Drill-down. **`is_posted` in the `ON` clause** |
| [[mart_account_period_activity]] | `(legal_entity_code, fiscal_year, fiscal_period, account_key)` **+ both flags** | 1:N | Drill-down to actual. **The flags must match this row's flags** |
| [[fact_gl_posting]] | Via the activity mart | — | **Do not go direct** — the two would then disagree |
| [[mart_billing_by_stream]] | **Do not join** | — | Billing is `operational_not_recognized`; plan is compared to recognised actuals |

### Pin both flags. Always.

```sql
-- RIGHT
WHERE budget_id = :budget AND fiscal_year = :y
  AND NOT includes_bbf AND NOT includes_pl_close

-- WRONG: up to four overlapping aggregates of the same postings
SELECT gl_account_key, sum(variance_amount)
FROM   finance.plan.mart_plan_vs_actual
WHERE  budget_id = :budget AND fiscal_year = :y
GROUP BY 1
```

Which combination is right depends on the question — a P&L variance normally wants neither BBF nor close entries; a balance-sheet movement question may want BBF. **What is never right is leaving them unpinned**, because `plan_amount` is repeated identically across all four combinations while `actual_amount` varies, so the variance is inflated *and* the plan is double counted.

This is the same trap as on [[mart_account_period_activity]], and it arrives here by inheritance rather than by choice.

### Do not filter `has_plan` or `has_actual` to true

```sql
-- RIGHT: the findings ARE the report
SELECT CASE WHEN NOT has_plan   THEN 'spend with no plan'
            WHEN NOT has_actual THEN 'plan with no spend'
            ELSE 'both' END AS finding,
       count(*), sum(coalesce(actual_amount, 0)), sum(coalesce(plan_amount, 0))
FROM   finance.plan.mart_plan_vs_actual
WHERE  budget_id = :budget AND fiscal_year = :y
  AND  NOT includes_bbf AND NOT includes_pl_close
GROUP BY 1

-- WRONG: hides exactly what a variance report exists to surface
WHERE has_plan AND has_actual
```

An unplanned account with spend is the highest-value row in the table. The `FULL OUTER JOIN` is what puts it there, and `join_type = 'full_outer'` is tagged so nobody reads those rows as a broken load and filters them out.

### `variance_pct` is null against a zero plan — leave it null

```sql
-- RIGHT
CASE WHEN variance_pct IS NULL AND coalesce(plan_amount, 0) = 0
       THEN 'no plan to vary from'
     ELSE format_number(variance_pct * 100, 1) || '%' END

-- WRONG: reports infinite overspend as on-plan
coalesce(variance_pct, 0)
```

Sorting a dashboard by `variance_pct DESC` also silently drops these rows to the bottom regardless of how large `variance_amount` is. **Rank on `variance_amount` when the point is materiality, on `variance_pct` when the point is proportion — and never on `variance_pct` alone.**

### The sign convention is fixed here and flipped only downstream

`variance_amount` is `actual − plan` for **every** account type. So for an expense account, positive means overspend; for a revenue account, positive means overperformance. Both are literally "actual exceeded plan."

```sql
-- RIGHT: flip in the presentation layer, where you know the audience
CASE WHEN a.account_type IN ('Revenue') THEN m.variance_amount
     ELSE -m.variance_amount END AS favourable_variance
```

Doing this inside the mart would make the stored column mean two different things depending on a joined attribute, and any consumer summing across account types would be adding a favourable to an unfavourable number as though they agreed.

### `plan_amount` and `plan_adjustment_amount` are not additive

`plan_amount` is already the plan *after* posted adjustments — the same relationship as on [[fact_plan_adjustment]]. To get the original plan, **subtract**:

```sql
plan_amount - coalesce(plan_adjustment_amount, 0)  AS plan_as_originally_set
plan_amount                                       AS plan_as_adjusted
```

## Gotchas

- **`committed_amount` is always null.** Do not `coalesce` it to zero, and do not present "actual vs plan" as complete spend commitment. A period with large open POs looks under budget here and is not.
- **This mart depends on another mart's aggregation rules.** [[mart_account_period_activity]]'s currency grain is *not* carried here, so confirm how the pipeline collapses currency before using this cross-entity — a CAPFM variance against a functional-currency plan needs translation, and there is no currency column to check it against.
- **`grain` tag and PK disagree in detail.** The tag says `entity_x_budget_x_period_x_account`; the PK adds the two flags. **The PK is the grain.**
- **No `source_system` / `source_table`.** Provenance is the `actual_sourced_from` tag plus `_loaded_at`.
- **T-06 gates the flags.** The BBF / P&L-close derivation depends on profiling distinct `SOURCDOC` values; until that runs, both flags are a design intent rather than a validated split — and the variance inherits that.
- **T-12 gates the plan side.** A non-unique `(BUDGETID, ACTINDX, YEAR1, PERIODID)` in `gl00201` collapses plan rows before they reach here.
