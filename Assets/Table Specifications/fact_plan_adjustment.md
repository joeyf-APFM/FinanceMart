---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.plan.fact_plan_adjustment

> [!danger] GP's own typo is reproduced verbatim — `BudgerAdjustment`
> The source column is **`BudgerAdjustment`** in both `GL32000` and `GL12001`. **Not `BudgetAdjustment`.** It is spelled that way in the DDL comments on purpose: *"a load script written from a corrected spelling will fail, and the failure will look like a missing column rather than a typo."*
>
> `REFRENCE` is misspelled in GP too, and is likewise left alone.

> [!warning] Not built
> DDL: [[../ddl/09-finance-plan.sql|09-finance-plan.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Fact — **posted and unposted in one table**, separated by `is_posted` |
| **Grain** | One budget adjustment line |
| **Sources** | `GL32000` (posted) **∪** `GL12000` + `GL12001` (unposted) |
| **Measure class** | `plan` |
| **Clustering** | `CLUSTER BY (legal_entity_code, fiscal_year, budget_id)` |
| **Readers** | `finance-analysts` |

## Why this unions and [[fact_gl_posting]] does not

The asymmetry is deliberate and the reason is stated in the DDL:

> [[fact_gl_posting]] and [[fact_gl_posting_work]] are separate **because their measure classes differ** — recognised versus not recognised — and mixing them would let unposted amounts into a recognised total. **A plan adjustment is not a recognised measure either way, so the risk does not exist and the convenience of one table wins.**

The cost of that convenience is that `is_posted` must be filtered deliberately, which is why the column comment says so and why it is in the surrogate-key derivation.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `plan_adjustment_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, journal_entry_number, budget_id, fiscal_year, period_number, account_index, is_posted)`. **`is_posted` is in the derivation because an unposted adjustment and the posted row it becomes are two observations of the same thing and must not collide** |
| `legal_entity_code` | STRING | No | Derived | APFM or CAPFM |
| `journal_entry_number` | BIGINT | No | `GL32000.JRNENTRY` / `GL12000.JRNENTRY` | **Company-scoped, and reused across years in GP — never treat it as globally unique** |
| `batch_number` | STRING | Yes | `GL12000.BACHNUMB` / `GL12001.BACHNUMB` | **Unposted only.** `GL32000` does not carry it |
| `batch_source` | STRING | Yes | `GL12000.BCHSOURC` | **Unposted only** |
| `budget_id` | STRING | No | `GL32000.BUDGETID` | In the grain, as on [[fact_plan_amount]] |
| `fiscal_year` | INT | No | `GL32000.YEAR1` | |
| `period_number` | INT | No | `GL32000.PERIODID` | |
| `period_date` | DATE | Yes | `GL32000.PERIODDT` | |
| `fiscal_period_key` | BIGINT | Yes | Derived | FK to [[dim_fiscal_calendar]] |
| `account_index` | INT | No | `GL32000.ACTINDX` | Company-scoped |
| `gl_account_key` | BIGINT | Yes | Derived | FK to [[dim_gl_account]] |
| `transaction_date` | DATE | Yes | `GL32000.TRXDATE` / `GL12000.TRXDATE` | |
| `date_key` | INT | Yes | Derived on `transaction_date` | FK to [[dim_date]] |
| `budget_amount` | DECIMAL(19,5) | Yes | `GL32000.BUDGETAMT` / `GL12001.BUDGETAMT` | **The resulting budget amount — the LEVEL** |
| `adjustment_amount` | DECIMAL(19,5) | Yes | **`GL32000.BudgerAdjustment` / `GL12001.BudgerAdjustment`** | **The DELTA.** *"Summing the two together double counts"* |
| `reference` | STRING | Yes | `GL32000.REFRENCE` | **GP's own misspelling of reference** |
| `source_document` | STRING | Yes | `GL32000.SOURCDOC` | |
| `trx_source` | STRING | Yes | `GL32000.TRXSORCE` | |
| `posted_by_user_id` | STRING | Yes | `GL32000.USWHPSTD` / `GL12000.USWHPSTD` | **Resolve through [[dim_gp_user]] rather than reading `sy01400`** |
| `last_user_id` | STRING | Yes | `GL12000.LASTUSER` | **Unposted only** |
| `posting_status` | INT | Yes | `GL12000.PSTGSTUS` | **Unposted only** |
| `error_state` | INT | Yes | `GL12000.ERRSTATE` | **Unposted only, and usually the answer to why an adjustment has not posted.** Header detail in `GLHDRVAL` / `GLHDRMSG` / `GLHDRMS2`, line detail in `GL12001.GLLINVAL` |
| `header_validation_message` | STRING | Yes | `GL12000.GLHDRMSG` ‖ `GLHDRMS2` | Concatenated where both populated. **Unposted only** |
| `line_validation_code` | INT | Yes | `GL12001.GLLINVAL` | **Unposted only** |
| `is_posted` | BOOLEAN | No | Derived | True from `gl32000`, false from `gl12000` + `gl12001`. **Every consumer must filter on this deliberately: an unposted adjustment is a proposal, not a plan change** |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | The guarded-layer table the row came from |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_plan_adjustment PRIMARY KEY (plan_adjustment_key)`; `fk_plan_adj_account` → `dim_gl_account`; `fk_plan_adj_period` → `common.calendar.dim_fiscal_calendar`. **No `legal_entity_key` and no FK to [[dim_legal_entity]]** — unlike [[fact_plan_amount]]. Join on `legal_entity_code`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `plan_adjustment_line` | |
| `measure_class` | `plan` | Both states — which is *why* they share a table |
| `unions` | `gl32000,gl12000+gl12001` | The union is discoverable from the object |
| `source_column_typo` | `BudgerAdjustment` | **On the object so nobody "fixes" it** |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_gl_account]] | `a.gl_account_key = adj.gl_account_key` | N:1 | Declared FK |
| [[dim_fiscal_calendar]] | `dfc.fiscal_period_key = adj.fiscal_period_key` | N:1 | Declared FK. Filter `period_level = 'period'` |
| [[dim_date]] | `d.date_key = adj.date_key` | N:1 | **No declared FK.** On `transaction_date` |
| [[fact_plan_amount]] | `(legal_entity_code, budget_id, fiscal_year, period_number, account_index)` | N:1 | **No FK.** Natural-key join, all five parts, `trim()` the strings |
| [[dim_gp_user]] | `trim(u.user_id) = trim(adj.posted_by_user_id)` | N:1 | **Trim both sides** — GP `char` columns are space-padded |
| [[dim_legal_entity]] | `le.legal_entity_code = adj.legal_entity_code` | N:1 | **No surrogate on this table** |
| [[mart_plan_vs_actual]] | This fact is its `plan_adjustment_amount` source | — | **Posted rows only** |
| [[fact_gl_posting]] | **Do not join to compare** | — | Different measure classes. A plan adjustment is not an actual |

### `is_posted` in every query

```sql
-- RIGHT: the plan as GP currently holds it
WHERE is_posted

-- RIGHT: what is waiting to change the plan, which is a different question
WHERE NOT is_posted

-- WRONG: counts proposals as plan changes, and counts the same adjustment twice
--        once it posts (the unposted row is not deleted from the replica reliably)
SELECT budget_id, sum(adjustment_amount) FROM finance.plan.fact_plan_adjustment GROUP BY 1
```

The wrong version does not error and its magnitude depends on how much sits in unposted batches at the moment of the query — so it is **irreproducible as well as wrong.** This is the single most likely mistake against this table, which is why the flag is in the surrogate key rather than only in a comment.

### `adjustment_amount` is a delta, `budget_amount` is a level

```sql
-- RIGHT: how much the plan moved
SELECT gl_account_key, sum(adjustment_amount) AS net_plan_change
FROM   finance.plan.fact_plan_adjustment
WHERE  is_posted AND budget_id = :budget AND fiscal_year = :y
GROUP BY 1

-- RIGHT: what the plan became, as at the latest adjustment
SELECT gl_account_key, budget_amount
FROM   ... QUALIFY row_number() OVER (PARTITION BY gl_account_key ORDER BY transaction_date DESC) = 1

-- WRONG: adds a running level to a delta
sum(budget_amount + adjustment_amount)
```

Two columns describing the same adjustment from different angles. `sum(budget_amount)` across several adjustments to one account is also meaningless — it adds successive *states*, not changes.

### Plan as originally set versus plan as adjusted

```sql
SELECT p.gl_account_key,
       p.budget_amount                                       AS plan_as_adjusted,
       p.budget_amount - coalesce(sum(a.adjustment_amount), 0) AS plan_as_originally_set
FROM      finance.plan.fact_plan_amount p
LEFT JOIN finance.plan.fact_plan_adjustment a
       ON  a.legal_entity_code = p.legal_entity_code
       AND trim(a.budget_id)   = trim(p.budget_id)
       AND a.fiscal_year       = p.fiscal_year
       AND a.period_number     = p.period_number
       AND a.account_index     = p.account_index
       AND a.is_posted                                   -- in the ON clause, not the WHERE
GROUP BY 1, 2
```

**`a.is_posted` must be in the `ON` clause.** In the `WHERE` it converts the `LEFT JOIN` to an inner one and drops every account that has never been adjusted — i.e. most of the plan. Same failure mode as the as-of predicate on [[fact_ar_apply]].

`fact_plan_amount.budget_amount` is already the plan **after** posted adjustments, so this is a subtraction, not an addition.

### Why has an adjustment not posted?

```sql
SELECT journal_entry_number, batch_number, batch_source, posting_status,
       error_state, header_validation_message, line_validation_code,
       budget_id, fiscal_year, period_number, adjustment_amount
FROM   finance.plan.fact_plan_adjustment
WHERE  NOT is_posted
ORDER BY error_state DESC NULLS LAST, transaction_date
```

The validation columns exist for exactly this query. They are **null by construction on posted rows** — a null `error_state` on a posted adjustment is not a missing value.

## Gotchas

- **Seven columns are unposted-only** (`batch_number`, `batch_source`, `last_user_id`, `posting_status`, `error_state`, `header_validation_message`, `line_validation_code`). Their nulls on posted rows are structural, not data quality. A completeness check that flags them will flag every posted row.
- **`journal_entry_number` is company-scoped and reused across years.** Any join or dedupe on it alone will silently merge unrelated adjustments across entities and years.
- **The GP column is `BudgerAdjustment` and the reference column is `REFRENCE`.** Both misspellings are load-bearing.
- **No `_source_synced_at`** on this table, unlike [[fact_plan_amount]]. Provenance is `source_table` plus `_loaded_at`.
- **No currency.** Plan and its adjustments are functional currency by implication.
- **An unposted adjustment and the posted row it becomes both exist** for as long as the replica carries them. That is the intent — but it means `count(*)` of adjustments is not a count of distinct adjustments unless `is_posted` is pinned.
