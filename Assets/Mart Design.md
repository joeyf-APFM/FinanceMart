# Finance Mart Design for APFM

> [!warning] Superseded as a build plan — read as aspiration, not as scope
> This note predates the Dynamics GP evidence and models the finance mart around `dim_family`, `fact_marketing_spend`, and unit economics. The buildable subset against sources that are actually replicated is *Finance Catalog and Mart Design 2026-09-09* (vault: `plans/2026-09-09-finance-catalog-and-mart-design`, not in this repo), which lays out a `finance` catalog with marts as schemas and a `common` catalog for `dim_date` / `dim_fiscal_calendar`.
>
> Two differences worth knowing before using anything below. **`fact_marketing_spend`, `fact_sales_advisor_cost`, and the whole Unit Economics Mart are out of scope** — no spend source is replicated, and marketing cost is DTS-4188 / DTS-4180 territory. And **`dim_partner` here collides with GP's notion of a customer**: GP's "customer" is who APFM bills, resolving at `business_unit_id` grain — a community — so the design note treats `dim_customer` as the billing-account view of a partner that bridges to the conformed `dim_partner` rather than replacing it.

## In this folder

| Note | Contents |
|---|---|
| [Finance Catalog DDL](Finance%20Catalog%20DDL.md) | The DDL for the `finance` and `common` catalogs — conventions, build order, verification tests, and what is deliberately absent. Eleven SQL files under `ddl/`, none executed |
| `ddl/*.sql` | The executable artifact, in dependency order `01`–`11`. Every file carries a `STATUS: NOT EXECUTED` banner |

Everything below this line is the original aspirational model — see the warning above.

---

A finance data mart for A Place for Mom should be organized around the economics of a senior care referral marketplace: how demand is acquired, how families move through the funnel, how referrals convert, how partners are billed, and whether the unit economics are healthy.

At the center, the mart should use finance-facing fact tables that connect referral activity, move-in or activation outcomes, partner billing, marketing spend, and operating cost.

| Fact table | Grain | What it answers |
|---|---:|---|
| `fact_referral_revenue` | One referral or billing event | What revenue was earned, from which partner, for which care journey? |
| `fact_move_in_commission` | One move-in or activation | What commission or fee was triggered by a successful placement? |
| `fact_home_care_referral_fee` | One home care referral event | What referral fees were earned from home care agencies? |
| `fact_marketing_spend` | Campaign, channel, and day | How much was spent to acquire family demand? |
| `fact_sales_advisor_cost` | Advisor and period | What labor cost supports conversion and guidance? |
| `fact_partner_invoice` | Invoice line | What was billed, collected, adjusted, refunded, or written off? |
| `fact_finance_adjustment` | Adjustment event | What revenue was reversed, disputed, credited, or manually adjusted? |

The key dimensions should be conformed with the broader APFM business model.

| Dimension | Purpose |
|---|---|
| `dim_family` or `dim_household` | Longitudinal customer/family spine |
| `dim_lead` | Inquiry episode, source, timing, and consent state |
| `dim_care_need` | Care type, urgency, budget, geography, and acuity |
| `dim_referral` | Referral action, referred partner, and status |
| `dim_partner` | Senior living community or home care agency |
| `dim_location` | Market, region, DMA, state, and ZIP |
| `dim_channel` | Paid search, organic, affiliate, call, partner, brand, and related acquisition channels |
| `dim_advisor` | Advisor, team, region, and assignment |
| `dim_date` | Reporting calendar, fiscal period, and cohort period |
| `dim_contract` | Partner contract terms, fee model, and effective dates |

The finance mart should likely split into two related analytical layers.

## Revenue Mart

Tracks gross revenue, net revenue, billable move-ins, home care referral fees, partner invoice status, collections, credits, disputes, cancellations, and revenue recognition timing.

Example metrics:

- `gross_referral_revenue`
- `net_referral_revenue`
- `billable_move_ins`
- `average_revenue_per_move_in`
- `collection_rate`
- `refund_rate`
- `revenue_per_partner`
- `revenue_by_care_type`

## Unit Economics Mart

Connects finance to funnel activity: marketing spend, leads, qualified families, referrals, tours, move-ins, advisor effort, and partner conversion.

Example metrics:

- `cost_per_lead`
- `cost_per_qualified_lead`
- `cost_per_move_in`
- `lead_to_referral_rate`
- `referral_to_move_in_rate`
- `revenue_per_lead`
- `gross_margin_per_move_in`
- `payback_period`
- `ltv_to_cac`

## Simplified Star Schema

```text
dim_family
   |
dim_lead -- fact_referral_revenue -- dim_partner -- dim_contract
   |                 |
dim_care_need        dim_date
   |
fact_marketing_spend -- dim_channel
   |
fact_move_in_commission
   |
fact_partner_invoice
```

## Modeling Notes

The durable finance spine should connect family or household, care need, referral, partner, and outcome. A lead should be modeled as an acquisition episode, not as the enduring customer entity. A referral is an APFM action, while move-in, activation, or payable home-care referral is the monetizable outcome.
