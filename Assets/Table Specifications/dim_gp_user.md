---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.reference.dim_gp_user

> [!warning] Not built
> DDL: [04-finance-reference.sql](../ddl/04-finance-reference.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).

| | |
|---|---|
| **Type** | Dimension, role-playing |
| **Grain** | One Dynamics GP user |
| **Source** | `main.prod_gp_dynamics_dbo_live.sy01400` — the system user list is authoritative; the per-company copies record company *access* |
| **Readers** | `finance-analysts` |

## Why it exists

**`SY01400` carries a `PASSWORD` column.** This dimension is a projection that excludes it, and the exclusion is the entire reason the table exists rather than consumers reading `sy01400` directly. `PASSWORD`, the UI colour preferences, and the browser fields are all deliberately not carried.

The tag `excludes_source_columns = 'PASSWORD'` states that on the object. `contains_employee_names = 'true'` flags the other sensitivity: `USERNAME` is a person's name — **internal-employee data, not customer PII**, which is why this table sits in `finance.reference` and not in `finance.identity`.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `gp_user_key` | BIGINT | No | Derived | PK. `xxhash64(gp_user_id)`. Reserved members −1/−2/−3 |
| `gp_user_id` | STRING | Yes | `SY01400.USERID` | The value that appears in `LASTUSER`, `USWHPSTD`, `PSTUSRID`, `LSTUSRED` across the GP tables. **Trim before joining** |
| `user_name` | STRING | Yes | `SY01400.USERNAME` | A person's name. Internal-employee data |
| `user_class` | STRING | Yes | `SY01400.USRCLASS` | |
| `user_role` | STRING | Yes | `SY01400.UserRole` | |
| `user_type` | STRING | Yes | `SY01400.UserType` | |
| `user_status` | STRING | Yes | `SY01400.UserStatus` | |
| `date_inactivated` | DATE | Yes | `SY01400.DateInactivated` | Blank-date sentinel → NULL |
| `gp_created_date` | DATE | Yes | `SY01400.CREATDDT` | |
| `gp_modified_date` | DATE | Yes | `SY01400.MODIFDT` | |
| `is_reserved_member` | BOOLEAN | No | Derived | |
| `source_system` | STRING | No | Literal | `GP`, or `SEED` |
| `source_table` | STRING | Yes | Literal | |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraint:** `pk_dim_gp_user PRIMARY KEY (gp_user_key)`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `excludes_source_columns` | `PASSWORD` | The reason the table exists |
| `contains_employee_names` | `true` | Not customer PII, but not neutral either |

## Recommended joins

**This is a role-playing dimension** — the facts carry several user columns each and none of them carries a `gp_user_key`. Every join is on the trimmed id.

| Fact | User columns | GP source |
|---|---|---|
| [fact_gl_posting](fact_gl_posting.md) | `posted_by_user_id`, `last_modified_by_user_id`, `approval_user_id` | `USWHPSTD`, `LASTUSER`, `APPRVLDT`-paired approver |
| [fact_gl_posting_work](fact_gl_posting_work.md) | `posted_by_user_id`, `last_modified_by_user_id`, `approval_user_id` | same |
| [fact_ar_transaction](fact_ar_transaction.md) | `posted_by_user_id`, `last_edited_by_user_id` | `PSTUSRID`, `LSTUSRED` |
| [fact_ar_apply](fact_ar_apply.md) | `posted_by_user_id` | `PSTUSRID` |
| [fact_plan_adjustment](fact_plan_adjustment.md) | `posted_by_user_id`, `last_user_id` | |

### Join it once per role, under an alias

```sql
SELECT p.*, poster.user_name AS posted_by, editor.user_name AS last_modified_by
FROM   finance.general_ledger.fact_gl_posting p
LEFT JOIN finance.reference.dim_gp_user poster
       ON trim(poster.gp_user_id) = trim(p.posted_by_user_id)
LEFT JOIN finance.reference.dim_gp_user editor
       ON trim(editor.gp_user_id) = trim(p.last_modified_by_user_id)
```

Two things this gets right that a single join does not:

- **`LEFT JOIN`, always.** A user who has been deleted from `SY01400` still appears in `USWHPSTD` on historical postings. An inner join drops those postings entirely — losing *amounts* in order to resolve a *name*.
- **`trim()` on both sides.** `USERID` is a space-padded `char`. Untrimmed, the join returns nothing and the report shows every poster as unknown.

### There is no `gp_user_key` on any fact

Deliberate. Resolving the surrogate at load would mean either failing rows for unknown users or silently landing them on −1. The facts keep the raw id and the resolution happens at query time, where a null name is visibly a null name.

## Gotchas

- **`user_status` and `date_inactivated` describe the user now, not at posting time.** A posting made by someone since deactivated will show as inactive. That is not an error in the posting.
- **Never read `sy01400` directly.** Even through the guarded `*_live` view, it carries `PASSWORD`. That is the whole point of this table.
- **The `dynamics` system database is the source.** Per-company `sy01400` copies record which users can access which company, which is a different question.
