-- Power BI query shape 580 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             9,552,178
-- Rows returned         22,153
-- Avg duration          1,555 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.deliverylog, prod_homecare_actransactional_homecare.referral
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    CASE WHEN ref.activatedon IS NULL THEN NULL ELSE ref.referralid END AS Activation,
    ref.providerID,
    ref.orderid,
    ref.referralid,
    CASE WHEN ref.returnapproved = TRUE THEN ref.referralid ELSE NULL END AS ReturnedReferrals,
    CONCAT(ref.providerid, '-', ref.orderid) AS ProviderOrderID,
    CASE
      WHEN ref.BillingTypeID = 1
      THEN 18
      WHEN hcc.AccountID = 2426
      AND log.DeliveryStatusTypeID IN (2, 3)
      AND hcc.CreatedOn >= '2024-11-06'
      AND hcc.IsHotTransfer = 0
      THEN 0
      WHEN hcc.AccountID = 2426
      AND hcc.Amount < 0
      AND hcc.CreatedOn >= '2024-11-22 21:33:00'
      AND hcc.IsHotTransfer = 0
      THEN hcc.Amount
      WHEN hcc.AccountID = 2426
      AND hcc.Amount > 0
      AND hcc.CreatedOn >= '2024-11-22 21:33:00'
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
  FROM main.prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN prod_homecare_actransactional_billing.homecarecharge AS hcc
    ON hcc.ReferralID = ref.ReferralID AND hcc.IsCredit = 0
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
    NOT hmcleadid IS NULL AND ref.billingtypeid = 3
)
SELECT
  ProviderOrderID,
  COUNT(DISTINCT referralid) AS TotalReferral,
  COUNT(DISTINCT returnedreferrals) AS Returnedreferrak,
  COUNT(DISTINCT Activation) AS Activation,
  SUM(referralrevenue) AS Rev
FROM CTE
GROUP BY
  1
