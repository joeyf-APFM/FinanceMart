---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.general_ledger.mart_account_period_activity

> [!CAUTION]
> **THIS IS NOT A TRIAL BALANCE**
>
> GP's account summary and beginning-balance tables are **not replicated**, so no opening balance exists to roll forward and no ending balance can be derived. This is **net period activity**. The design doc lists the slot as `mart_trial_balance` and instructs, in the same paragraph, to name it for what it is — because **a table called `mart_trial_balance` will be reconciled against a real trial balance and lose.** The rename implements the design rather than departing from it, and `design_slot = 'mart_trial_balance'` keeps the traceability.

> [!WARNING]
> **Not built**
>
> DDL: [06-finance-general-ledger.sql](../ddl/06-finance-general-ledger.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Mart (aggregate) |
| **Grain** | Legal entity × fiscal year × period × account × currency × **`includes_bbf` × `includes_pl_close`** |
| **Source** | [fact_gl_posting](fact_gl_posting.md) |
| **Clustering** | `CLUSTER BY (legal_entity_code, fiscal_year, fiscal_period)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-06** (the flags it aggregates on) |

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `legal_entity_code` | STRING | No | Fact | **PK** |
| `fiscal_year` | INT | No | Fact | **PK** |
| `fiscal_period` | INT | No | Fact | **PK.** Period 0 carries beginning-balance-forward |
| `fiscal_period_key` | BIGINT | Yes | Fact | FK to [dim_fiscal_calendar](dim_fiscal_calendar.md) |
| `account_key` | BIGINT | No | Fact | **PK.** FK to [dim_gl_account](dim_gl_account.md) |
| `account_index` | INT | Yes | Fact | `ACTINDX` as replicated |
| `currency_key` | BIGINT | Yes | Fact | **PK.** FK to [dim_currency](dim_currency.md). **Activity is summarised per currency; summing across currencies without translation is the most likely way to misuse this table** |
| `includes_bbf` | BOOLEAN | No | Derived | **PK.** Whether BBF rows are in this aggregate. **Part of the grain, not a footnote: the same account and period appears once with and once without** |
| `includes_pl_close` | BOOLEAN | No | Derived | **PK.** Same rule for P&L close rows |
| `debit_amount` | DECIMAL(19,5) | Yes | `sum(DEBITAMT)` | |
| `credit_amount` | DECIMAL(19,5) | Yes | `sum(CRDTAMNT)` | |
| `net_activity_amount` | DECIMAL(19,5) | Yes | `sum(net_amount)` | **Net period activity — not an ending balance and not a trial balance.** There is no replicated opening balance to add to it |
| `posting_line_count` | BIGINT | Yes | `count(*)` | Present so a suspicious figure can be traced to a row count **before anyone reruns the source query** |
| `source_system` | STRING | No | Literal | `GP` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_mart_account_period_activity PRIMARY KEY (legal_entity_code, fiscal_year, fiscal_period, account_key, currency_key, includes_bbf, includes_pl_close)`; `fk_activity_account FOREIGN KEY (account_key) REFERENCES finance.general_ledger.dim_gl_account`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `grain` | `legal_entity_x_year_x_period_x_account_x_currency` | |
| `is_not_a_trial_balance` | `true` | Stated on the object, not just in a comment |
| `design_slot` | `mart_trial_balance` | Traceability back to the design doc's slot name |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_gl_account](dim_gl_account.md) | `m.account_key = a.account_key` | N:1 | Declared FK |
| [dim_fiscal_calendar](dim_fiscal_calendar.md) | `m.fiscal_period_key = dfc.fiscal_period_key` | N:1 | Filter `period_level = 'period'` |
| [dim_currency](dim_currency.md) | `m.currency_key = c.currency_key` | N:1 | |
| [dim_legal_entity](dim_legal_entity.md) | `m.legal_entity_code = le.legal_entity_code` | N:1 | No surrogate carried |
| [mart_plan_vs_actual](mart_plan_vs_actual.md) | This mart is its **actual** source | — | See below |
| [fact_gl_posting](fact_gl_posting.md) | This mart's source | — | Drill-down, not a join |

### Every query must pin the two flag columns

The flags are **in the primary key**, so each account/period/currency appears up to **four** times — one row per combination of `includes_bbf` and `includes_pl_close`.

```sql
-- RIGHT: activity reporting
WHERE NOT includes_bbf AND NOT includes_pl_close

-- RIGHT: audit extract
WHERE includes_bbf AND includes_pl_close

-- WRONG: sums up to four overlapping aggregates of the same postings
SELECT account_key, sum(net_activity_amount) FROM ... GROUP BY 1
```

The wrong version returns a number roughly two to four times too large, with correct-looking sign and correct-looking account detail. Nothing in the result indicates the duplication. **This is the single most likely misuse of this table** and the reason the flags were put in the key rather than exposed as separate columns to filter.

### And pin the currency

```sql
-- WRONG: adds CAD to USD as if they were the same unit
SELECT fiscal_period, sum(net_activity_amount) FROM ... GROUP BY 1

-- RIGHT: either group by currency
GROUP BY fiscal_period, currency_key
-- or translate through fact_exchange_rate first, then sum
```

Both traps compose: a query that pins neither can be off by a factor of four *and* mixing currencies.

### Drilling from this mart to the postings behind it

`posting_line_count` is the first check — if it looks wrong, the aggregate is wrong, and no drill is needed:

```sql
SELECT * FROM finance.general_ledger.fact_gl_posting
WHERE  legal_entity_code = :e AND fiscal_year = :y AND fiscal_period = :p
  AND  account_key = :a AND currency_key = :c
  AND  NOT is_beginning_balance_forward AND NOT is_profit_loss_close   -- match the flags
```

The flag predicates must match the mart row's flags or the drill returns a different population than the aggregate summarised.

## Gotchas

- **No opening balance exists.** Any request for a balance sheet or an ending balance from this table cannot be met from the current replica — it needs GP's summary tables added to the Fivetran connector.
- **Period 0 is BBF**, so `includes_bbf = false` rows for period 0 will be near-empty rather than absent.
- **The mart inherits T-06.** If the `SOURCDOC` derivation is wrong, the flags are wrong, and because they are in the key, every row is in the wrong bucket rather than merely mislabelled.
- **[mart_plan_vs_actual](mart_plan_vs_actual.md) sources its actuals from here, not from the fact**, so the two products **agree by construction.** A change to this mart's aggregation changes plan-vs-actual too.
