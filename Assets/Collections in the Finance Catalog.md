---
tags:
  - finance
  - semantic-layer
  - collections
  - databricks
created: 2026-09-09
updated: 2026-09-09
---

# Collections in the Finance Catalog

> [!note] Placement analysis only — nothing was changed
> This note answers *where collections belongs* in *Finance Catalog and Mart Design 2026-09-09* (vault: `plans/2026-09-09-finance-catalog-and-mart-design`, not in this repo). **No DDL file was edited, no table was added, and no grant was changed.** Everything proposed here is a proposal. The eleven files under `ddl/` still describe exactly what [Finance Catalog DDL](Finance%20Catalog%20DDL.md) says they describe.

## The answer

**Collections stays in `finance.receivables`. It does not get its own schema — yet.**

Collections is receivables management read with a different intent. The core operational query needs `fact_ar_transaction`, `mart_ar_aging`, and `dim_collections_attributes` together; a separate `finance.collections` schema would make the primary use case a cross-schema join and buy nothing. Under the design's own rule — schemas are marts, and a mart has a fact grain — collections has no independent grain today. It reuses `fact_ar_transaction` and `fact_ar_apply`.

The consumption side already agrees. The Genie split in the initial plan (vault: `Finance Semantic Layer Initial Plan 2026-09-08`) names one of its four agents **"Receivables & Collections"**, so the schema boundary and the agent boundary land in the same place.

Collections is also already an unnamed driver inside the DDL. `dim_customer.bank_name` carries the comment *"Carried because collections work needs it"* — the requirement was shaping columns before it had a home.

**The trigger to split it out later:** the arrival of a collections *activity* source. At that point there is a genuine activity fact with its own grain and its own load cadence, plus a worklist and a behaviour mart, and `finance.receivables` would be holding eleven tables that mix accounting truth with operational workflow. Until then, one schema.

### One boundary to state before someone else states it wrong

The epic's v1 non-goals include **"collections automation."** That excludes *doing* the collecting — dunning sequences, dialer integration, workflow state owned in the warehouse. It does not exclude collections *analytics*. Everything in this note is reporting: who owes what, how old, who owns it, how they have paid before. Expect the non-goal to be cited against the worklist anyway, and have the distinction ready.

## What already serves collections

All in `finance.receivables` unless noted, and all in [the DDL](Finance%20Catalog%20DDL.md) today.

| Object | What collections gets from it |
|---|---|
| `mart_ar_aging` | Who owes what and how old. Carries `computation_basis` in its grain, so the snapshot and reconstructed figures coexist and a disagreement is visible rather than averaged |
| `fact_ar_transaction` | The documents themselves, including `gp_aging_bucket` (`AGNGBUKT`) — GP's own bucket, and the only independent check on the cutoffs, available for **open documents only** |
| `fact_ar_apply` | The payment trail. Carries both `apply_to_document_date` and `apply_date`, which is what makes payment behaviour derivable with no new ingestion |
| `mart_writeoff` | Write-off events with dates and `business_unit_id` resolved as of the write-off. Tagged `requires_no_new_ingestion='true'` — servable today |
| `dim_collections_attributes` | CN00500 as a satellite on `dim_customer`: `credit_manager_id` (`CRDTMGR`), `credit_control_cycle`, `preferred_contact_method`, `no_mail_flag`, and `Time_Zone` — the last of which exists for call windows and nothing else |
| `finance.identity.dim_customer` | Credit limit type and amount, balance type, statement cycle, on-hold, inactive |

`business_area = collections` is already a value in the tag vocabulary defined by the GP UC metadata plan (vault: `plans/2026-08-27-dynamics-gp-uc-metadata-plan`), so the Phase 0 tagging work does not need a vocabulary change to label any of this.

## Four gaps, in order of cost

### 1. `dim_customer` is missing RM00101's collections-policy columns

Cheapest gap and the most surprising one. The columns exist in the replica and were simply not carried. Verified against `Dynamics GP Table and Column Metadata Reference` on 2026-09-09 — all 101 RM00101 columns were re-extracted, and each name below is present in the source.

| Source column(s) | What it is | Why collections needs it |
|---|---|---|
| `MXWOFTYP`, `MXWROFAM` | Maximum write-off type and amount | Makes *"was this write-off within the customer's authorized limit"* answerable. This is write-off **governance**, which is the second half of Tiffany Wise's write-off pain point — visibility without authorization context invites the wrong conclusion |
| `RMWRACC`, `RMFCGACC`, `RMOvrpymtWrtoffAcctIdx` | GL account indices for write-off, finance charge, and overpayment write-off | The reconciliation path from `mart_writeoff` to `fact_gl_posting`. Without them the tie-out is a guess about which accounts to filter |
| `FNCHATYP`, `FNCHPCNT`, `FINCHDLR`, `FINCHID` | Finance charge setup — type, percentage, dollar amount, charge id | Separates *interest accrued* from *principal owed* in an aging balance. Chasing a balance that is mostly finance charge is a different conversation |
| `DISGRPER`, `DUEGRPER` | Discount and due-date grace periods | These shift the date a document is actually past due. Aging computed without them will disagree with what the customer believes, per customer, and the disagreement will look like a bug |
| `MINPYTYP`, `MINPYDLR`, `MINPYPCT` | Minimum payment type, dollar, percent | Defines what counts as a good-faith payment versus a token one |
| `CRLMTPER`, `CRLMTPAM` | Credit limit period and period amount | The existing `credit_limit_amount` is only half the limit when the limit is periodic |
| `Send_Email_Statements`, `DOCFMTID` | Statement channel and document format | With `NOMAIL` from CN00500, this is the complete dunning-channel picture. Sending a paper statement to a `NOMAIL` customer is the kind of error that is only visible when both flags sit side by side |
| `KPDSTHST`, `KPCALHST`, `KPERHIST`, `KPTRXHST` | Keep-history flags | Whether GP is retaining history for this customer at all. A customer with history retention off is a customer whose reconstructed aging is incomplete, and nothing else in the design would reveal that |

