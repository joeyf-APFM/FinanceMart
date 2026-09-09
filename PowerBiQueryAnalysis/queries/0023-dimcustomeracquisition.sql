-- Power BI query shape 23 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,473
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             38,375,747,834
-- Rows returned         222,528,903
-- Avg duration          6,093 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483, b23c969a-4a6b-4d76-bea0-6e46dcac27aa, c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_acreporting_reporting.dimcustomeracquisition, prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    r.ReferralID,
    r.LeadID,
    r.ProviderID,
    l.HMCProspectID,
    l.ExternalIdentifier AS YGL_Lead_ID,
    BillingTypeID,
    ReferralStatusTypeID,
    ReferredOn,
    CASE WHEN NOT hmcl.HotTransferred IS NULL THEN 1 ELSE 0 END AS HT,
    ActivatedOn,
    r.HMCLeadID,
    OrderID,
    hcc.Amount,
    CASE
      WHEN r.OrderID = 2774
      THEN 34
      WHEN r.BillingTypeID = 1
      THEN 18
      ELSE hcc.Amount
    END AS ReferralRevenue,
    CASE
      WHEN (
        r.HMCLeadID IS NULL AND BillingTypeID = 1
      )
      THEN 1
      WHEN dca.Source = 'APFM Screened Leads'
      THEN 1
      ELSE 0
    END AS APFM
  FROM prod_homecare_actransactional_homecare.referral AS r
  LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
    ON r.LeadID = l.LeadID
  LEFT JOIN prod_homecare_actransactional_billing.homecarecharge AS hcc
    ON hcc.ReferralID = r.ReferralID AND hcc.IsCredit = 0
  LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.HMCLeadID = r.HMCLeadID
  LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcl.HMCRequestID = hmcr.HMCRequestID
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequest AS dhcr
    ON hmcr.HMCRequestID = dhcr.RequestID
  LEFT JOIN prod_homecare_acreporting_reporting.dimcustomeracquisition AS dca
    ON dca.CustomerAcquisitionKey = dhcr.CustomerAcquisitionKey
  WHERE
    r.ReferredOn > '2023-01-01' AND BillingTypeID = 1
)
SELECT
  t.ReferralID,
  t.LeadID,
  t.ProviderID,
  ActDate,
  NumProv,
  t.ReferredOn,
  t.HT,
  CASE WHEN NOT ActivatedOn IS NULL THEN 1 ELSE 0 END AS Activation,
  grp.HT AS AnyHT,
  grp.Activation AS AnyActivation,
  'APFM' AS BusinessUnit
FROM CTE AS t
LEFT JOIN (
  SELECT
    LeadID,
    SUM(HT) AS HT,
    COUNT(ActivatedOn) AS Activation,
    MIN(ActivatedOn) AS ActDate,
    COUNT(ReferralID) AS NumProv
  FROM CTE
  GROUP BY
    LeadID
) AS grp
  ON grp.LeadID = t.LeadID
WHERE
  APFM = 1
ORDER BY
  t.LeadID DESC
