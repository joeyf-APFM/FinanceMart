---
title: GP Data Check-in Prep 2026-09-08
created: 2026-09-08
meeting_date: 2026-09-08
meeting_time: 12:30–1:00 PM MT
meeting_title: GP Data to Databricks Project Check-in
attendees:
  - Tiffany Wise
  - Kate Grimshaw
  - Jimmy Bui
  - Jill Leos
  - Bron Tamulis
workspace: dbc-88a3d066-4cdb
profile: dbc-88a3d066-4cdb
tags:
  - gp-to-genie
  - dynamics-gp
  - databricks
  - genie
  - finance
---

# GP Data Check-in Prep — 2026-09-08

First check-in since the [[Kickoff Meeting 2026-08-28|2026-08-28 kickoff]]. Eleven days, thirty minutes, five people, and **all six kickoff decisions still Open** — so this is a decision meeting, not a status meeting. Lead with the two findings that change what they asked for, then close the decisions.

Everything below is sourced from this folder. Evidence for the table/replication claims is the 2026-08-27 snapshot in [[GP to Genie/A Genie Playbook for Dynamic GP|A Genie Playbook for Dynamics GP]] and [[plans/2026-08-27-dynamics-gp-uc-metadata-plan\|the UC metadata plan]], measured against `main` on the production workspace (`dbc-88a3d066-4cdb`).

## DTS-4187 live status — pulled from Jira 2026-09-08

| Field | Value |
|---|---|
| Type / status | Epic, **To Do** |
| Priority | **Low** |
| Assignee | **Bolu Fatunmbi** — no assignee was recorded anywhere in this vault before today |
| Reporter | Paul Sears, created 2026-08-28 |
| Label | `NewProductInvestment` |
| Last updated | 2026-09-02 |
| Child issues | **None.** `parent = DTS-4187` returns zero results |

The last row is the important one. Eleven days on, the epic is a very thorough design document with **no decomposed work beneath it** — no stories, no spikes, nothing anyone can be assigned or burn down. That is a better explanation for the absence of movement than "the decisions went unanswered," and it changes the ask: the outcome of this meeting should be *the first two or three child tickets written*, not another round of decisions recorded in a document.

It also reframes the priority question. **Low** priority on an epic with no children is not a prioritisation signal at all — it is an epic that has never entered a queue. Ask Tiffany what her deadline actually is, and whether Bolu knows he owns this.

## Put these two in front of the group first

### 1. Two of the three swim lanes they named cannot be built today

At kickoff they framed the work as three swim lanes — **Financials, Sales, Purchasing**. Only one is servable:

| Swim lane                         | Status             | Why                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| --------------------------------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Financials** (GL + Receivables) | Buildable now      | `gl20000`, `gl30000`, `rm20101`, `rm30101`, `rm20201` and the masters are all replicated                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| **Sales**                         | **Partly blocked** | `SOP30200` (Sales Transaction History header) is not ingested. `sop30300` has 8.0M line rows with no customer, no document date, no void status, no salesperson. Item-level questions work; nothing a business user would actually ask does directly. **But** the epic routes invoice-line customer and date through the IPR bridge at 98.7%, so this is buildable *via the bridge* — with the real ceiling running the other way: only **60.6%** of REF documents have an IPR at all. Present it as 60.6% coverage, not as a wall. |
| **Purchasing**                    | **Absent**         | No PO or commitment tables are replicated at all. It is also why budget-vs-actual cannot include committed amounts.                                                                                                                                                                                                                                                                                                                                                                                                                 |

The ask: confirm whether Sales and Purchasing are in scope. If yes, they become Fivetran ingestion requests and a sequencing conversation, not a build. If no, say so on the record and Financials becomes v1.

### 2. The bridge from GP to the funnel already exists and is not being used

They asked for **end-to-end tracking and tracing** and requested **invoice ID be added to Salesforce**. Both point at the same join, and it is already in the lake:

**Validated on production 2026-09-08** — read-only, profile `dbc-88a3d066-4cdb`. Full evidence: [[../Databricks landscape/gp-ipr-identity-spine-validation-2026-09-08|gp-ipr-identity-spine-validation-2026-09-08.md]].

