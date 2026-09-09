-- Power BI query shape 632 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,338,422
-- Rows returned         1,000
-- Avg duration          2,464 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.providerid,
  o.orderid,
  CASE
    WHEN ost.name = 'Suspended' AND orst.name = 'Monthly Cap Reached'
    THEN 'Monthly Cap Reached'
    ELSE ost.name
  END AS OrderStatus,
  orst.name AS OrderStatusReason
FROM main.prod_homecare_actransactional_organization.provider AS p
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
  ON op.providerid = p.providerid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.orderid = op.orderid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.orderstatustypeid = o.orderstatustypeid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS orst
  ON orst.orderstatusreasontypeid = o.orderstatusreasontypeid
LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
  ON psc.providerid = p.providerid
LEFT JOIN main.prod_homecare_actransactional_geo.postalcode_01072025 AS pc
  ON pc.postalcodeid = psc.postalcodeid
WHERE
  psc.deleted = 0 AND pc.countryid = 1
