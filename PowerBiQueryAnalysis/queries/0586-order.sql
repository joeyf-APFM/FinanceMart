-- Power BI query shape 586 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             151,482
-- Rows returned         2,284
-- Avg duration          690 ms
-- Power BI datasets     none recorded
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
  DATEDIFF(DAY, o.createdon, CURRENT_TIMESTAMP()) <= 90
  AND ost.name <> 'Onboarding'
  AND p.providerorganizationid IS NULL
