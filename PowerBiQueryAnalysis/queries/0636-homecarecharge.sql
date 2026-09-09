-- Power BI query shape 636 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             4,052,806
-- Rows returned         91
-- Avg duration          2,596 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.deliverylog, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    ref.referralid,
    ref.providerid,
    ref.referredon,
    CONCAT(ref.orderid, '-', ref.providerid) AS ProviderOrder,
    ref.orderid,
    op.createdon,
    DATEDIFF(DAY, o.createdon, CURRENT_TIMESTAMP()) AS OrderAge,
    DATEDIFF(DAY, o.createdon, ref.referredon) AS ReferralAge,
    p.name AS ProviderName,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    CASE WHEN ref.returnapproved = TRUE THEN 1 ELSE 0 END AS ReturnApproved,
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
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.order AS op
    ON op.orderid = ref.orderid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = ref.orderid
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
    ref.referredon >= '2023'
    AND op.createdon >= '2023'
    AND ref.billingtypeid = 3
    AND NOT ref.hmcleadid IS NULL
    AND (
      LOWER(p.name) NOT LIKE '%home instead%'
      AND LOWER(p.name) NOT LIKE 'senior helpers%'
    )
    AND DATEDIFF(DAY, o.createdon, CURRENT_TIMESTAMP()) >= 180
    AND DATEDIFF(DAY, o.createdon, ref.referredon) <= 180
), CTE1 AS (
  SELECT DISTINCT
    SUM(ReferralRevenue) AS ReferralRev,
    ProviderOrder,
    Org
  FROM CTE
  WHERE
    returnapproved = 0
  GROUP BY
    providerorder,
    org
)
SELECT
  CONCAT(
    (
      FLOOR(ReferralRev / 500) * 500
    ),
    '-',
    (
      FLOOR(ReferralRev / 500) * 500
    ) + 500
  ) AS ReferralBucket,
  COUNT(DISTINCT ProviderOrder) AS ProviderOrders,
  (
    FLOOR(ReferralRev / 500) * 500
  ) AS sort,
  org
FROM CTE1
GROUP BY
  CONCAT(
    (
      FLOOR(ReferralRev / 500) * 500
    ),
    '-',
    (
      FLOOR(ReferralRev / 500) * 500
    ) + 500
  ),
  (
    FLOOR(ReferralRev / 500) * 500
  ),
  org
