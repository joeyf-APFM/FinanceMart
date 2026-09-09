---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.receivables.dim_collections_attributes

> [!warning] Not built
> DDL: [[../ddl/07-finance-receivables.sql|07-finance-receivables.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]] and [[../Collections in the Finance Catalog|Collections in the Finance Catalog]].

| | |
|---|---|
| **Type** | Dimension — a **satellite** on [[dim_customer]] |
| **Grain** | **One row per customer that has a `CN00500` record — not one per customer** |
| **Source** | `CN00500` (Collections Management add-on) |
| **History** | Type 1 — current state only from the replica |
| **Readers** | `finance-analysts` |

## Why a satellite and not columns on `dim_customer`

`CN00500` is a **Collections Management add-on** table that **may be sparsely populated**. Merging sparse add-on columns into the customer dimension makes it impossible to tell *"not set"* from *"module not used"*:

> **Absence of a row means no `CN00500` record exists, which is different from an attribute being blank** — a distinction that merging would destroy.

**Profile the population rate before building anything on top of this.** The [[../Collections in the Finance Catalog|collections placement note]] carries the query for that; it has not been run.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `customer_key` | BIGINT | No | Derived | **PK and FK to [[dim_customer]].** One row per customer *with a record* |
| `legal_entity_code` | STRING | No | Derived | APFM or CAPFM |
| `gp_customer_number` | STRING | No | `CN00500.CUSTNMBR` | Trimmed |
| `credit_manager_id` | STRING | Yes | `CN00500.CRDTMGR` | **Who owns the collections relationship** |
| `preferred_contact_method` | STRING | Yes | `CN00500.PreferredContactMethod` | |
| `no_mail_flag` | BOOLEAN | Yes | `CN00500.NOMAIL` | **A contact-preference suppression flag — respect it in any outbound collections process** |
| `address_code` | STRING | Yes | `CN00500.ADRSCODE` | |
| `time_zone` | STRING | Yes | `CN00500.Time_Zone` | |
| `credit_control_cycle` | STRING | Yes | `CN00500.CN_Credit_Control_Cycle` | |
| `user_table_01` | STRING | Yes | `CN00500.USRTAB01` | **Undocumented user field; profile before use** |
| `user_table_09` | STRING | Yes | `CN00500.USRTAB09` | Undocumented user field; profile before use |
| `user_defined_1` | STRING | Yes | `CN00500.USERDEF1` | **Distinct from `RM00101.USERDEF1` — do not conflate them** |
| `user_defined_2` | STRING | Yes | `CN00500.USERDEF2` | |
| `user_defined_date_1` | DATE | Yes | `CN00500.USRDAT01` | |
| `history_type` | STRING | No | Literal | Always `type_1` |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | e.g. `main.prod_gp_apfm_dbo_live.cn00500` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_dim_collections_attributes PRIMARY KEY (customer_key)`; `fk_collections_customer` → `finance.identity.dim_customer`. **No `SET TAGS` statement** — this is the only table in the receivables schema without one.

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_customer]] | `ca.customer_key = dc.customer_key` | 1:1 **partial** | Declared FK. **`LEFT JOIN` from the customer, always** |
| [[mart_ar_aging]] | `ca.customer_key = m.customer_key` | 1:N | `LEFT JOIN`. Aging plus who owns the relationship |
| [[mart_writeoff]] | `ca.customer_key = w.customer_key` | 1:N | `LEFT JOIN` |
| [[fact_ar_transaction]] | `ca.customer_key = f.customer_key` | 1:N | `LEFT JOIN` |
| [[bridge_customer_to_business_unit]] | via `customer_key`, as-of | 1:N | **Fan-out and as-of.** Collections attributes are billing-account grain, communities are not |

### `LEFT JOIN`, never `INNER JOIN` — and the whole point is the null

```sql
-- RIGHT
SELECT m.gp_customer_number, m.outstanding_amount, ca.credit_manager_id
FROM      finance.receivables.mart_ar_aging m
LEFT JOIN finance.receivables.dim_collections_attributes ca
       ON ca.customer_key = m.customer_key
WHERE  m.as_of_date = :d AND m.computation_basis = 'snapshot'

-- WRONG: silently restricts the whole aging report to customers in CN00500
JOIN finance.receivables.dim_collections_attributes ca ON ...
```

The wrong version does not error and returns a coherent, correctly-aged report — **of a subset of the receivable whose size nobody has measured.** If `CN00500` covers 10% of customers, the report shows 10% of the balance and looks fine.

### Three states, not two

```sql
CASE WHEN ca.customer_key IS NULL      THEN 'no CN00500 record'   -- module not used for them
     WHEN ca.credit_manager_id IS NULL THEN 'record, no manager'  -- record exists, not set
     ELSE ca.credit_manager_id END
```

This is the distinction the satellite exists to preserve. Collapsing it with `coalesce(ca.credit_manager_id, 'unassigned')` merges *"we do not use the module here"* with *"nobody has been assigned"* — two different problems with two different owners.

### Respect `no_mail_flag` in anything outbound

```sql
-- Any collections outreach list
WHERE coalesce(ca.no_mail_flag, false) = false
```

`coalesce` to `false` is correct **here specifically**: a customer with no `CN00500` record has expressed no suppression preference. It is the one place in this note where defaulting the null is right — and note that it makes an assumption about consent that should be confirmed with whoever owns the outreach process, not inferred from the schema.

## Gotchas

- **The population rate is unmeasured.** Every figure derived from this table is bounded by a number nobody has yet run the query for.
- **`credit_manager_id` is not a [[dim_gp_user]] key by declaration.** If it holds a GP user id, join `trim()`-to-`trim()`; if it holds free text, it does not join at all. Profile it.
- **`USRTAB01` and `USRTAB09` are undocumented and the numbering implies 02–08 exist and were not carried.** If a consumer needs one, add it deliberately rather than assuming the gap was an oversight.
- **Type 1.** A credit manager reassigned last month appears as the owner of every historical write-off.
- **`CN00500` is one of several CN tables.** The others — collections notes, activities, credit-control cycles — are covered in [[../Collections in the Finance Catalog|Collections in the Finance Catalog]] and are **not** in this DDL.
