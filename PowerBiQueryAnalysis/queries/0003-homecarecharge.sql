-- Power BI query shape 3 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5,081
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             61,963,133,932
-- Rows returned         552,658,473
-- Avg duration          12,770 ms
-- Power BI datasets     36a8e73a-5aae-46e5-a621-b847af424af7, 728529db-9b31-4ce3-9fd4-4fdf844d7334, 75a0183c-2c90-4d23-9c69-cdb19108448e, af940fd5-99cd-4e93-a620-822230b10ce8, eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.deliverylog, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    r.ReferralID,
    r.LeadID,
    l.HMCProspectID,
    hmcr.HMCRequestID,
    l.ExternalIdentifier AS YGL_Lead_ID,
    r.ProviderID,
    r.BillingTypeID,
    ReferralStatusTypeID,
    ReferredOn,
    CASE WHEN NOT hmcl.HotTransferred IS NULL THEN 1 ELSE 0 END AS HT,
    CASE WHEN r.IsTopOff = 1 THEN 1 ELSE 0 END AS TopOffQueue,
    CASE
      WHEN r.AddOnTypeID = 1
      THEN 'AddOn'
      WHEN r.AddOnTypeID = 2
      THEN 'NeighborZip'
      WHEN r.AddOnTypeID = 3
      THEN 'ZipAddOn'
      ELSE NULL
    END AS AddOnType,
    CASE WHEN r.addontypeid IN (1, 2, 3) THEN 1 ELSE 0 END AS AddOn,
    r.CreatedOn,
    CAST(ReturnApproved AS INT),
    r.HMCLeadID,
    OrderID,
    CASE WHEN p.IsPace = 1 THEN 1 ELSE 0 END AS PaceReferral,
    CAST(hcc.IsHotTransfer AS INT),
    hcc.Amount,
    CASE
      WHEN r.BillingTypeID = 1
      THEN 18
      WHEN hcc.AccountID = 2426
      AND log.DeliveryStatusTypeID IN (2, 3)
      AND hcc.CreatedOn >= '2024-11-06'
      AND hcc.IsHotTransfer = 0
      THEN 0
      WHEN hcc.AccountID = 2426
      AND hcc.Amount < 0
      AND hcc.CreatedOn >= '2024-12-01'
      AND hcc.IsHotTransfer = 0
      THEN hcc.Amount
      WHEN hcc.AccountID = 2426
      AND hcc.Amount > 0
      AND hcc.CreatedOn >= '2024-12-01'
      AND hcc.IsHotTransfer = 0
      THEN hcc.Amount
      WHEN hcc.AccountID = 2426
      AND log.DeliveryStatusTypeID IN (2, 3)
      AND hcc.CreatedOn >= '2024'
      AND hcc.IsHotTransfer = 0
      THEN -42
      WHEN hcc.AccountID = 2426
      AND hcc.Amount < 0
      AND hcc.CreatedOn >= '2024'
      AND hcc.IsHotTransfer = 0
      THEN -42
      WHEN hcc.AccountID = 2426
      AND hcc.Amount > 0
      AND hcc.CreatedOn >= '2024'
      AND hcc.IsHotTransfer = 0
      THEN 42
      WHEN hcc.AccountID = 2426 AND hcc.Amount < 0 AND hcc.IsHotTransfer = 0
      THEN -34
      WHEN hcc.AccountID = 2426 AND hcc.Amount > 0 AND hcc.IsHotTransfer = 0
      THEN 34
      WHEN hcc.AccountID = 2426 AND hcc.IsHotTransfer = 1
      THEN 0
      ELSE hcc.Amount
    END AS ReferralRevenue
  FROM prod_homecare_actransactional_homecare.referral AS r
  LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
    ON r.LeadID = l.LeadID
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON p.ProviderID = r.ProviderID
  LEFT JOIN prod_homecare_actransactional_billing.homecarecharge AS hcc
    ON hcc.ReferralID = r.ReferralID AND hcc.IsCredit = 0
  LEFT JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.HMCLeadID = r.HMCLeadID
  LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcl.HMCRequestID = hmcr.HMCRequestID
  LEFT JOIN (
    SELECT
      DeliveryLogID,
      DeliveryName,
      ReferralID,
      DeliveryStatusTypeID
    FROM prod_homecare_actransactional_homecare.deliverylog
    WHERE
      DeliveryName = 'HomeInsteadProvider'
  ) AS log
    ON hcc.ReferralID = log.ReferralID
  WHERE
    1 = 1
    AND r.createdon >= '2024-08-22'
    AND /* AND BillingTypeID = 3 */ NOT r.HMCLeadID IS NULL
    AND hmcr.createdate > '2024-08-22'
  ORDER BY
    ReferredOn DESC
), CTE2 AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY HMCRequestID ORDER BY ReferralRevenue DESC) AS ReferralCount
  FROM CTE
  WHERE
    IsHotTransfer = 0
  ORDER BY
    ReferralID DESC
), CTE3 AS (
  SELECT
    ref.*,
    ROW_NUMBER() OVER (PARTITION BY ref.HMCRequestID ORDER BY AddOn DESC) AS rn
  FROM CTE2 AS ref
  RIGHT JOIN (
    SELECT
      HMCRequestID
    FROM CTE2
    GROUP BY
      HMCRequestID
    HAVING
      COUNT(ReferralID) > 4
  ) AS req
    ON req.HMCRequestID = ref.HMCRequestID
  WHERE
    ReferralCount = 5 OR Addon = 1
)
SELECT
  *
FROM CTE3
WHERE
  rn = 1
