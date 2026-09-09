---
title: Finance Semantic Layer Initial Plan 2026-09-08
created: 2026-09-08
updated: 2026-09-08
status: draft — proposal for discussion, nothing approved
epic: DTS-4187
workspace: dbc-88a3d066-4cdb
profile: dbc-88a3d066-4cdb
tags:
  - finance
  - semantic-layer
  - databricks
  - dynamics-gp
  - genie
  - plan
---

# Finance Semantic Layer — Initial Plan

> [!warning] Status: draft proposal, not an approved plan
> Nothing here has been agreed by Finance or Data Platform. [DTS-4187](https://aplaceformom.atlassian.net/browse/DTS-4187) is an **Epic in To Do at Low priority with zero child issues** — a complete design document with no decomposed work beneath it. **The purpose of this note is to be that decomposition**, so that the 2026-09-08 check-in can end with tickets written instead of another round of decisions recorded.
>
> Phase boundaries and ticket splits below are mine. The evidence they rest on is measured and cited; the sequencing is a proposal.

## What this plan is built on

Three different classes of input, kept separate on purpose:

| Class | Source | Trust |
|---|---|---|
| **Measured on production** | [[../Databricks landscape/gp-ipr-identity-spine-validation-2026-09-08\|gp-ipr-identity-spine-validation-2026-09-08]] (2026-09-08, read-only, profile `dbc-88a3d066-4cdb`) and the 2026-08-27 GP snapshot in [[GP to Genie/GP to Genie\|GP to Genie]] | Reproducible. Cite freely. |
| **From the epic** | Paul Sears' Appendix comment on DTS-4187, 2026-08-28 — source inventory, trap list, match rates, revenue streams, open decisions | Independently reproduced on 2026-09-08 for all four identity-spine candidates, two to the exact numerator and denominator. Trustworthy. |
| **Stated need** | Tiffany Wise's pain-points comment on DTS-4187, 2026-08-28 11:17 | Her words, not our inference. |

The single most useful thing that changed in the last eleven days: **the identity spine is no longer an assumption.** It is measured, and the number is better than the epic claimed.

## Guiding constraints

These are not steps. They apply to every step, and each one has already produced a wrong number in this vault at least once.

1. **`_fivetran_deleted = false` on every GP query, always.** 16% of rows across the estate are tombstones and **82–99.9%** in the tables users actually ask about. Omitting it overstates `gl20000` activity roughly **5.7×**. This belongs in the staging layer so no consumer can forget it.
2. **`_fivetran_synced` is not a freshness signal.** It advances only when a row changes. `gl30000`'s 2026-01-31 timestamp is the FY2025 close, not a broken connector. Monitor connector `succeeded_at` instead.
3. **Date-bound the funnel bridge.** GP→funnel resolves at **100.00% for FY2023–2026** and ~1.8% before mid-2022. Quote it with the bound or not at all — the bare all-time figure (51.85%) undersells it and an unqualified "100%" promises history that does not exist.
4. **Label reconstructed numbers as reconstructed.** Ship "real" and "estimated" as two clearly named outputs, never one blended figure. This is the discipline that keeps a gap from becoming "the numbers are wrong" three weeks later.
5. **Name the grain in every ingestion request.** The DTS-4188 lesson: ask for a *separate table*, not a column bolted onto an existing grain, or you get row explosion and ambiguous duplication.
6. **A Genie agent holds ≤30 tables and Databricks recommends ≤5.** Against 59 GP tables that means four agents, not one. Scope is a design constraint, not a preference.

## Ingestion blockers

The blocker list has been carrying more weight than it can support. Classified honestly, **one is a hard gate, two are cost/benefit asks, one is withdrawn, and two are scope decisions that have been sitting in the blocker column pretending to be engineering problems.**

|     # | Item                                                                                                                  | Class                                    | What it actually costs us                                                                                                        | Mitigation available today                                                                                                                                                                                                        | Owner                       |
| ----: | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
|     1 | `SOP30200` (Sales Transaction History header) not ingested `SOP30300` as well for lead_id. can join back accordingly. | **Soft — cheap insurance**               | Sales-lane header attributes: customer, document date, void status, salesperson. `sop30300` has 8.0M line rows with none of them | The epic resolves invoice lines through the IPR bridge — `ipr_invoice.gp_invoice_num` → `sop30300.sopnumbe` at **98.7%** (613,879 / 622,066). Real ceiling runs the other way: only **60.6%** of REF documents have an IPR at all | **Kate Grimshaw**           |
|     2 | `GL00105` (Account Index Master) not ingested                                                                         | **Soft**                                 | Account strings must be assembled rather than read                                                                               | Assemble and **document the 5-segment assumption** in the staging layer                                                                                                                                                           | **Kate Grimshaw**           |
| ~~3~~ | ~~`RM00101` PII masking undecided~~                                                                                   | ~~**HARD — gates Phase 4**~~             | ~~**Applying column masks disables entity matching on that table.** Decided late, it invalidates a tuned agent~~                 | ~~None. This must be decided before any agent is tuned against `RM00101`~~                                                                                                                                                        | ~~Finance + Data Platform~~ |
|     4 | ~~`gl30000` last replicated 2026-01-31~~                                                                              | **WITHDRAWN**                            | Nothing                                                                                                                          | Not a blocker. See constraint 2 — the table is correct, not stale. **Do not send anyone to investigate a healthy connector**                                                                                                      | —                           |
|     5 | Only **2 of 7** live GP companies replicated                                                                          | **Scope decision**                       | No consolidated question is answerable until settled                                                                             | Confirm the other five are out of scope by design. Missing: AgingCare, APFM Holdings, SeniorAdvisor.com, Tomorrow's Guides, APFM UK                                                                                               | **Tiffany Wise**            |
|     6 | ~~No PO or~~ commitment tables replicated at all                                                                      | **Deferred by the epic's own non-goals** | Budget-vs-actual cannot include committed amounts                                                                                | Label the gap. Purchasing is a v1 non-goal in DTS-4187, so this is not a blocker unless scope changes                                                                                                                             | —                           |

### Two things to say plainly about this list

**It is a three-item list, not a five-item list.** Blocker 4 is withdrawn and blockers 5 and 6 are scope decisions. Walking into a check-in with a padded blocker list is how a Low-priority epic stays Low.

**Only blocker 3 can stop work.** Blockers 1 and 2 are cost/benefit asks with working mitigations, so Phases 1–3 proceed regardless of whether Fivetran ever adds those tables. That is the useful conclusion: **the ingestion gaps do not gate the build.** They cap the Sales lane's coverage at a measurable 60.6% and force one documented assumption on account strings.
*we are pushing this into a further phase, all folks who will access this data have rights to see the PII info*


### The queue is one person, not five tickets

Blockers 1 and 2 route to **Kate Grimshaw** as ingestion-path owner. So does **DTS-4188**, which is In Progress with a working dev prototype and parked on two questions to Kate open since 2026-09-02 and 2026-09-03. That is two GP connector asks plus a live marketing ticket queued behind the same person.

Raise them as **one sequencing conversation with a named grain per request**, not as tickets trickling in independently — and clear the DTS-4188 questions verbally while she is in the room, because that is a thirty-second answer unblocking a ticket that blocks PRODAN-231.

### A blocker the epic does not list

`main.prod_fin_ipr_ipr.ipr` has **no modelling layer on either side.** Upstream is only ephemeral Fivetran staging; downstream is one leftover VIEW; and 26,303 lineage read events land directly on the raw replica from dashboards and ad-hoc queries. There is no `finance_staging`, no conformed dimension, nothing between replica and consumer.

That is the argument for this epic — its raw → staging → reporting design is not adding a layer, it is adding **the only** layer. It is also a migration hazard: **`main.prod_fin_charges_ipr.ipr` is a VIEW the epic tells people to avoid, and it was read on 2026-09-08 at 16:36 UTC.** Deprecating it will break something live. Find the two dashboards before touching it.

## Phases

### Phase 0 — Metadata and decisions. No ingestion dependency. Starts now.

The highest-leverage work available, and none of it waits on Fivetran.

- **Apply the 3,313 generated Unity Catalog comments and tags** across all 59 GP tables and 2,169 columns. Already generated, not applied. Genie's accuracy comes mostly from column descriptions, and every one of those columns is currently uncommented — `TRXSORCE`, `ACTINDX`, `NJRNLENT` mean nothing to a model without help. **Needs a reviewer: Bron Tamulis is the GP expert.** Ask for his time.
- **Close decisions 1, 2, 5, 6** (audience and top-5 questions, GP company scope, first agent scope, golden SQL).
- **Decide the `RM00101` PII masking posture** (blocker 3) — this gates Phase 4, so deciding it late wastes tuning work.
- **State the catalog/schema names on the record**: `main.prod_gp_apfm_dbo`, `main.prod_gp_capfm_dbo`, `main.prod_gp_dynamics_dbo`.

### Phase 1 — Financials lane. Buildable today.

The only fully servable swim lane of the three named at kickoff. `gl20000`, `gl30000`, `rm20101`, `rm30101`, `rm20201` and the masters are all replicated.

- `main.finance_staging` views over the GP replicas, with the `_fivetran_deleted` guard baked in so no consumer can omit it.
- `main.finance_reporting` conformed dimensions and facts: GL trial balance, revenue by stream, AR aging.
- **Company dimension is degenerate for APFM**: 100% of APFM GL activity — all 8,204,550 rows, FY2000–2026 — carries Company segment `10`. One company database really does equal one legal entity, so do not build a company hierarchy that has one member.

### Phase 2 — Identity spine and the funnel bridge. Validated, so low-risk.

This is the phase that answers Tiffany's pain point 3 in her own words, and its join rates are already measured.

- `dim_customer` keyed on GP `rm00101.custnmbr`, spined via **`ipr.fin_customer_id` at 97.92% row-level / 97.24% distinct**.
- `bridge_gp_customer_to_family` via **`ipr.lead_id` → `funnel_lead.lead_id` → `family_file_id`, 100.00% for FY2023–2026**. `ipr` carries both keys on the same row (99.28% of live rows), so this is one table, not a chain. **Do not route this through YGL** — `prod_ygl_apfm`'s GP mapping keys on `business_unit_id`, a community, and cannot reach a family without borrowing the same `lead_id` `ipr` already has.
- Optional Salesforce bridge via `prod_fin_01_cst.mir`, which carries `lead_id` (100%), `salesforce_id` (93.1%) and `customer_billing_id` (64.7%) on 409,309 live rows. Note `mir.customer_billing_id` matches GP at only 22.19% — **use `mir` as the Salesforce bridge, never as the GP spine.**
- **Ship the FY2023 floor as a documented property of the model**, not as a caveat someone discovers later.
- Free use case, no new source: **unbilled move-ins are the rows where the spine is null and `move_in` is populated.** `fin_customer_id` is assigned at invoicing, so blank means not yet billed — 0.02% blank for January-created rows, **77.74% for September**. The corollary is a trap worth stating once: **any inner join from `ipr` to GP silently drops most of the current month.**

### Phase 3 — Sales lane via the IPR invoice bridge. Not blocked on `SOP30200`.

- `fact_invoice_line` built through `ipr_invoice.gp_invoice_num` → `sop30300.sopnumbe` at **98.7%**.
- **Label the ceiling in the model, not in a footnote**: only **60.6%** of REF documents have an IPR. Present the lane as 60.6% coverage, not as complete and not as blocked.
- The `SOP30200` request (blocker 1) runs in parallel and raises coverage if granted. It does not gate this phase.

### Phase 4 — Genie agents. Gated on Phase 0 and blocker 3.

Four agents against 59 tables, per the ≤5-table guidance: **Financials · Receivables & Collections · Budget vs Actual · Currency & System.** Decision 5 picks which is first, and it is the decision that unblocks the most downstream work.

Do not start tuning until the UC comments are applied and the `RM00101` masking posture is decided.

### Explicitly deferred

| Deferred | Why |
|---|---|
| **Purchasing lane** | No PO or commitment tables replicated, and a v1 non-goal in the epic |
| **Maxio target state** | Epic non-goal for v1 |
| **Home Care revenue** | Would inherit DTS-4180's problem: HC `campaign_id` is not populated in `prod.funnel_lead` at all and must be regex-parsed from `hmcrequest.url`, where ~3.8M of ~5.3M rows have no campaign ID. **This is a URL-parsing recovery project, not a column add.** In-or-out is already an open decision in the epic |
| **Pre-2022 funnel history** | `funnel_lead` history floor. Not recoverable from the GP side |
| **Replacing GP/IPR as system of record** | Epic non-goal |
| **Collections automation, payroll, fixed assets, inventory** | Epic non-goals |

## Proposed child tickets

The gap DTS-4187 actually has. **The meeting only needs the first two or three of these written** — the rest exist so the shape of the epic is visible.

| # | Proposed ticket | Phase | Depends on |
|---:|---|---|---|
| 1 | Apply the 3,313 generated UC comments and tags to 59 GP tables / 2,169 columns | 0 | Bron Tamulis review time |
| 2 | Decide and document the `RM00101` PII masking posture | 0 | Finance + Data Platform |
| 3 | Confirm GP company scope — 2 of 7 replicated, are the other five out by design | 0 | Tiffany Wise |
| 4 | Build `finance_staging` GL views with the `_fivetran_deleted` guard | 1 | #3 |
| 5 | Build `finance_staging` AR views with the `_fivetran_deleted` guard | 1 | #3 |
| 6 | Build `dim_customer` on the validated `ipr.fin_customer_id` spine | 2 | #4, #5 |
| 7 | Build `bridge_gp_customer_to_family`, FY2023 floor documented in the model | 2 | #6 |
| 8 | Build `fact_invoice_line` via the IPR invoice bridge, 60.6% coverage labelled | 3 | #6 |
| 9 | Fivetran request: `SOP30200` + `GL00105`, grain named per request | parallel | Kate Grimshaw |
| 10 | Stand up Genie agent 1, scope per decision 5 | 4 | #1, #2 |

Tickets 1–3 are Phase 0 and have no ingestion dependency, which is the point: **work can start before a single connector question is answered.**

## Decisions that gate phases

Mapping the six still-open kickoff decisions onto what they actually hold up, so none of them can be deferred without a visible cost.

| Decision | Gates | Ask of |
|---|---|---|
| 1 — Primary audience and top 5 questions in her GP language | Phase 4 agent scoping; validates Phase 1 outputs | **Tiffany Wise** |
| 2 — Which GP company / database is in scope | Phases 1–3 (see blocker 5) | **Tiffany Wise** |
| 3 — Catalog/schema/table names | Nothing — **ours to state, answerable now** | Data team |
| 4 — Request `GL00105` / `SOP30200` | Nothing hard. Partly self-answered: the epic calls `SOP30200` "cheap insurance" | Group |
| 5 — First Genie agent: GL, AR, or full finance | **Phase 4 entirely.** The highest-leverage decision on the list | Group |
| 6 — Golden SQL examples to validate against | Phase 1 acceptance criteria | Data team + **Bron Tamulis** |

## Risks

- **`prod_fin_charges_ipr.ipr` is a live VIEW.** Read 2026-09-08 16:36 UTC. The epic's trap list says avoid it; lineage says two dashboards depend on it. Identify them before deprecating.
- **PII masking applied late invalidates a tuned agent.** Column masks disable entity matching on `RM00101`. This is why blocker 3 sits in Phase 0 rather than Phase 4.
- **Four jobs began reading `ipr` on 2026-08-28** — the day the epic was filed. Owners unidentified. Someone may already be building a parallel version of this.
- **`prod_optgen_ipr` is all zero rows and `ygl_gp_mapping` matches GP at 0.14%.** Both are named-alike traps that reproduce exactly as the epic describes. Anyone who joins them will get a plausible-looking empty answer rather than an error.
- **`rm00101` distinct live customers fell ~113 between 2026-08-27 and 2026-09-08.** GP customer counts are not monotonic. Do not build a check that assumes they are.
- **Genie accuracy depends on Phase 0 landing first.** Standing up an agent against 2,169 uncommented columns will produce a demo that fails on the second question and sets the project back further than waiting would have.

## Open question this plan cannot answer

Tiffany's pain point 4 — YGL holding one Primary Invoicing ID at a time, losing a property's payment history on overwrite — may not actually be a data-loss problem. `great_plains_customer_mapping` holds **46,819 live rows over only 36,597 distinct `business_unit_id`** — 10,222 surplus — and carries `begin_date` / `end_date`. The superseded ERP IDs look preserved in Databricks even though the YGL UI shows only the current one. Both YGL tables carry zero Fivetran tombstones, so nothing is hiding behind `_fivetran_deleted`.

If that holds, her stated pain is partly a **reporting** problem we can solve now, not only a **source-system** problem waiting on `SF-1869`. Worth an explicit check before `SF-1869` is scoped as the only fix.

## Links

- [[Finance Semantic Layer|Finance Semantic Layer]] — folder note and epic tracker
- [[GP Data Check-in Prep 2026-09-08|GP Data Check-in Prep 2026-09-08]] — the check-in this plan feeds
- [[Kickoff Meeting 2026-08-28|Kickoff Meeting 2026-08-28]] — where the three swim lanes and six decisions came from
- [[GP to Genie/GP to Genie|GP to Genie]] — GP table/column research, join map, Genie build playbook
- [[../Databricks landscape/gp-ipr-identity-spine-validation-2026-09-08|gp-ipr-identity-spine-validation-2026-09-08]] — the measured spine and lineage evidence
- [DTS-4187](https://aplaceformom.atlassian.net/browse/DTS-4187) · [SF-1869](https://aplaceformom.atlassian.net/browse/SF-1869) · [DTS-4188](https://aplaceformom.atlassian.net/browse/DTS-4188) · [DTS-4180](https://aplaceformom.atlassian.net/browse/DTS-4180)
