---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.general_ledger.dim_gl_account

> [!warning] Not built
> DDL: [06-finance-general-ledger.sql](../ddl/06-finance-general-ledger.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Dimension |
| **Grain** | One GP account index (`ACTINDX`) **per legal entity** |
| **Sources** | `GL00100` (account master), `GL00102` (category descriptions), `GL40200` (segment value descriptions), `SY00300` (account format) |
| **History** | Type 1 — the replica carries current state only |
| **Clustering** | `CLUSTER BY (legal_entity_code, account_number)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-13** (`SGMTNUMB` count, `MNSEGIND` position) |

## It substitutes for a table that is not replicated

**`GL00105`, the Account Index Master, is not replicated.** Where a join would normally go through it, this dimension is the substitute. Recorded on the object as `substitutes_for_unreplicated = 'GL00105'` so the absence is discoverable rather than folklore.

## The segment layout is verifiable, not assumed

`SY00300` carries `SGMTNUMB`, `SGMTNAME`, `LOFSGMNT`, `MXLENSEG` and `SegmentWidth`, so **the number of segments actually in use, their names and their lengths are readable from the replica.**

`GL00100` physically has five `ACTNUMBR` columns whether or not five are in use. **Do not infer the count from the column list** — read `segments_in_use`. A pipeline that hardcodes five keeps working right up until the account format changes.

Segment names are **denormalised from `SY00300` onto every account row on purpose**: a Genie agent answers far better against a flat named column than against a join it has to discover.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `account_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, account_index)`. **Legal entity is in the key** — the same `ACTINDX` in APFM and CAPFM is a different account. Reserved members −1/−2/−3 |
| `legal_entity_code` | STRING | Yes | Derived | Null on reserved members |
| `legal_entity_key` | BIGINT | Yes | Derived | FK to [dim_legal_entity](dim_legal_entity.md) |
| `account_index` | INT | Yes | `GL00100.ACTINDX` | **The column every GL fact actually carries** |
| `account_number` | STRING | Yes | Derived | Formatted, segments joined with `SY01500.ACSEGSEP`. **Do not hardcode a hyphen** |
| `account_alias` | STRING | Yes | `GL00100.ACTALIAS` | |
| `account_description` | STRING | Yes | `GL00100.ACTDESCR` | |
| `segments_in_use` | INT | Yes | `SY00300` | **Read this rather than assuming five** |
| `segment_1_code` | STRING | Yes | `GL00100.ACTNUMBR_1` | |
| `segment_1_name` | STRING | Yes | `SY00300.SGMTNAME` | For APFM this is the **Company** segment — `10` on 100% of activity, degenerate within the entity. **Build no hierarchy on it** |
| `segment_1_description` | STRING | Yes | `GL40200.DSCRIPTN` | For segment 1's value |
| `segment_2_code` … `segment_5_code` | STRING | Yes | `GL00100.ACTNUMBR_2..5` | |
| `segment_2_name` … `segment_5_name` | STRING | Yes | `SY00300.SGMTNAME` | |
| `segment_2_description` … `segment_5_description` | STRING | Yes | `GL40200.DSCRIPTN` | |
| `main_account_segment` | STRING | Yes | `GL00100.MNACSGMT` | The natural account. **`SY00300.MNSEGIND` identifies which position is the main segment — read it rather than assuming a position** |
| `account_type` | INT | Yes | `GL00100.ACCTTYPE` | Coded; decode from the GP reference value lists |
| `posting_type` | INT | Yes | `GL00100.PSTNGTYP` | Balance-sheet vs P&L. **Determines whether a year-end close zeroes the account**, so it drives the P/L close exclusion on the fact |
| `typical_balance` | INT | Yes | `GL00100.TPCLBLNC` | Debit or credit. Needed to present a signed amount without guessing |
| `account_category_number` | INT | Yes | `GL00100.ACCATNUM` | The rollup level used by [mart_period_summary](mart_period_summary.md) |
| `account_category_description` | STRING | Yes | `GL00102.ACCATDSC` | |
| `fixed_or_variable` | INT | Yes | `GL00100.FXDORVAR` | |
| `decimal_places` | INT | Yes | `GL00100.DECPLACS` | One-based offset, same caveat as [dim_currency](dim_currency.md) |
| `is_active` | BOOLEAN | Yes | `GL00100.ACTIVE` | |
| `allows_account_entry` | BOOLEAN | Yes | `GL00100.ACCTENTR` | |
| `user_defined_1` | STRING | Yes | `GL00100.USERDEF1` | Semantics an open decision in the epic |
| `user_defined_2` | STRING | Yes | `GL00100.USERDEF2` | Same caveat |
| `gp_created_date` | DATE | Yes | `GL00100.CREATDDT` | Blank-date sentinel → NULL |
| `gp_modified_date` | DATE | Yes | `GL00100.MODIFDT` | |
| `is_reserved_member` | BOOLEAN | No | Derived | |
| `history_type` | STRING | No | Literal | Always `type_1` |
| `source_system` | STRING | No | Literal | `GP`, or `SEED` |
| `source_table` | STRING | Yes | Literal | The tables the row was **assembled** from |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_dim_gl_account PRIMARY KEY (account_key)`; `fk_gl_account_legal_entity FOREIGN KEY (legal_entity_key) REFERENCES finance.reference.dim_legal_entity`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `history_type` | `type_1` | |
| `grain` | `legal_entity_x_account_index` | |
| `substitutes_for_unreplicated` | `GL00105` | The Account Index Master is not in the replica |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_legal_entity](dim_legal_entity.md) | `da.legal_entity_key = le.legal_entity_key` | N:1 | Declared FK. Also the source of `account_segment_separator` |
| [fact_gl_posting](fact_gl_posting.md) | `f.account_key = da.account_key` | 1:N | Declared FK. **The primary GL join** |
| [fact_gl_posting_work](fact_gl_posting_work.md) | `f.account_key = da.account_key` | 1:N | Declared FK |
| [mart_account_period_activity](mart_account_period_activity.md) | `m.account_key = da.account_key` | 1:N | Declared FK |
| [fact_plan_amount](fact_plan_amount.md) | `f.account_key = da.account_key` | 1:N | Plan and actual meet at the account |
| [fact_plan_adjustment](fact_plan_adjustment.md) | `f.account_key = da.account_key` | 1:N | |
| [mart_plan_vs_actual](mart_plan_vs_actual.md) | `m.account_key = da.account_key` | 1:N | |
| [fact_invoice_line](fact_invoice_line.md) | `f.sales_account_index` + `legal_entity_code` | N:1 | **No surrogate on the fact.** See below |
| [mart_period_summary](mart_period_summary.md) | `account_category_number` | N:M | **Not an account-grain join.** See below |

