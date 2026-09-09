---
tags:
  - finance
  - semantic-layer
  - table-spec
created: 2026-09-09
updated: 2026-09-09
---

# finance.reference.fact_exchange_rate

> [!warning] Not built
> DDL: [[../ddl/04-finance-reference.sql|04-finance-reference.sql]] · `STATUS: NOT EXECUTED`. See [[Table Specifications]].

| | |
|---|---|
| **Type** | Fact — not a lookup |
| **Grain** | Legal entity × exchange table × currency × rate date × **rate time** |
| **Sources** | `mc00100` (rates), `mc40600` (rate-table purpose) |
| **Clustering** | `CLUSTER BY (rate_date, gp_currency_id)` |
| **Readers** | `finance-analysts` |
| **Tests** | **T-04** (landed precision of `XCHGRATE`) |

## Why a fact and not a lookup

**CAPFM is Canadian.** Consolidated APFM + CAPFM reporting requires translation, so rates are a measured, dated series rather than a static reference list. `RM20201` also carries `APTOEXRATE` and originating-currency amounts, so rate provenance is available per apply — build to that from the start rather than retrofitting translation later.

## Columns

| Column | Type | Null | Source | Notes |
|---|---|---|---|---|
| `exchange_rate_key` | BIGINT | No | Derived | PK. `xxhash64(legal_entity_code, exchange_table_id, gp_currency_id, rate_date, rate_time)` |
| `legal_entity_code` | STRING | No | Derived | **Exchange tables are maintained per company** — APFM and CAPFM rates are separate series |
| `exchange_table_id` | STRING | No | `MC00100.EXGTBLID` | Which rate table the rate belongs to. Space-padded — trim |
| `currency_key` | BIGINT | No | Derived | FK to [[dim_currency]] |
| `gp_currency_id` | STRING | No | `MC00100.CURNCYID` | As replicated |
| `rate_date` | DATE | No | `MC00100.EXCHDATE` | Blank-date sentinel → NULL, **but a null here means the row is unusable** and should be surfaced rather than loaded |
| `rate_time` | TIMESTAMP | Yes | `MC00100.TIME1` | GP stores date and time in separate columns. Both are needed because **a table can hold multiple rates for one day** |
| `expiration_date` | DATE | Yes | `MC00100.EXPNDATE` | When the rate stops applying |
| `exchange_rate` | DECIMAL(19,7) | Yes | `MC00100.XCHGRATE` | Confirm landed precision rather than assuming `19,7` — a truncated rate is a silent translation error |
| `rate_purpose` | STRING | Yes | Derived from `MC40600` | `current`, `historical`, `average`, `budget`, or `unmapped`. **`MC40600`'s purpose is inferred rather than documented by Microsoft, so treat `unmapped` as a real category, not a defect** |
| `source_system` | STRING | No | Literal | `GP` |
| `source_table` | STRING | No | Literal | e.g. `main.prod_gp_apfm_dbo_live.mc00100` |
| `_loaded_at` | TIMESTAMP | No | Pipeline | |

**Constraints:** `pk_fact_exchange_rate PRIMARY KEY (exchange_rate_key)`; `fk_exchange_rate_currency FOREIGN KEY (currency_key) REFERENCES finance.reference.dim_currency`.

## Recommended joins

| Join to | On | Cardinality | Notes |
|---|---|---|---|
| [[dim_currency]] | `f.currency_key = c.currency_key` | N:1 | |
| [[dim_legal_entity]] | `f.legal_entity_code = le.legal_entity_code` | N:1 | Or via `legal_entity_key` if resolved at load |

### Translating a fact is an as-of join, not an equijoin

**There is no `exchange_rate_key` on any fact in this catalog.** Translation is not pre-joined, deliberately — the rate that applies depends on which rate table and which purpose the question wants, and that is a reporting decision rather than a load-time one.

The grain includes `rate_time`, so a date-only equijoin can return **several rows per day**. The correct pattern is latest-on-or-before:

```sql
-- Translate a GL posting into a reporting currency
SELECT p.*, r.exchange_rate
FROM   finance.general_ledger.fact_gl_posting p
LEFT JOIN finance.reference.fact_exchange_rate r
  ON  r.legal_entity_code = p.legal_entity_code
  AND r.gp_currency_id    = :from_currency
  AND r.exchange_table_id = :rate_table   -- pin it; do not let it fan out
  AND r.rate_date        <= p.transaction_date
  AND (r.expiration_date IS NULL OR r.expiration_date > p.transaction_date)
QUALIFY row_number() OVER (
          PARTITION BY p.posting_key
          ORDER BY r.rate_date DESC, r.rate_time DESC NULLS LAST) = 1
```

Three things that go wrong without this:

1. **Omitting `exchange_table_id`** joins Current, Historical, Average and Budget rates all at once. The amount then depends on join order, which is to say it is nondeterministic.
2. **Omitting `rate_time` in the ordering** picks an arbitrary intraday rate when a day carries more than one.
3. **Using `=` on `rate_date`** returns nothing on any date with no rate maintained — weekends, holidays, and any gap in maintenance. A `LEFT JOIN` then silently produces a null rate and a null translated amount.

### Which rate table

`rate_purpose` is the column that lets a consumer ask for the right series without knowing GP's table ids. Pin it rather than the raw `exchange_table_id` where possible:

```sql
AND r.rate_purpose = 'current'    -- or 'average' for a period-average translation
```

And handle `unmapped` explicitly. It is a real category — an unmapped rate table is a rate table whose purpose `MC40600` does not establish, not a broken row.

## Gotchas

- **Rates are per legal entity.** A CAPFM translation must use CAPFM's rate table, not APFM's.
- **`rate_date IS NULL` means the row is broken**, unlike every other date in this catalog where the sentinel-to-NULL mapping is benign. Surface these at load.
- **A missing rate is not zero.** Translating with a null rate produces a null amount, and `sum()` skips it — the total silently loses the untranslated rows.
