-- Power BI query shape 162 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            298
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             565,018,581
-- Rows returned         2,542,877
-- Avg duration          3,094 ms
-- Power BI datasets     c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    CONCAT(p.providerid, '-', o.orderid) AS ProviderOrder
  FROM main.prod_homecare_actransactional_organization.provider AS p
  JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.providerid = p.providerid
  JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = op.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
    ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
  WHERE
    o.createdon >= '2025'
    AND ost.name <> 'Onboarding'
    AND p.providerorganizationid IS NULL
), CTEB AS (
  SELECT
    COUNT(DISTINCT ref.referralid) AS Referrals,
    CONCAT(ref.providerid, '-', ref.orderid) AS ProviderOrder,
    CASE WHEN ref.returnapproved = TRUE THEN 1 ELSE 0 END AS ReturnApproved
  FROM main.prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  WHERE
    ref.referredon >= '2024'
    AND ref.billingtypeid = 3
    AND NOT ref.hmcleadid IS NULL
    AND p.providerorganizationid IS NULL
  GROUP BY
    2,
    3
), CTEA AS (
  SELECT
    COUNT(DISTINCT ref.referralid) AS Activations,
    CONCAT(ref.providerid, '-', ref.orderid) AS ProviderOrder
  FROM main.prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  WHERE
    ref.referredon >= '2024'
    AND ref.billingtypeid = 3
    AND NOT ref.hmcleadid IS NULL
    AND p.providerorganizationid IS NULL
    AND NOT ref.activatedon IS NULL
  GROUP BY
    2
)
SELECT
  CTE.ProviderOrder,
  CASE WHEN CTEB.Referrals IS NULL THEN 'No' ELSE 'Yes' END AS RecievedReferrals,
  CASE WHEN CTEA.Activations IS NULL THEN 'No' ELSE 'Yes' END AS RecievedActivatons
FROM CTE
LEFT JOIN CTEB
  ON CTEB.providerorder = cte.providerorder
LEFT JOIN CTEA
  ON ctea.providerorder = cte.providerorder
