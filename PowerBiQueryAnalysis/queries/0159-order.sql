-- Power BI query shape 159 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            299
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             26,637,988
-- Rows returned         1,873,309
-- Avg duration          2,058 ms
-- Power BI datasets     c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.name AS ProviderName,
  p.providerid,
  o.name AS OrderName,
  o.orderid,
  o.createdon AS OrderCreateDate,
  CONCAT(p.providerid, '-', o.orderid) AS ProviderOrder,
  DATEDIFF(DAY, o.createdon, CURRENT_TIMESTAMP()) AS DaysActive,
  ost.name AS CurrentOrderStatus,
  osrt.name AS CurrentOrderReason
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
