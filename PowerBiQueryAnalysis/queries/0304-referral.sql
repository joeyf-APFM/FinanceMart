-- Power BI query shape 304 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            58
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             149,885,604
-- Rows returned         43,123
-- Avg duration          4,573 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    o.orderid,
    ost.name AS OrderStatus,
    orst.name AS OrderStatusReason,
    op.providerid,
    o.createdon
  FROM prod_homecare_actransactional_ordermanagement.order AS o
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS orst
    ON orst.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.orderid = o.orderid
  WHERE
    DATEDIFF(DAY, o.createdon, CURRENT_TIMESTAMP()) <= 60
), CTEA AS (
  SELECT
    ref.providerid,
    ref.orderid,
    MIN(activatedon) AS FirstActivation
  FROM prod_homecare_actransactional_homecare.referral AS ref
  WHERE
    NOT activatedon IS NULL
  GROUP BY
    1,
    2
), CTEB AS (
  SELECT
    COUNT(DISTINCT ref.referralid) AS Referrals,
    COUNT(DISTINCT CASE WHEN ref.returnapproved = TRUE THEN ref.referralid ELSE NULL END) AS ReturnApproved,
    ref.orderid,
    ref.providerid
  FROM prod_homecare_actransactional_homecare.referral AS ref
  WHERE
    NOT ref.hmcleadid IS NULL AND ref.billingtypeid = 3
  GROUP BY
    3,
    4
)
SELECT DISTINCT
  ref.providerid,
  CTE.orderid,
  CASE
    WHEN DATEDIFF(DAY, CTE.createdon, FirstActivation) <= 20
    THEN 'In First 20'
    WHEN DATEDIFF(DAY, CTE.createdon, FirstActivation) > 20
    THEN 'After First 20'
    WHEN FirstActivation IS NULL
    THEN 'No Activations'
  END AS ActivationTimeFrame,
  CTE.createdon,
  CTEB.Referrals,
  p.name AS ProviderName,
  CTEB.ReturnApproved,
  CASE
    WHEN CTEB.ReturnApproved / CTEB.Referrals >= 0.10
    THEN 'High Returns'
    ELSE 'Normal Returns'
  END AS ReturnVolume
FROM prod_homecare_actransactional_homecare.referral AS ref
JOIN CTE
  ON CTE.providerid = ref.providerid AND ref.orderid = CTE.orderid
LEFT JOIN CTEA
  ON CTEA.providerid = ref.providerid AND ref.orderid = CTEA.orderid
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = ref.providerid
LEFT JOIN CTEB
  ON CTEB.orderid = ref.orderid AND CTEB.providerid = ref.providerid
WHERE
  p.providerorganizationid IS NULL