The bridge is **`main.prod_fin_ipr_ipr.ipr`**, and it is one table, not a chain. It carries the GP customer key and the funnel lead key on the same row:

| Measure | Result |
|---|---:|
| Live rows (`NOT _fivetran_deleted`) | 570,656 |
| `fin_customer_id` → `rm00101.custnmbr`, **row-level** | **97.92%** (558,787) |
| `fin_customer_id` → `rm00101.custnmbr`, distinct values | **97.24%** (24,422 / 25,114) |
| `lead_id` populated | **100.00%** |
| Both keys on the same row | **99.28%** (566,576) |
| `lead_id` → `funnel_lead` → `family_file_id`, **FY2023–2026** | **100.00%** (230,674 / 230,674) |
| Same bridge, 2022 | 95.75% |
| Same bridge, ≤ 2021 | 1.76% |

So GP revenue joins to the funnel **exactly** for FY2023 forward. The pre-2022 collapse is a `funnel_lead` history floor, not an IPR defect. **Say it with the date bound attached** — the bare all-time figure is 51.85%, which undersells a bridge that is perfect over any period this group will analyse, and an unqualified "100%" promises history that does not exist.

The funnel keys are already settled and in use on the cost side: `funnel_lead.funnel_lead_id`, `lead_id`, `family_file_id`, `dim_funnel_channel.campaign_id`, and DMA derived from `funnel_lead.desired_postal_code` → `geography_lookup.zip`. So "integrate GP into the funnel" has a concrete meaning — `ipr` → `funnel_lead.lead_id` → `family_file_id` — and revenue currently appears in the Context Graph only as `move_in` at 2,227 families / **8.4% coverage**. Nobody has to invent a spine.

> [!warning] Correction — do not present YGL as the family-grain bridge
> Earlier drafts of this note said "YGL is already family-keyed, so this is the path from a GP customer to `family_file_id`." **That is wrong, and it is worth knowing why before someone repeats it in the meeting.** The claim came from the Context Graph v3 producer inventory, which was transcribed into the vault from a pasted artifact and never queried. Queried on 2026-09-08:
>
> - `prod_ygl_apfm` has **481 tables**, not the 105 the inventory states.
> - **94** carry `lead_id`. Exactly **one** carries `family_file_id` (`prod_ygl_apfm.client`). The "105 family-keyed" figure most likely counted the lead-keyed tables and relabelled them.
> - Neither `great_plains_customer_mapping` (46,819 live) nor `great_plains_customer` (46,272 live) carries `family_file_id`, `lead_id`, or `property_id`. The mapping's grain is **`business_unit_id` — a community.**
>
> YGL's GP mapping is a real bridge to the **partner/property** side (partner concentration, property payment history), and it cannot reach a family without borrowing the same `lead_id` that `ipr` already carries directly. **The YGL route is strictly longer than the `ipr` route.** Lead with `ipr`; offer YGL for the community questions.

