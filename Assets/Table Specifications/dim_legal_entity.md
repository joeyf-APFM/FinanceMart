---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.reference.dim_legal_entity

> [!warning] Not built
> DDL: [04-finance-reference.sql](../ddl/04-finance-reference.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Dimension |
| **Grain** | One GP company |
| **Source** | `main.prod_gp_dynamics_dbo_live.sy01500` — the **system** database company list is authoritative, not the per-company copies |
| **Members** | Two real: `APFM`, `CAPFM`. Plus −1/−2/−3 |
| **Readers** | `finance-analysts` |

## The correction this table records

Elsewhere the company account segment has been described as degenerate, and that reading has been over-applied. Both halves are true and they are about different things:

- **The GL company account segment is degenerate *within* APFM.** It is `10` on **100% of APFM GL activity — all 8,204,550 rows, FY2000–2026**. No hierarchy should ever be built on it.
- **APFM and CAPFM are two replicated companies and therefore two legal entities.** The dimension is real at catalog level even though the segment carries no information inside one company.

Which is why `legal_entity_code` is stamped on **every row of every fact in this catalog** and is a component of nearly every surrogate key — while `dim_gl_account` deliberately does not build a company rollup out of segment 1.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `legal_entity_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code)`. Reserved members −1/−2/−3 |
| `legal_entity_code` | STRING | Yes | Derived | `APFM` or `CAPFM`. Null on reserved members |
| `gp_company_id` | INT | Yes | `SY01500.CMPANYID` | |
| `gp_interid` | STRING | Yes | `SY01500.INTERID` | The GP company **database** name — what ties a row back to `prod_gp_apfm_dbo` vs `prod_gp_capfm_dbo` |
| `company_name` | STRING | Yes | `SY01500.CMPNYNAM` | |
| `country_code` | STRING | Yes | `SY01500.CMPCNTRY` | **CAPFM being Canadian is what makes multicurrency load-bearing rather than optional** |
| `location_id` | STRING | Yes | `SY01500.LOCATNID` | |
| `account_segment_separator` | STRING | Yes | `SY01500.ACSEGSEP` | Needed to render a formatted account number. **Do not hardcode a hyphen** |
| `functional_currency_key` | BIGINT | Yes | Derived | FK to [dim_currency](dim_currency.md). The **denominator for every unconverted amount** in that entity's facts |
| `gp_created_date` | DATE | Yes | `SY01500.CREATDDT` | |
| `gp_modified_date` | DATE | Yes | `SY01500.MODIFDT` | |
| `is_reserved_member` | BOOLEAN | No | Derived | |
| `source_system` | STRING | No | Literal | `GP`, or `SEED` |
| `source_table` | STRING | Yes | Literal | |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_dim_legal_entity PRIMARY KEY (legal_entity_key)`; `fk_legal_entity_currency FOREIGN KEY (functional_currency_key) REFERENCES finance.reference.dim_currency`.

No `SET TAGS` statement in the DDL for this table.

## Recommended joins

Almost everything in the catalog carries `legal_entity_code`, and most also carry `legal_entity_key`.

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_currency](dim_currency.md) | `le.functional_currency_key = c.currency_key` | N:1 | |
| [dim_customer](dim_customer.md) | `dc.legal_entity_key = le.legal_entity_key` | 1:N | Declared FK |
| [fact_gl_posting](fact_gl_posting.md), [fact_gl_posting_work](fact_gl_posting_work.md) | `f.legal_entity_key = le.legal_entity_key` | 1:N | Declared FK on the posted fact |
| [fact_ar_transaction](fact_ar_transaction.md), [fact_ar_apply](fact_ar_apply.md) | `f.legal_entity_key = le.legal_entity_key` | 1:N | |
| [dim_gl_account](dim_gl_account.md) | `da.legal_entity_key = le.legal_entity_key` | 1:N | |
| Everything else | `x.legal_entity_code = le.legal_entity_code` | N:1 | The string code is present even where the surrogate is not — e.g. [snap_period_close_daily](snap_period_close_daily.md), [mart_ar_aging](mart_ar_aging.md), [fact_plan_amount](fact_plan_amount.md) |

### `legal_entity_code` is part of the natural key of nearly everything

Not decoration. `ACTINDX`, `CUSTNMBR`, `JRNENTRY` and `BUDGETID` are all **company-scoped** in GP: the same `CUSTNMBR` in APFM and CAPFM is not necessarily the same counterparty. Any natural-key join across these tables must include the entity:

```sql
-- RIGHT
JOIN ... ON  a.legal_entity_code  = b.legal_entity_code
        AND  trim(a.gp_customer_number) = trim(b.gp_customer_number)

-- WRONG: collides APFM and CAPFM customers that share a number
JOIN ... ON  trim(a.gp_customer_number) = trim(b.gp_customer_number)
```

The surrogate keys already encode this — `customer_key` is `xxhash64(legal_entity_code, gp_customer_number)` — so joining on the surrogate is safe by construction. The hazard is only in natural-key joins, which is where the guarded replica views get used directly.

### Rendering an account number

`account_segment_separator` is the reason a formatted account number is assembled rather than hardcoded:

```sql
concat_ws(le.account_segment_separator, a.segment_1, a.segment_2, a.segment_3, ...)
```

[dim_gl_account](dim_gl_account.md) carries `formatted_account_number` already assembled; this column exists for anything building its own.

## Gotchas

- **Two entities, not one.** Any total that silently omits CAPFM is wrong in a way nothing in the data will flag.
- **Do not build a hierarchy on GL segment 1.** It is 10 on every APFM row.
- **`gp_interid`, not `legal_entity_code`, is what maps to a replica schema name.** Useful when tracing a figure back to `prod_gp_*_dbo_live`.
