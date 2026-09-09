-- Power BI query shape 103 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            712
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             3,625,086,083
-- Rows returned         14,277,787
-- Avg duration          8,798 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.providerid,
  p.name AS ProviderName,
  cph.orderid,
  o.createdon AS OrderCreateDate,
  ost.name AS CurrentOrderStatus,
  osrt.name AS CurrentOrderStatusReasonType,
  u2.FirstName AS HCAM,
  u.FirstName AS CSM
FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
LEFT JOIN prod_homecare_actransactional_ordermanagement.`order` AS o
  ON o.orderid = cph.OrderID
LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.orderstatustypeid = o.orderstatustypeid
LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
  ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.ProviderID = cph.ProviderID
LEFT JOIN prod_homecare_actransactional_auth.users AS u
  ON u.UserID = AccountSpecialistUserID
LEFT JOIN prod_homecare_actransactional_auth.users AS u2
  ON u2.UserID = HCAMUserID
WHERE
  cph.date >= '2025'