Appendix C3's ranking also reproduces end to end, so the epic's evidence can be trusted without re-deriving it: `ipr.fin_customer_id` **97.24%**, `finance.customer.gp_customer_num` **96.17%** (exact match to the epic's numerator and denominator), `mir.customer_billing_id` **22.19%**, and `ygl_gp_mapping.gp_customer_num` **0.14%** — the "dead table, do not use" verdict confirmed at 30 matches out of 21,344. That last one is a *different object* from `prod_ygl_apfm.great_plains_customer_mapping`, in a different schema; the names are close enough that if the room hears "there's already a mapping table," make sure they are not picturing the dead one.

> [!tip] One free use case, and one trap, from the same fact
> `fin_customer_id` is blank on only 0.71% of all live rows — but blank on **28.85% of August rows and 77.74% of September rows**, ramping monotonically from 0.02% in January. It is not a data-quality problem: the value is assigned when the referral is invoiced, so **blank means not yet billed** and backfills within about sixty days.
>
> That means the epic's **"unbilled move-ins"** use case is already sitting in the data — nulls in the spine where `move_in` is populated. No new source, no new join. And the trap: **any inner join from `ipr` to GP silently drops the current month**, three quarters of it in September. Worth saying out loud before someone builds a dashboard on it.

The ask: the invoice-ID-into-Salesforce request and the identity spine in **DTS-4187** are the same problem, and the spine half is now measured rather than assumed. Decide whether this group owns it, and whether DTS-4187 stays at **Low** priority while it is the thing that makes their "track invoices and how money is handled" goal answerable.

## Context: the funnel's cost side is stuck the same way

Background, not agenda — but it is the single strongest argument available if anyone pushes back on priority. Evidence: `google-ads-dma-lead-cost-table-inventory.docx` (see Source below), live Databricks validation 2026-08-31 on the same production profile (`dbc-88a3d066-4cdb`), 120-day window 2026-05-03 → 2026-08-31.

The funnel has two economic halves, and **both are blocked on the identical failure mode — an un-ingested source table.**

| | Revenue / AR side (this project) | Cost side (DTS-4188) |
|---|---|---|
| Question asked | Invoice and cash by lead / move-in | Google Ads spend by DMA and per lead |
| What exists | GL + Receivables replicated; `ipr` GP↔funnel bridge live and **validated at 100% for FY2023+** | `main.prod_refined.google_ads_data_history` — 119 campaigns, **~$42.1M spend** in 120 days |
| What's missing | `SOP30200`, `GL00105` not ingested | No Google Ads table **in prod** carries any location field — no DMA, metro, region, city, or geo criterion. A dev prototype now exists; see the status block below |
| Consequence | Sales lane unbuildable; account strings reconstructed | DMA spend can only be an **allocated estimate**, never actual |
| Fix | Fivetran connector additions | A separate Google Ads location performance sync |

Spend by source over the window: Senior Living **$26,480,193.18** (70 campaigns), Home Care **$11,643,842.26** (47), Grace **$4,002,171.89** (2).

**Live Jira status, pulled 2026-09-08 — and it puts a name in this room on the critical path.**

[DTS-4188](https://aplaceformom.atlassian.net/browse/DTS-4188) is **In Progress**, not stalled: Shivani Chouhan, reported by Brian Flynn 2026-08-28, last touched 2026-09-04, under epic **DTS-4144** *Unified Funnel Attribution and Analytics Gold Layer* (To Do, Low). It **blocks PRODAN-231** *Get Location Data / By Lead Spend for Google/Bing*, which is sitting in **Blocked**.

She found the path and built it. Google Ads `geographic_view` exposes the `geo_target_*` fields; she joined `geo_target_most_specific_location` against Google's own geo-target constants and landed `dev_refined.google_ads_data_4188_v1` plus `dev_refined.geo_target_constants`, with 10 days of test data as of 9/4. She also flagged the blast radius — the geo columns will land on `REFINED_DB.google_ads_data` as well, because `google_ads_data_history` derives from it.

**The ticket is waiting on Kate Grimshaw, who is on this call.** Two asks, both unanswered:

1. *(9/2)* Which geo columns to promote — only `geo_target_postal_code`, or also `geo_target_metro`, `region`, `state`, `county`, `city`? Six days open.
2. *(9/3)* The DMA/MSA mapping table she referenced by email — "we have mapping in the lake already for DMA, MSA, and various other bits and bobs." Five days open.

That is a thirty-second answer that unblocks a ticket blocking another ticket. Get it in this meeting rather than filing it.

Three things carry over directly to the GP build:

- **Both fixes are the same category of ask, and Kate is the shared dependency.** DTS-4188's location sync and GP blockers 1, 2, and 4 are all connector/ingestion requests. DTS-4188 is *assigned* to **Shivani**, but it is *waiting on* **Kate** — the same person the GP asks route to as ingestion-path owner. So this is not "different assignees, one conversation"; it is one bottleneck with five requests behind it. Raise them together so the queue gets sequenced deliberately instead of four GP tickets arriving separately from a marketing one that is already parked.
- **Add a table, don't add a column.** The DTS-4188 recommendation is explicitly to request a *separate* location performance table, because bolting location onto an already-detailed grain risks row explosion and ambiguous spend duplication. The same caution applies to anything we ask Fivetran to add on the GP side — name the grain in the request.
- **Ship two clearly labeled outputs, not one blended number.** The cost side is being built as "actual spend by DMA once the sync lands" *and* "interim allocated estimate," labeled separately. That is the pattern for GP too: build the Financials lane as real, and label the Sales/Purchasing gaps as gaps rather than quietly approximating around them. It is the same discipline as the `_fivetran_deleted` rule below — a reconstructed number that is not labeled as reconstructed becomes "the numbers are wrong" three weeks later.

Also worth knowing, because it is live in the daily notes as **DTS-4180**: in the 120-day profile, Home Care had **exactly 1 row** in `main.prod.funnel_lead` with `current_campaign_id` populated, so HC attribution has to run through `funnel_lead_hc` / `hmcrequest` / `session` instead — that path matched 122,145 HC rows to 47 campaigns. Senior Living is healthy by comparison: 69 of 70 SL campaigns bridge cleanly on both `funnel_lead.current_campaign_id` and `dim_funnel_channel.campaign_id`. If GP revenue is eventually joined per-lead, it will inherit this same SL-clean / HC-broken asymmetry, and Home Care being in or out of GP scope is already open as a question in the epic.

DTS-4180's own ticket history confirms this independently and makes it worse than a join problem. Ankit Mandloi (In Progress, last updated 2026-09-04) found that HC `campaign_id` is not populated in `prod.funnel_lead` at all; the IDs have to be regex-parsed out of `hmcrequest.url`, and of ~5.3M rows in Steve Reilly's extraction query **~3.8M have no campaign ID**, ~600K HC rows in `funnel_lead` are not returned by the query at all, `hmcrequest` has no column that distinguishes Google from Bing, and the null-URL rows are not merely organic — they include SEO, PingPost, and API leadsources. Steve's 9/4 suggestion (recover the nulls from `prod_homecare_insite_directory.session.landingpageurl`) is the open thread, four days unanswered. DTS-4180 blocks **DTS-4148**, and sits under the same **DTS-4144** epic as DTS-4188. Read across: Home Care attribution is not a gap to be closed by one ETL change, so if this group wants HC revenue in scope, that is a commitment to a URL-parsing recovery project, not a column add.

## The six kickoff decisions — still Open

Due 2026-08-28. None recorded as answered. Route them by name rather than to the room.

|   # | Decision                                                     | Ask of                                                                                                                                   |
| --: | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
|   1 | Primary audience and top 5 questions, in her own GP language | **Tiffany Wise**                                                                                                                         |
|   2 | Which GP company / company database is in scope              | **Tiffany Wise**                                                                                                                         |
|   3 | Databricks catalog/schema/table names for the GP extracts    | Data team (ours to state: `main.prod_gp_apfm_dbo`, `main.prod_gp_capfm_dbo`, `main.prod_gp_dynamics_dbo`)                                |
|   4 | Whether to request the missing `GL00105` and `SOP30200`      | Group — see blockers 1–2. **Partly self-answered:** the epic's own open decision 4 calls `SOP30200` "cheap insurance," not a requirement |
|   5 | First Genie agent scope: GL, AR, or full GP finance          | Group                                                                                                                                    |
|   6 | Golden SQL examples to validate before the build             | Data team + **Bron Tamulis** to validate                                                                                                 |

Decision 5 is the one that unblocks everything else. A Genie agent holds at most 30 tables (Databricks recommends ≤5) against a 59-table estate, so this is four agents — Financials, Receivables & Collections, Budget vs Actual, Currency & System — and someone has to pick which one is first.

## The five blockers — asks, not workarounds

|   # | Blocker                                       | Ask                                                                                                                      | Route to                                         |
| --: | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------ |
|   1 | `SOP30200` not ingested by Fivetran           | Add it to the connector — but as *cheap insurance*, not a hard blocker. The epic resolves invoice lines through the IPR bridge at **98.7%** (`ipr_invoice.gp_invoice_num` → `sop30300.sopnumbe`, 613,879 of 622,066), so ask for it on cost/benefit rather than urgency | **Kate Grimshaw** (Lakeflow Connect / ingestion) |
|   2 | `GL00105` (Account Index Master) not ingested | Add it, or accept assembled account strings and document the 5-segment assumption                                        | **Kate Grimshaw**                                |
|   3 | `RM00101` PII masking undecided               | Decide before Agent 2 is tuned — **applying column masks disables entity matching on that table**                        | Finance + Data Platform                          |
|   4 | `gl30000` last replicated **2026-01-31**      | **Withdraw — this is not a blocker.** `_fivetran_synced` advances only on row change, and 2026-01-31 is the FY2025 close, so the table is correct rather than stale. Monitor connector `succeeded_at` instead. Do not send anyone to investigate a healthy connector | **Kate Grimshaw**                                |
|   5 | Only **2 of 7** live GP companies replicated  | Confirm the other five are out of scope by design                                                                        | **Tiffany Wise**                                 |

On blocker 5, the missing companies are AgingCare, APFM Holdings, SeniorAdvisor.com, Tomorrow's Guides, and APFM UK. No consolidated question is answerable until that is settled, so it is a scope decision, not a backlog item. The epic adds a useful data point: 100% of APFM GL activity — all 8,204,550 rows, FY2000–2026 — carries Company segment `10`, so one company database really does equal one legal entity.

**Blocker 4 is withdrawn** (see the row above), so the route-to cell there is moot — nothing to hand Kate. That leaves **three** GP connector asks, not four, and blocker 1 is a judgement call rather than a hard stop. Say this plainly; walking in with a padded blocker list is how a Low-priority epic stays Low.

Blocker 3 gates a phase. Blockers 1 and 2 land on **Kate** as ingestion-path owner — and so, right now, does **DTS-4188**, which is In Progress with a dev prototype and parked on two questions to Kate that have been open since 9/2 and 9/3. That is two GP connector asks plus a live marketing one, all queued behind the same person. Raise them as one sequencing conversation with a named grain per request rather than five tickets trickling in independently, and clear the DTS-4188 questions verbally while she is in the room.

## One thing waiting on a go

Phase 1 of the playbook — **3,313 reviewable Unity Catalog comments and tags** across all 59 GP tables and 2,169 columns — is **generated but not applied**. It is described as the single highest-leverage step in the build, because Genie's accuracy comes mostly from column descriptions and every one of those 2,169 columns is currently uncommented. `TRXSORCE`, `ACTINDX`, `NJRNLENT` mean nothing to a model without help.

This needs a reviewer, and **Bron** is the GP expert on the call. Ask for his review time.

Related correctness rule to state out loud once, because it will otherwise surface as "the numbers are wrong": **16% of rows in this estate are Fivetran tombstones, and 82–99.9% in the tables users will actually ask about.** Omitting `_fivetran_deleted = false` overstates `gl20000` activity roughly **5.7×**.

## What we still do not have from them

**Correction, pulled from Jira 2026-09-08: the pain-points list was delivered.** Tiffany posted it as a comment on DTS-4187 on 2026-08-28 at 11:17, hours after kickoff, and edited it at 11:30. It never made it into this vault, which is why earlier drafts of this note listed it as outstanding. Do not ask her for it again — thank her for it and use it. Her five, condensed:

1. Community and customer-service teams **cannot see balance due or past due in Salesforce**. They email collections instead, which creates manual work, response delays, knowledge gaps, and hands customers from team to team — "a known customer frustration."
2. CAMs and Community Operations **cannot see write-off balances or bad-debt recovery** for customers sent to collections. To identify approved non-partners to target for acquisition, Tiffany reviews *thousands* by hand.
3. **"There is no end to end view of the customer journey"** — she wants write-offs by marketing channel, by advisor, payment behaviour with versus without CWS, write-off by care type, and other lead attributes.
4. **YGL holds only one Primary Invoicing ID (ERP/GP ID) at a time.** A known GP flaw forces a new ERP ID when a customer pays at parent level and later switches orgs; replacing it in YGL loses the property's history. She wants all ERPs sharing a property ID tied together for complete community payment history.
5. **New Primary Invoicing IDs are created manually, one community at a time.** Moving the field to Salesforce would allow bulk upload; ideally it would be automated.

Two things to say back to her in this meeting. **Pain point 3 is the GP↔funnel join**, unprompted and in her own words — "write-offs by marketing channel" is exactly the `ipr` → `funnel_lead.lead_id` → `family_file_id` path in section 2, which as of 2026-09-08 is measured at **100% for FY2023 forward**. So that section is not just a response to a stated need rather than an inference; it is a response with the join rate already proven. And **points 4 and 5 are `SF-1869`** (*Add field, Primary Invoicing ID and sync to YGL*, To Do since 2026-08-24), referenced in the epic's own appendix — so her top operational pain already has a ticket that nobody has connected to this project out loud.

Still genuinely outstanding:

- **Current data workflows.** Explicitly noted as the thing that drives design.
- **The questions they are trying to answer**, in their words. We have 21 candidates and 4 must-haves in [[GP to Genie Candidate Questions and Follow-Ups]], all reverse-engineered from the requirements workbook rather than from them. Tiffany's pain points narrow this considerably but are not the same artifact — a pain point is not a question a Genie agent can be graded against.
- **Dedicated time with Bron, Jill, and Jimmy** on the GP Data ticket. This action item carried 2026-08-31 → 2026-09-01 and then dropped out of the notes without being closed. Re-book it in the meeting rather than after.

Jill Leos and Jimmy Bui have no recorded statement anywhere in the vault — attendee lists only. Worth finding out in this call what each of them actually owns, because right now we cannot route anything to them.

## Capture list

Write these down live, since the kickoff notes were the last capture and everything since has been inference:

- Tiffany's top 5 questions, verbatim, in GP report/window language
- The GP company answer for both decision 2 and blocker 5
- Which of the four agents is first
- Whether Sales and Purchasing are in or out
- Who reviews the 3,313 metadata statements, and by when
- Whether **Home Care** is in GP scope — the epic lists it as open, and the cost side shows HC behaves differently enough that it can't be assumed in
- What Jill and Jimmy own
- **Kate's two DTS-4188 answers** — which `geo_target_*` columns to promote, and where the DMA/MSA mapping table lives. Post them straight to the ticket so Shivani is unblocked today.
- **Tiffany's real deadline**, and whether **Bolu Fatunmbi** knows he is the assignee on DTS-4187
- **The first two or three child tickets under DTS-4187**, written in the meeting. An epic with zero children is the actual blocker; leave with work that can be assigned
- Whether Tiffany's pain points 4 and 5 are already covered by **`SF-1869`**, or whether this project needs to own them

## Links

- [[Finance Semantic Layer]] — folder note, epic DTS-4187 summary and open decisions
- [[Kickoff Meeting 2026-08-28]] — raw kickoff notes, the only capture of the group speaking
- [[GP to Genie Candidate Questions and Follow-Ups]] — 4 must-have + 21 candidate questions, the six decisions
- [[GP to Genie/A Genie Playbook for Dynamic GP|A Genie Playbook for Dynamics GP]] — build phases, known blockers
- [[GP to Genie/GP to Genie|GP to Genie]] — table inventory, prefixes, YGL customer-mapping counts
- [[Trevor Greer - Genie Space Setup Questions]] — scoping/interview questions to run live if the room has capacity

## Source

The cost-side section above is drawn from an external evidence document, not a vault note:

`~/Documents/Codex/2026-08-28/using/outputs/google-ads-dma-lead-cost-table-inventory.docx`

*Google Ads DMA Spend and Lead-Level Cost Attribution — table inventory, join candidates, and recommended path for CMAM DMA breakout.* Audience: Marketing Analytics, Data Platform, and CMAM stakeholders. Evidence date 2026-08-31, workspace profile `dbc-88a3d066-4cdb`. Contains the recommended table tiers, the SL/Grace and Home Care lead-level cost paths, the attribution caveats, four starter analyst queries, and the DTS-4188 field-level request spec (identity/grain, location, performance, lineage).

Not staged into the vault. If the DMA work becomes a standing thread, transcribe it into `raw_sources/` and give it its own note near the marketing-cost material rather than here — this note only borrows the parts that bear on GP.
