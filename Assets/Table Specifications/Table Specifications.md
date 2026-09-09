---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# Table Specifications

One note per table in the `finance` and `common` catalogs — columns, descriptions, table tags, and recommended joins. A level above [the DDL](../ddl/) and derived from it.

> [!WARNING]
> **Nothing here exists**
>
> All 28 tables are specifications. Every file under `ddl/` carries a `STATUS: NOT EXECUTED` banner and **no target workspace has been chosen**. See [Finance Catalog DDL](../Finance%20Catalog%20DDL.md) for build order, conventions, and the fourteen verification tests.

> [!NOTE]
> **The DDL is the artifact, these notes are the reading copy**
>
> Where a note and its `.sql` file disagree, the `.sql` file is right and the note is stale. The notes add one thing the DDL does not carry: **recommended joins**, including the fan-out and as-of hazards that a declared foreign key does not express.

## The 28 tables

### `common.calendar` — [03](../ddl/03-common-calendar.sql)

| Table | Type | Grain |
|---|---|---|
| [dim_date](dim_date.md) | Dimension | One calendar date. A **promotion**, not a new build |
| [dim_fiscal_calendar](dim_fiscal_calendar.md) | Dimension | Fiscal period × period level |
| [snap_period_close_daily](snap_period_close_daily.md) | Snapshot | Snapshot date × entity × year × period × **series** |

### `finance.reference` — [04](../ddl/04-finance-reference.sql)

| Table | Type | Grain |
|---|---|---|
| [dim_currency](dim_currency.md) | Dimension | Currency |
| [fact_exchange_rate](fact_exchange_rate.md) | Fact | Entity × rate table × currency × date × time |
| [dim_legal_entity](dim_legal_entity.md) | Dimension | GP company |
| [dim_gp_user](dim_gp_user.md) | Dimension | GP user |

### `finance.identity` — [05](../ddl/05-finance-identity.sql) · PII, restricted

| Table | Type | Grain |
|---|---|---|
| [dim_customer](dim_customer.md) | Dimension | GP billing account |
| [bridge_customer_to_family](bridge_customer_to_family.md) | Bridge | Customer × family file |
| [bridge_customer_to_salesforce](bridge_customer_to_salesforce.md) | Bridge | Customer × Salesforce id |
| [bridge_customer_to_business_unit](bridge_customer_to_business_unit.md) | Bridge | Customer × community, effective-dated |

### `finance.general_ledger` — [06](../ddl/06-finance-general-ledger.sql)

| Table | Type | Grain |
|---|---|---|
| [dim_gl_account](dim_gl_account.md) | Dimension | Entity × account index |
| [fact_gl_posting](fact_gl_posting.md) | Fact | Posted GL distribution line |
| [fact_gl_posting_work](fact_gl_posting_work.md) | Fact | Unposted GL distribution line |
| [mart_account_period_activity](mart_account_period_activity.md) | Mart | Entity × year × period × account × currency |
| [mart_period_summary](mart_period_summary.md) | Mart | Period × entity × category × as-of date |

### `finance.receivables` — [07](../ddl/07-finance-receivables.sql)

| Table | Type | Grain |
|---|---|---|
| [fact_ar_transaction](fact_ar_transaction.md) | Fact | AR document |
| [fact_ar_apply](fact_ar_apply.md) | Fact | Apply relationship — **this is the aging history** |
| [snap_ar_aging_daily](snap_ar_aging_daily.md) | Snapshot | Snapshot date × customer × document |
| [mart_ar_aging](mart_ar_aging.md) | Mart | As-of × entity × customer × bucket × currency × basis |
| [mart_writeoff](mart_writeoff.md) | Mart | Write-off event |
| [dim_collections_attributes](dim_collections_attributes.md) | Dimension | Customer **with a CN00500 record** |

### `finance.billing` — [08](../ddl/08-finance-billing.sql) · nothing here is revenue

| Table | Type | Grain |
|---|---|---|
| [fact_referral_charge](fact_referral_charge.md) | Fact | **Unconfirmed** — profile `ipr` first (T-10) |
| [fact_invoice_line](fact_invoice_line.md) | Fact | SOP document line, APFM only |
| [mart_billing_by_stream](mart_billing_by_stream.md) | Mart | Period × entity × stream × community |

### `finance.plan` — [09](../ddl/09-finance-plan.sql)

| Table | Type | Grain |
|---|---|---|
| [fact_plan_amount](fact_plan_amount.md) | Fact | Entity × budget × year × period × account |
| [fact_plan_adjustment](fact_plan_adjustment.md) | Fact | Plan adjustment line, posted and unposted |
| [mart_plan_vs_actual](mart_plan_vs_actual.md) | Mart | Entity × budget × period × account |

## Join hazards that no foreign key expresses

The single most useful thing in these notes. A declared FK in Unity Catalog is informational and non-enforced, and it says nothing about cardinality, fan-out, or whether the join is even an equijoin. Six patterns recur:

| Hazard | Where | What goes wrong |
|---|---|---|
| **Bridge fan-out** | [bridge_customer_to_family](bridge_customer_to_family.md), [bridge_customer_to_salesforce](bridge_customer_to_salesforce.md), [bridge_customer_to_business_unit](bridge_customer_to_business_unit.md) | All three are many-to-many. Joining a fact through one multiplies amount rows by the number of matches. Every measure must be de-duplicated or allocated |
| **As-of join, not equijoin** | [bridge_customer_to_business_unit](bridge_customer_to_business_unit.md), [fact_exchange_rate](fact_exchange_rate.md) | Effective-dated and time-keyed sources need `valid_from <= d AND (valid_to IS NULL OR valid_to > d)` or a latest-on-or-before window. An equijoin returns either nothing or every version |
| **Series fan-out** | [snap_period_close_daily](snap_period_close_daily.md) | The grain includes `series_id`. Joining without it multiplies rows by up to seven |
| **Flags in the grain** | [mart_account_period_activity](mart_account_period_activity.md), [mart_ar_aging](mart_ar_aging.md), [mart_plan_vs_actual](mart_plan_vs_actual.md) | `includes_bbf`, `includes_pl_close`, `computation_basis` are in the primary key. Not filtering them double counts, and the total looks plausible |
| **Role-playing dimensions** | [dim_gp_user](dim_gp_user.md), [dim_date](dim_date.md) | Facts carry several user columns and several date columns but only one `date_key`. Aging by due date, or naming both poster and approver, needs the dimension joined more than once under aliases |
| **Sparse satellite** | [dim_collections_attributes](dim_collections_attributes.md) | `LEFT JOIN` only. An inner join silently drops every customer with no CN00500 record, and the population rate is unprofiled |

## Trim before joining, always

Every GP `char` column is space-padded. `CUSTNMBR`, `ACTINDX` formatted values, `USERID`, `BUDGETID`, `EXGTBLID`, `SOPNUMBE` — an untrimmed join to the charging platform or the YGL mapping returns **nothing**, not fewer rows, and the failure looks like missing data rather than a bad join.

## Who can read what

From [10-grants.sql](../ddl/10-grants.sql). Group names are **unconfirmed placeholders** — verify against `databricks account groups list --profile account-apfm`.

| Schema | Read access |
|---|---|
| `common.calendar` | `` `account users` `` — a conformed calendar with a restricted grant is not conformed |
| `finance.reference`, `.general_ledger`, `.receivables`, `.billing`, `.plan` | `finance-analysts` |
| `finance.identity` | `finance-pii-readers` **only** |
| `main.prod_gp_*_dbo_live` | `finance-analysts` — the guarded views, so nobody reads the raw replica |
