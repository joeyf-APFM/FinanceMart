---
tags:
  - finance
  - semantic-layer
  - table-spec
  - pii
created: 2026-09-09
updated: 2026-09-09
---

# finance.identity.dim_customer

> [!danger] PII-bearing, restricted schema
> Names, addresses, phone, fax, bank name and branch, tax registration number. `finance.identity` is granted to `finance-pii-readers` **only**. Masking is deferred to a later phase by decision — that decision is about today's audience and holds only as long as the audience does.

> [!warning] Not built
> DDL: [[../ddl/05-finance-identity.sql|05-finance-identity.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Dimension |
| **Grain** | One GP customer = **one billing account.** Not one partner, not one family |
| **Source** | `rm00101`, both companies |
| **History** | **Type 1, overwriting — not a choice.** See below |
| **Clustering** | `CLUSTER BY (legal_entity_code, gp_customer_number)` |
| **Readers** | `finance-pii-readers` |

## What the grain is not

GP's "customer" is **who APFM bills**. `great_plains_customer_mapping` resolves it at `business_unit_id` grain — a community. `dim_partner` is the conformed commercial counterparty in the shared design, so `dim_customer` is the **billing-account view of a partner** and bridges to `dim_partner` rather than competing with it. The tag `not_a_partner_master = 'true'` says so on the object, because the name will otherwise imply the opposite.

[[bridge_customer_to_business_unit]] is the evidence: one GP customer can bill for several communities, and a community can change which customer bills it.

**Open question for Finance:** whether any GP customers are families or private-pay individuals. That would change the grain rather than the label.

## Why Type 1 is forced

Fivetran replicates `RM00101` as **current state**, so no prior version of a customer attribute exists to preserve. Type 1 is not a modelling preference here — there is nothing else available. If Finance needs Type 2 on any attribute, that requires either CDC on the connector or a daily snapshot, and **it can only start collecting from the day it is built.** `history_type` is carried as a data column, `'type_1'`, so a consumer sees it without reading a note.

## Deliberately not carried

`RM00101.CRCRDNUM` (credit card number), `CCRDXPDT` (expiry), `CRCARDID`. Propagating a card number into a mart is a payment-card exposure **independent of the decision to defer masking**, and no use case in the epic needs it. If one appears it needs its own review, not a column added here quietly. Recorded on the object as `excludes_source_columns = 'CRCRDNUM,CCRDXPDT,CRCARDID'`.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `customer_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, gp_customer_number)`. **Legal entity is in the key** because GP customer numbers are company-scoped — the same `CUSTNMBR` in APFM and CAPFM is not necessarily the same counterparty. Reserved members −1/−2/−3 |
| `legal_entity_code` | STRING | Yes | Derived | Null on reserved members |
| `legal_entity_key` | BIGINT | Yes | Derived | FK to [[dim_legal_entity]] |
| `gp_customer_number` | STRING | Yes | `RM00101.CUSTNMBR` | **Trim before joining** — an untrimmed join to `ipr` or the YGL mapping silently returns nothing |
| `parent_customer_number` | STRING | Yes | `RM00101.CPRCSTNM` | GP's parent/corporate customer — the closest thing GP has to a partner rollup. **Reconcile against `dim_partner` rather than using as a hierarchy on its own** |
| `customer_name` | STRING | Yes | `RM00101.CUSTNAME` | PII |
| `statement_name` | STRING | Yes | `RM00101.STMTNAME` | PII |
| `short_name` | STRING | Yes | `RM00101.SHRTNAME` | PII |
| `contact_person` | STRING | Yes | `RM00101.CNTCPRSN` | PII — a named individual |
| `customer_class` | STRING | Yes | `RM00101.CUSTCLAS` | **Confirm with Finance what the classes mean before exposing to a Genie agent** — an undocumented class code invites a confident wrong answer |
| `address_line_1` | STRING | Yes | `RM00101.ADDRESS1` | PII |
| `address_line_2` | STRING | Yes | `RM00101.ADDRESS2` | PII |
| `address_line_3` | STRING | Yes | `RM00101.ADDRESS3` | PII |
| `city` | STRING | Yes | `RM00101.CITY` | |
| `state_province` | STRING | Yes | `RM00101.STATE` | |
| `postal_code` | STRING | Yes | `RM00101.ZIP` | |
| `country` | STRING | Yes | `RM00101.COUNTRY` | |
| `phone_1` | STRING | Yes | `RM00101.PHONE1` | PII |
| `phone_2` | STRING | Yes | `RM00101.PHONE2` | PII |
| `fax` | STRING | Yes | `RM00101.FAX` | PII |
| `bank_name` | STRING | Yes | `RM00101.BANKNAME` | Financial PII. **Carried because collections work needs it; a candidate for the first mask** |
| `bank_branch` | STRING | Yes | `RM00101.BNKBRNCH` | Financial PII |
| `tax_registration_number` | STRING | Yes | `RM00101.TXRGNNUM` | Tax identifier. Financial PII |
| `currency_key` | BIGINT | Yes | `RM00101.CURNCYID` | FK to [[dim_currency]] |
| `payment_terms_id` | STRING | Yes | `RM00101.PYMTRMID` | |
| `salesperson_id` | STRING | Yes | `RM00101.SLPRSNID` | |
| `sales_territory` | STRING | Yes | `RM00101.SALSTERR` | |
| `credit_limit_type` | INT | Yes | `RM00101.CRLMTTYP` | Coded — **decode against the value lists in the GP reference rather than guessing** |
| `credit_limit_amount` | DECIMAL(19,5) | Yes | `RM00101.CRLMTAMT` | |
| `balance_type` | INT | Yes | `RM00101.BALNCTYP` | Balance-forward vs open-item. **This changes how the apply trail behaves and therefore how aging must be computed** |
| `statement_cycle` | INT | Yes | `RM00101.STMTCYCL` | |
| `is_on_hold` | BOOLEAN | Yes | `RM00101.HOLD` | |
| `is_inactive` | BOOLEAN | Yes | `RM00101.INACTIVE` | |
| `first_invoice_date` | DATE | Yes | `RM00101.FRSTINDT` | Blank-date sentinel → NULL |
| `user_defined_1` | STRING | Yes | `RM00101.USERDEF1` | Semantics are an open decision in the epic — **do not surface to a Genie agent until Finance says what it holds** |
| `user_defined_2` | STRING | Yes | `RM00101.USERDEF2` | Same caveat |
| `gp_created_date` | DATE | Yes | `RM00101.CREATDDT` | |
| `gp_modified_date` | DATE | Yes | `RM00101.MODIFDT` | |
| `partner_key` | BIGINT | Yes | Derived | Intended FK to the conformed `dim_partner`, **which does not exist yet — left nullable and WITHOUT a foreign-key constraint until it does.** Present now so the bridge is designed in rather than bolted on |
| `is_reserved_member` | BOOLEAN | No | Derived | |
| `history_type` | STRING | No | Literal | Always `type_1`. Stated as data, not documentation |
| `source_system` | STRING | No | Literal | `GP`, or `SEED` |
| `source_table` | STRING | Yes | Literal | |
| `_source_synced_at` | TIMESTAMP | Yes | `_fivetran_synced` | **NOT freshness** — advances only when the row changes |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_dim_customer PRIMARY KEY (customer_key)`; `fk_customer_legal_entity FOREIGN KEY (legal_entity_key) REFERENCES finance.reference.dim_legal_entity`; `fk_customer_currency FOREIGN KEY (currency_key) REFERENCES finance.reference.dim_currency`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `contains_pii` | `true` | |
| `history_type` | `type_1` | Forced by the source, not chosen |
| `grain` | `gp_billing_account` | |
| `not_a_partner_master` | `true` | The name will imply otherwise; the tag contradicts it |
| `excludes_source_columns` | `CRCRDNUM,CCRDXPDT,CRCARDID` | Payment-card columns |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_legal_entity]] | `dc.legal_entity_key = le.legal_entity_key` | N:1 | |
| [[dim_currency]] | `dc.currency_key = c.currency_key` | N:1 | |
| [[fact_ar_transaction]] | `f.customer_key = dc.customer_key` | 1:N | The primary AR join |
| [[fact_ar_apply]] | `f.customer_key = dc.customer_key` | 1:N | |
| [[mart_ar_aging]], [[mart_writeoff]] | `m.customer_key = dc.customer_key` | 1:N | |
| [[dim_collections_attributes]] | `dc.customer_key = dca.customer_key` | 1:0..1 | **`LEFT JOIN` only** — the satellite exists per CN00500 record, not per customer |
| [[fact_referral_charge]] | `f.customer_key = dc.customer_key` | 1:N | **`LEFT JOIN`** from the fact — a null `customer_key` there is the unbilled-move-in population |
| [[bridge_customer_to_family]] | `b.customer_key = dc.customer_key` | 1:N | **Many-to-many. Fan-out** |
| [[bridge_customer_to_salesforce]] | `b.customer_key = dc.customer_key` | 1:N | **Many-to-many. Fan-out**, 22.19% match |
| [[bridge_customer_to_business_unit]] | `b.customer_key = dc.customer_key` + effective-date predicate | 1:N | **Many-to-many, effective-dated** |
| `dim_partner` | `dc.partner_key = dp.partner_key` | N:1 | **Does not exist yet.** No FK declared |

### Joining a customer to itself: the parent rollup

`parent_customer_number` invites a self-join, and it is a company-scoped natural key, so the entity has to be in it:

```sql
LEFT JOIN finance.identity.dim_customer parent
       ON  parent.legal_entity_code       =  child.legal_entity_code
       AND trim(parent.gp_customer_number) = trim(child.parent_customer_number)
```

But treat the result as a **candidate** rollup to reconcile against `dim_partner`, not as the partner hierarchy. GP's parent field is maintained by whoever set the customer up.

### The three bridges cannot be joined together

Chaining [[bridge_customer_to_family]] to [[bridge_customer_to_salesforce]] through `customer_key` multiplies the fan-out of both. A customer with 3 families and 2 Salesforce ids yields 6 rows. If a query needs both, aggregate each bridge to one row per customer first.

## Gotchas

- **A credit limit is not PII, but it lives here.** `credit_limit_amount`, `balance_type` and `statement_cycle` are non-PII policy attributes sitting in a PII-restricted schema, so a collections analyst needs a PII grant to read a credit limit. See [[../Collections in the Finance Catalog|Collections in the Finance Catalog]] — the proposed fix is a projection view in `finance.receivables`, not moving columns.
- **Keep Genie agents pointed at the marts, not here.** Column masks on `RM00101` disable entity matching, so an agent tuned against an unmasked `dim_customer` is invalidated the day masking arrives.
- **`_source_synced_at` is not freshness.**
- **Type 1 means yesterday's credit limit is gone.** Any question about *when* a limit changed is unanswerable and will stay unanswerable until a snapshot starts collecting.
