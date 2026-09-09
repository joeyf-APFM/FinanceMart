---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.plan.fact_plan_amount

> [!NOTE]
> **The schema is called `plan`, the columns keep `BUDGET`**
>
> GP calls it a budget, the business plans against several things that are not budgets, and *"the schema will outlive whichever word is current"* — but **the GP column names keep BUDGET so the lineage back to source stays obvious.**

> [!WARNING]
> **Not built**
>
> DDL: [09-finance-plan.sql](../ddl/09-finance-plan.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Fact |
| **Grain** | Legal entity × budget × fiscal year × period × account |
| **Sources** | `GL00201` (budget detail) with `GL00200` (budget master) **denormalised on** |
| **Measure class** | `plan` |
| **Clustering** | `CLUSTER BY (legal_entity_code, fiscal_year, budget_id)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-12** (uniqueness of `(BUDGETID, ACTINDX, YEAR1, PERIODID)` in `gl00201`) |

## `GL00200.BUDPWRD` is deliberately not carried

**GL00200 carries a budget password.** It is excluded for the same reason `SY01400.PASSWORD` is excluded from [dim_gp_user](dim_gp_user.md): *"a secret that reaches a mart has effectively been published."*

The exclusion is recorded as `excludes_source_columns = 'BUDPWRD'` **so it cannot be quietly undone by someone adding "the rest of the header columns."**

## Denormalised rather than split into a `dim_plan`

`GL00200` has **seven usable columns after `BUDPWRD` is dropped**, and *"a four-column dimension bought at the price of a join every Genie query has to discover is a bad trade."*

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `plan_amount_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, budget_id, fiscal_year, period_number, account_index)`. **T-12** must confirm uniqueness in `gl00201` |
| `legal_entity_code` | STRING | No | Derived | **In the key because `BUDGETID` and `ACTINDX` are both company-scoped** |
| `legal_entity_key` | BIGINT | Yes | Derived | FK to [dim_legal_entity](dim_legal_entity.md) |
| `budget_id` | STRING | No | `GL00201.BUDGETID` | **GP allows many budgets per year, so this is part of the grain and not a filter to be forgotten. Two budgets summed together is a number that means nothing** |
| `budget_comment` | STRING | Yes | `GL00200.BUDCOMNT` | **Often the only human-readable statement of what a budget id represents** — carried so a consumer is not choosing between opaque codes |
| `budget_based_on` | INT | Yes | `GL00200.Based_On` | What GP built the budget from — another budget, actuals, or nothing. **Material to whether a variance is meaningful** |
| `budget_from_date` | DATE | Yes | `GL00200.From_Date` | Blank-date sentinel → NULL |
| `budget_to_date` | DATE | Yes | `GL00200.TODATE` | |
| `fiscal_year` | INT | No | `GL00201.YEAR1` | |
| `period_number` | INT | No | `GL00201.PERIODID` | **Period 0 carries beginning balances in GP and is not an error** |
| `period_date` | DATE | Yes | `GL00201.PERIODDT` | |
| `fiscal_period_key` | BIGINT | Yes | Derived | FK to [dim_fiscal_calendar](dim_fiscal_calendar.md) **at `period_level = 'period'`** |
| `account_index` | INT | No | `GL00201.ACTINDX` | GP's internal account key, **company-scoped** |
| `gl_account_key` | BIGINT | Yes | Derived | FK to [dim_gl_account](dim_gl_account.md). **The join that makes plan and actual comparable, and it only works if both sides resolve the account the same way** |
| `account_segment_1` … `account_segment_5` | STRING | Yes | `GL00201.ACTNUMBR_1..5` | GP repeats the segments on the budget detail row. **Carried so a plan figure can be read at segment grain without resolving the account dimension first** |
| `account_category_number` | INT | Yes | `GL00201.ACCATNUM` | |
| `budget_amount` | DECIMAL(19,5) | Yes | `GL00201.BUDGETAMT` | **The posted, current plan.** Adjustments are separate, in [fact_plan_adjustment](fact_plan_adjustment.md) — *"whether a consumer wants the plan as originally set or as adjusted is a real question this split lets them answer"* |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | e.g. `main.prod_gp_apfm_dbo_live.gl00201` |
| `_source_synced_at` | TIMESTAMP | Yes | `_fivetran_synced` | **NOT freshness** |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_plan_amount PRIMARY KEY (plan_amount_key)`; FKs to `dim_gl_account`, `common.calendar.dim_fiscal_calendar`, `dim_legal_entity`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `entity_x_budget_x_year_x_period_x_account` | |
| `measure_class` | `plan` | Not `recognized`, not `operational_not_recognized` |
| `excludes_source_columns` | `BUDPWRD` | **The exclusion is on the object so it cannot be silently reversed** |
| `budget_id_is_in_grain` | `true` | Stated because forgetting it is the likeliest error |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_gl_account](dim_gl_account.md) | `f.gl_account_key = a.account_key` | N:1 | Declared FK. **Plan and actual meet here** |
| [dim_fiscal_calendar](dim_fiscal_calendar.md) | `f.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Declared FK. Filter `period_level = 'period'` |
| [dim_legal_entity](dim_legal_entity.md) | `f.legal_entity_key = le.legal_entity_key` | N:1 | Declared FK |
| [fact_plan_adjustment](fact_plan_adjustment.md) | `(legal_entity_code, budget_id, fiscal_year, period_number, account_index)` | 1:N | **No FK.** Natural-key join, all five parts |
| [mart_plan_vs_actual](mart_plan_vs_actual.md) | This fact is its **plan** source | — | Aggregate |
| [mart_account_period_activity](mart_account_period_activity.md) | `(legal_entity_code, fiscal_year, account_key)` + period | N:M | **Prefer the mart** — see below |
| [dim_date](dim_date.md) | — | — | **No `date_key` on this table.** A plan is a period amount, not a dated event |

### `budget_id` in every query, or the number means nothing

```sql
-- RIGHT
WHERE budget_id = :budget