**These are not PII.** Which exposes a problem the current layout created: `finance.identity` is restricted to `finance-pii-readers` (`ddl/10-grants.sql`), so every non-PII policy attribute sitting on `dim_customer` is **over-restricted**. A collections analyst should not need a PII grant to read a credit limit — and `credit_limit_amount`, `balance_type`, and `statement_cycle` are already there, so this is a live inconsistency, not a hypothetical one.

The fix is not moving columns between schemas. It is a projection:

```text
finance.receivables.vw_customer_credit_policy
  -- over finance.identity.dim_customer
  -- projects the policy columns only, no names, no addresses, no bank details
  -- granted to finance-collections; finance.identity is NOT granted
```

Standard Unity Catalog view-based access control: the view's owner needs `SELECT` on the base table, the reader needs it only on the view. Same mechanism `ddl/02-guarded-gp-views.sql` already relies on. Worth an explicit test with a genuinely non-privileged principal in `attivita` before depending on it, for the same reason `ddl/11` refuses to assert how masks behave through views.

### 2. `mart_collections_worklist` — buildable today, does not exist

The operational output. Grain: as-of date × customer.

Past-due total, oldest days past due, amount by bucket, credit utilization against the limit, credit manager from `CN00500.CRDTMGR`, preferred contact method, `no_mail_flag` and `Send_Email_Statements`, time zone for call windows, on-hold status, last payment date and amount — plus `business_unit_id` and `salesforce_id` so the answer is reachable by the audience that needs it.

This is what closes *"balance and past-due invisible in Salesforce."* Every input is already in `finance.receivables` or one column-addition away.

### 3. `mart_customer_payment_behaviour` — also buildable today

Grain: customer × period. Derived entirely from `fact_ar_apply`, which carries the document date and the apply date on the same row: weighted average days to pay, count and value of documents paid late, discount-taken rate, partial-payment rate, write-off history, and the trend across periods.

This is the segmentation layer — it decides *who* goes on the worklist rather than listing everyone with a balance. It is also the closest available answer to Tiffany Wise's *"CWS payment behaviour"* point, and it needs no new ingestion.

**One measure to decide before building:** DSO needs a revenue denominator, which lives in `finance.billing` or the GL, not in receivables. Whoever builds this has to pick a denominator and write it down, because DSO computed two ways is DSO nobody trusts.

### 4. `fact_collection_activity` — blocked on a source that may not exist

Notes, calls, promises to pay, dunning history, escalations. This is the real gap, and the distinction it draws is the important one:

- *"Who should we call"* — **servable today**, gaps 1–3.
- *"What happened when we called"* — **not servable, and not reconstructable from anything in the replica.**

A worklist without activity history means the same customer gets called twice and a promise to pay is invisible. That is not a reporting nicety; it is the difference between a list and a process.

## The one query that settles gap 4

**`CN00500` is the only CN table named anywhere in this vault** — 211 mentions, and no other CN table appears in any `.md`, `.sql`, `.csv`, or `.txt` under `Vault/APFM/`. But the vault documents **32 of 59 physical GP tables**, so the silence is not proof. The GP UC metadata plan enumerates only 18 GP tables and does not settle it either.

One read against the replica does:

```sql
-- Read-only. Choose a profile explicitly; dbc-88a3d066-4cdb is production
-- AND is the CLI default, so an omitted --profile lands there silently.
SELECT table_schema, table_name
FROM   main.information_schema.tables
WHERE  table_schema IN ('prod_gp_apfm_dbo', 'prod_gp_capfm_dbo')
  AND  table_name LIKE 'cn%'
ORDER BY 1, 2;
```

**Not yet run.** If CN activity tables are present, `fact_collection_activity` becomes a build rather than an ask — and the case for a `finance.collections` schema gets materially stronger the same day.

If they are absent, the second candidate source is Salesforce activity rather than GP, which changes the owner of the conversation and puts it next to `SF-1869`.

## Grants

`finance-collections` needs `finance.receivables` + `finance.reference` + `vw_customer_credit_policy`, and **not** `finance.identity`. That is a per-schema enumeration, which is the standing cost of environment-in-schema and not an oversight — see the header of `ddl/10-grants.sql`.

The harder audience is the one Tiffany Wise actually named. CAMs and Community Ops need write-off visibility **scoped to their own communities**, which is a **row filter on `business_unit_id`** — a different mechanism from anything in `ddl/11`, which is column masks only. `mart_writeoff` already carries `business_unit_id` resolved as of the write-off date, so the column is there and the filter is not.

Worth noting that a row filter has the inverse risk profile from a mask: a mask makes a value unreadable and the change is visible in the value, while a filter makes rows *disappear* and the change is invisible in the result. A CAM comparing a filtered total against a finance total will find a discrepancy with no indication of why. If a filter is applied, the filtered object should say so in a column or a tag.

## What this note does not change

- No file under `ddl/` was edited. All eleven still carry `STATUS: NOT EXECUTED`.
- No table was added to any schema, and the count in [Finance Catalog DDL](Finance%20Catalog%20DDL.md) is still 28.
- No grant was added to `ddl/10-grants.sql`; `finance-collections` is proposed here only, and the existing group names in that file are still unconfirmed placeholders.
- No RM00101 column was added to `dim_customer`. Gap 1 is a finding, not a fix.
- `ddl/11-pii-masking-prepared-not-applied.sql` is untouched and still entirely commented.
