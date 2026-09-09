---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.billing.fact_invoice_line

> [!danger] The document header is not replicated
> **`SOP30200`, the sales document HEADER history table, is not in the replica.** Only `sop30300` (line history) is. The consequence is not cosmetic: **there is no reliable document-level customer, document date, void status, or salesperson for an invoice.** Each of those absences is labelled on the columns below rather than left for a consumer to discover when a total comes out wrong.

> [!warning] Not built · APFM only
> DDL: [08-finance-billing.sql](../ddl/08-finance-billing.sql) · `STATUS: NOT EXECUTED`. See [Table Specifications](Table%20Specifications.md).
>
> `sop30300` is **absent from `prod_gp_capfm_dbo`**, so this fact covers **one legal entity**. Stamped in the table comment and in a tag, because *"a consumer comparing invoiced amounts across entities will otherwise read CAPFM's absence as zero."*

| | |
|---|---|
| **Type** | Fact |
| **Grain** | One `sop30300` document **line** (including kit components) |
| **Source** | `main.prod_gp_apfm_dbo_live.sop30300` — **real columns; `sop30300` is in the GP reference, all 119 of them** |
| **Measure class** | `operational_not_recognized` |
| **Clustering** | `CLUSTER BY (legal_entity_code, sop_number)` |
| **Readers** | `finance-analysts` |

## The IPR bridge is measured, not assumed

| Figure | Value |
|---|---|
| `ipr_invoice` rows whose `gp_invoice_num` matches a `sopnumbe` | **613,879 / 622,066 = 98.7%** |
| REF documents with an associated IPR row (the **end-to-end ceiling**) | **60.6%** |

