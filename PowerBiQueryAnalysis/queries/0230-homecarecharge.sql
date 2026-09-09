-- Power BI query shape 230 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            220
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             3,084,601,880
-- Rows returned         408,243,115
-- Avg duration          7,907 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    r.ReferralID,
    r.LeadID,
    l.HMCProspectID,
    hmcr.HMCRequestID,
    l.ExternalIdentifier AS YGL_Lead_ID,
    BillingTypeID,
    ReferralStatusTypeID,
    ReferredOn,
    CASE WHEN NOT hmcl.HotTransferred IS NULL THEN 1 ELSE 0 END AS HT,
    r.CreatedOn,
    ReturnApproved,
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
    ROW_NUMBER() OVER (PARTITION BY r.ReferralID ORDER BY r.CreatedOn) AS rn
  FROM prod_homecare_actransactional_homecare.referral AS r
  LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
    ON r.LeadID = l.LeadID
  LEFT JOIN prod_homecare_actransactional_billing.homecarecharge AS hcc
    ON hcc.ReferralID = r.ReferralID AND hcc.IsCredit = 0
  LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.HMCLeadID = r.HMCLeadID
  LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcl.HMCRequestID = hmcr.HMCRequestID
  WHERE
    1 = 1
    AND /* AND BillingTypeID = 3 */ NOT r.HMCLeadID IS NULL
    AND YEAR(hmcr.createdate) >= YEAR(DATE_ADD(YEAR, -2, CURRENT_TIMESTAMP()))
  ORDER BY
    ReferredOn DESC
)
SELECT
  *
FROM CTE
WHERE
  rn = 1