-- RIGHT: comparing two plans, which is a real question
GROUP BY budget_id, fiscal_year, period_number

-- WRONG: sums every budget GP holds for the year
SELECT fiscal_year, period_number, sum(budget_amount) FROM ... GROUP BY 1, 2
```

The wrong version returns a total that is a multiple of the real plan — 2× if there are two budgets, 3× if three — and there is nothing in the shape of the result to reveal it. This is why `budget_id_is_in_grain = 'true'` is a tag rather than a comment.

### Comparing plan to actual: use the mart, not the fact

```sql
-- RIGHT: mart_plan_vs_actual already does this, correctly, with the flags in the grain
SELECT * FROM finance.plan.mart_plan_vs_actual
WHERE  budget_id = :budget AND fiscal_year = :y
  AND  NOT includes_bbf AND NOT includes_pl_close

-- Hand-rolled: workable, but you must reproduce both flag predicates
FULL OUTER JOIN finance.general_ledger.mart_account_period_activity act
  ON  act.legal_entity_code = p.legal_entity_code
  AND act.fiscal_year       = p.fiscal_year
  AND act.fiscal_period     = p.period_number
  AND act.account_key       = p.gl_account_key
  AND NOT act.includes_bbf AND NOT act.includes_pl_close   -- omit these and the variance is wrong
```

**`FULL OUTER`, not inner.** An account with spend and no plan is exactly what a variance report exists to surface. And the actual side must come from [mart_account_period_activity](mart_account_period_activity.md) with its flags pinned — a variance against an actual that includes beginning-balance-forward entries **is wrong in a way that looks plausible.**

The currency trap composes here too: that mart's grain includes `currency_key`, and this fact has no currency column at all. **Plan amounts are functional currency; summing a multi-currency actual against them mixes units.**

### Reading a plan at segment grain without the dimension

```sql
SELECT account_segment_2, fiscal_year, period_number, sum(budget_amount)
FROM   finance.plan.fact_plan_amount
WHERE  budget_id = :budget AND legal_entity_code = :entity
GROUP BY 1, 2, 3
```

The segments are on the row precisely so this needs no join. **But do not group by `account_segment_1`** — for APFM that is the Company segment, `10` on 100% of activity, and the grouping returns one row while looking like a working breakdown. Same trap as on [dim_gl_account](dim_gl_account.md).

## Gotchas

- **`budget_amount` is the plan *after* posted adjustments.** "Plan as originally set" needs this minus the posted deltas in [fact_plan_adjustment](fact_plan_adjustment.md).
- **No currency column.** Amounts are functional currency by implication. Any CAPFM comparison needs translation on the actual side, not here.
- **`account_index` is company-scoped.** Any natural-key join to an account must carry `legal_entity_code`.
- **Period 0 exists.** Excluding it drops GP's beginning balances; including it in a period-by-period plan chart adds a phantom period.
- **T-12 is unresolved.** If `(BUDGETID, ACTINDX, YEAR1, PERIODID)` is not unique, the surrogate collides and plan rows are silently lost on load.
- **`budget_based_on` is worth reading before quoting a variance.** A budget built from prior actuals compared against those same actuals is a tautology, not a finding.