**Both figures belong in the model**, and `is_ipr_matched` carries the second one as data so the ceiling is visible in every aggregate rather than living in a footnote.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `invoice_line_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, sop_type, sop_number, line_item_sequence, component_sequence)`. **`component_sequence` is in the key because `sop30300` uses it for kit components, and omitting it collapses distinct lines** |
| `legal_entity_code` | STRING | No | Literal | **APFM only** |
| `legal_entity_key` | BIGINT | Yes | Derived | FK to [dim_legal_entity](dim_legal_entity.md) |
| `sop_type` | INT | No | `SOPTYPE` | Quote, order, invoice, return, back order. **Filter to invoices explicitly — this table holds all types and a total across them is meaningless** |
| `sop_number` | STRING | No | `SOPNUMBE` | The document number, **and the join key to `ipr_invoice.gp_invoice_num`** |
| `line_item_sequence` | BIGINT | No | `LNITMSEQ` | |
| `component_sequence` | BIGINT | No | `CMPNTSEQ` | Non-zero for kit components |
| `customer_key` | BIGINT | Yes | **Resolved indirectly** | FK to [dim_customer](dim_customer.md). **`SOP30200` is not replicated and `sop30300` carries no `CUSTNMBR`.** Path: `sop_number` → `ipr_invoice.gp_invoice_num` → `ipr.fin_customer_id`. **Only as good as the IPR bridge — 98.7% / 60.6%** |
| `gp_customer_number` | STRING | Yes | Resolved as above | **Never present this as authoritative document-level customer; it is an inference from the charging platform** |
| `ship_to_name` | STRING | Yes | `ShipToName` | **PII.** The one name `sop30300` carries directly, and it is a **ship-to rather than a bill-to — NOT a substitute for the header customer** |
| `ship_to_address_code` | STRING | Yes | `PRSTADCD` | |
| `ship_to_city` | STRING | Yes | `CITY` | |
| `ship_to_state` | STRING | Yes | `STATE` | |
| `requested_ship_date` | DATE | Yes | `ReqShipDate` | Blank-date sentinel → NULL |
| `fulfilled_date` | DATE | Yes | `FUFILDAT` | |
| `actual_ship_date` | DATE | Yes | `ACTLSHIP` | **THE CLOSEST AVAILABLE PROXY FOR A DOCUMENT DATE, and it is a proxy** — the real document date is on `SOP30200`. **Label it as a ship date wherever it is surfaced. Do not silently present it as the invoice date** |
| `date_key` | INT | Yes | Derived on `actual_ship_date` | FK to [dim_date](dim_date.md), **with the proxy caveat above** |
| `item_number` | STRING | Yes | `ITEMNMBR` | |
| `item_description` | STRING | Yes | `ITEMDESC` | |
| `unit_of_measure` | STRING | Yes | `UOFM` | |
| `location_code` | STRING | Yes | `LOCNCODE` | |
| `quantity` | DECIMAL(19,5) | Yes | `QUANTITY` | |
| `unit_price` | DECIMAL(19,5) | Yes | `UNITPRCE` | |
| `extended_price` | DECIMAL(19,5) | Yes | `XTNDPRCE` | The line total, functional currency |
| `originating_extended_price` | DECIMAL(19,5) | Yes | `OXTNDPRC` | Originating currency |
| `unit_cost` | DECIMAL(19,5) | Yes | `UNITCOST` | |
| `extended_cost` | DECIMAL(19,5) | Yes | `EXTDCOST` | |
| `tax_amount` | DECIMAL(19,5) | Yes | `TAXAMNT` | |
| `trade_discount_amount` | DECIMAL(19,5) | Yes | `TRDISAMT` | |
| `markdown_amount` | DECIMAL(19,5) | Yes | `MRKDNAMT` | |
| `sales_account_index` | INT | Yes | `SLSINDX` | **How an invoice line ties to the account it credited.** Joins to [dim_gl_account](dim_gl_account.md) |
| `cost_of_sales_account_index` | INT | Yes | `CSLSINDX` | |
| `currency_index` | INT | Yes | `CURRNIDX` | |
| `currency_key` | BIGINT | Yes | Derived from `CURRNIDX` | FK to [dim_currency](dim_currency.md) |
| `decimal_places_currency` | INT | Yes | `DECPLCUR` | **A one-based offset, so 3 means 2 decimal places. Read it rather than assuming two** |
| `salesperson_id` | STRING | Yes | `SLPRSNID` | **Present at LINE level.** The document-level salesperson is on `SOP30200` and unavailable, **so a per-document salesperson has to be inferred from its lines and can disagree across them** |
| `sales_territory` | STRING | Yes | `SALSTERR` | |
| `price_level` | STRING | Yes | `PRCLEVEL` | |
| `trx_source` | STRING | Yes | `TRXSORCE` | Ties the line to the GL batch that posted it |
| `line_error_code` | INT | Yes | `SOPLNERR` | |
| `is_non_inventory` | BOOLEAN | Yes | `NONINVEN` | **Expected true for most APFM lines** — referral fees are not stocked goods |
| `void_status` | STRING | Yes | — | **DELIBERATELY NULL AND KEPT AS A COLUMN.** `sop30300` carries no void flag; void status is on `SOP30200`. *"The column exists so the gap is visible in the schema instead of being an unstated assumption that nothing here is voided"* |
| `referral_charge_key` | BIGINT | Yes | Derived | FK to [fact_referral_charge](fact_referral_charge.md) where matched |
| `is_ipr_matched` | BOOLEAN | No | Derived | Whether this line's document appears in `ipr_invoice`. **Carried as data so the ceiling is visible in every aggregate** |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | `main.prod_gp_apfm_dbo_live.sop30300` |
| `_source_synced_at` | TIMESTAMP | Yes | `_fivetran_synced` | **NOT freshness** |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_invoice_line PRIMARY KEY (invoice_line_key)`; FKs to `dim_customer`, `dim_currency`, `fact_referral_charge`.

## Table tags

| Tag | Value | Meaning |
|---|---|---|
| `measure_class` | `operational_not_recognized` | |
| `grain` | `sop_document_line` | |
| `covers_legal_entities` | `APFM` | **So CAPFM's absence cannot be read as zero** |
| `missing_header_table` | `SOP30200` | The gap is discoverable from the object |
| `ipr_bridge_rate` | `0.987` | |
| `ref_with_ipr_rate` | `0.606` | The end-to-end ceiling |

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [dim_customer](dim_customer.md) | `il.customer_key = dc.customer_key` | N:1 | Declared FK. **`LEFT JOIN` — the resolution is an inference with a 60.6% ceiling** |
| [fact_referral_charge](fact_referral_charge.md) | `il.referral_charge_key = rc.referral_charge_key` | N:1 | Declared FK. `LEFT JOIN` |
| [dim_currency](dim_currency.md) | `il.currency_key = c.currency_key` | N:1 | Declared FK |
| [dim_gl_account](dim_gl_account.md) | `a.legal_entity_code = il.legal_entity_code AND a.account_index = il.sales_account_index` | N:1 | **No surrogate on this fact — natural-key join, entity included** |
| [dim_date](dim_date.md) | `il.date_key = d.date_key` | N:1 | **On a ship-date proxy.** Label it as such |
| [dim_legal_entity](dim_legal_entity.md) | `il.legal_entity_key = le.legal_entity_key` | N:1 | Always APFM |
| [fact_gl_posting](fact_gl_posting.md) | `trim(g.trx_source) = trim(il.trx_source)` + entity | N:M | The subledger tie |
| [mart_billing_by_stream](mart_billing_by_stream.md) | This fact is one of its two sources | — | Aggregate |
| [fact_ar_transaction](fact_ar_transaction.md) | via `sop_number` ↔ `document_number` | N:1 | **Unverified.** Profile before relying on it |

### Filter `sop_type` before anything else

```sql
-- RIGHT
WHERE sop_type = :invoice_type    -- decode from the GP reference; do not hardcode a guess