### Joining from a raw account index

Where a fact carries `ACTINDX` but no `account_key` — [fact_invoice_line](fact_invoice_line.md)'s `sales_account_index` is the case in this catalog — the entity must be in the join:

```sql
-- RIGHT
JOIN finance.general_ledger.dim_gl_account a
  ON  a.legal_entity_code = f.legal_entity_code
  AND a.account_index     = f.sales_account_index

-- WRONG: ACTINDX is company-scoped; this collides APFM and CAPFM accounts
JOIN ... ON a.account_index = f.sales_account_index
```

### `mart_period_summary` is not an account-grain join

That mart rolls up on `account_category_number`, deliberately, so it is a summary rather than a second copy of [mart_account_period_activity](mart_account_period_activity.md). Joining it to this dimension on `account_key` is impossible; joining on `account_category_number` fans out to every account in the category. Use the category description already carried on the mart.

### Two segment traps

- **Do not group by `segment_1_code`.** It is `10` on 100% of APFM activity, so the grouping returns one row and looks like a working filter.
- **Do not assume the main segment's position.** `MNSEGIND` says which it is. `main_account_segment` is carried already resolved for exactly this reason — use it rather than picking `segment_2_code` because it happened to look right.

## Gotchas

- **`segments_in_use` may be fewer than five, and the unused segment columns will still hold values.** Padding, blanks, or stale content — none of it meaningful. Read `segments_in_use` before rendering.
- **Type 1.** An account renamed last year shows its current description on every historical posting.
- **`posting_type` drives the close flags on the fact,** so a mis-decoded posting type propagates into `is_profit_loss_close` and from there into both GL marts.
