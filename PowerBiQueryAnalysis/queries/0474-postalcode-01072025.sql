-- Power BI query shape 474 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             255,203
-- Rows returned         61,156
-- Avg duration          691 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.providerid,
  o.orderid,
  CASE
    WHEN ost.name = 'Suspended' AND orst.name = 'Monthly Cap Reached'
    THEN 'Monthly Cap Reached'
    ELSE ost.name
  END AS OrderStatus,
  orst.name AS OrderStatusReason,
  po.name AS Organization,
  p.providerorganizationid,
  p.name AS ProviderName
FROM main.prod_homecare_actransactional_organization.provider AS p
JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
  ON op.providerid = p.providerid
JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.orderid = op.orderid
JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.orderstatustypeid = o.orderstatustypeid
JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS orst
  ON orst.orderstatusreasontypeid = o.orderstatusreasontypeid
LEFT JOIN main.prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
JOIN main.prod_homecare_actransactional_geo.postalcode_01072025 AS pc
  ON pc.code = p.postalcode
WHERE
  ost.name <> 'Onboarding' AND countryid = 1