-- WRONG: sums quotes, orders, invoices, returns and back orders together
SELECT sum(extended_price) FROM finance.billing.fact_invoice_line
```

The wrong version adds quotes — documents that were never billed — to invoices, and nets returns against them at a different grain. There is no default filter and no view that applies one.

### Never call `actual_ship_date` the invoice date

```sql
-- RIGHT: label it honestly
SELECT date_trunc('month', actual_ship_date) AS ship_month, sum(extended_price)

-- WRONG: it is a proxy, and a report column called invoice_month is a claim
SELECT date_trunc('month', actual_ship_date) AS invoice_month, ...
```

The values may be perfectly usable. The problem is the label: once a column is called `invoice_month`, someone reconciles it to a GP invoice register and the discrepancy gets attributed to the pipeline rather than to the missing header table.

### The salesperson is a line attribute, and lines can disagree

```sql
-- Detect the disagreement before reporting a per-document salesperson
SELECT sop_number, count(DISTINCT trim(salesperson_id)) AS distinct_salespeople
FROM   finance.billing.fact_invoice_line
WHERE  sop_type = :invoice_type
GROUP BY 1
HAVING count(DISTINCT trim(salesperson_id)) > 1
```

If that returns rows, any per-document salesperson is a choice — `max()`, the first line, the largest line — and the choice must be stated. `SOP30200` would have settled it and is not there.

### `is_ipr_matched` belongs in every aggregate

```sql
SELECT date_trunc('month', actual_ship_date) AS ship_month,
       sum(extended_price)                                                AS total,
       sum(CASE WHEN is_ipr_matched THEN extended_price END)              AS matched,
       avg(CASE WHEN is_ipr_matched THEN 1.0 ELSE 0.0 END)                AS match_rate
FROM   finance.billing.fact_invoice_line
WHERE  sop_type = :invoice_type
GROUP BY 1
```

The match rate travelling beside the amount is the point of carrying the flag as data. A period whose rate has collapsed is then visible **before** someone builds a forecast on it.

## Gotchas

- **`void_status` is always null.** Do not filter on it and do not conclude nothing is voided. The void data does not exist in the replica.
- **`customer_key` is an inference, twice removed.** A customer-grain invoice report from this table is bounded by 60.6%, not by 98.7% — the higher figure is only the `ipr_invoice`→`sopnumbe` hop.
- **`ship_to_name` is PII** and lives in a schema that `finance-analysts` can read. It is a ship-to, so it is not the billing party either.
- **Kit components double-count if `component_sequence` is ignored.** The parent line and its components both carry amounts; check `CMPNTSEQ` semantics against the GP reference before summing.
- **`DECPLCUR` is one-based.** Rendering with a hardcoded two decimals is wrong for any currency where it is not 3.
- **CAPFM is absent, not zero.** Any cross-entity billing comparison must say so explicitly.
