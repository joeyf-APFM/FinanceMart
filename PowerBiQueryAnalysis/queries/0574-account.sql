-- Power BI query shape 574 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             865,695
-- Rows returned         19,119
-- Avg duration          6,827 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.accountstatustype, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    a.AccountID,
    a.name AS AcccountName,
    ast.name AS AccountStatus,
    a.accountstatusreasonnote,
    o.orderid,
    o.name AS OrderName,
    ost.name AS OrderStatus,
    osrt.name AS OrderStatusReason,
    p.providerid,
    p.name AS ProviderName
  FROM main.prod_homecare_actransactional_billing.account AS a
  LEFT JOIN main.prod_homecare_actransactional_billing.accountstatustype AS ast
    ON ast.accountstatustypeid = a.accountstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.accountid = a.accountid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
    ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.orderid = o.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = op.providerid
  WHERE
    ast.name = 'Closed' AND o.billingtypeid = 3
), CTEA AS (
  SELECT
    CTE.ProviderID,
    COUNT(DISTINCT o.orderid) AS OtherOrders
  FROM CTE
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.providerid = cte.providerid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = op.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  WHERE
    ost.name IN ('Active', 'Paused', 'Suspended') AND o.billingtypeid = 3
  GROUP BY
    1
), CTEB AS (
  SELECT
    CTE.ProviderID,
    COUNT(DISTINCT o.orderid) AS OnboardingOrders
  FROM CTE
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.providerid = cte.providerid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = op.orderid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  WHERE
    ost.name = 'Onboarding' AND o.billingtypeid = 3
  GROUP BY
    1
)
SELECT
  CTE.*,
  CTEA.OtherOrders,
  CTEB.onboardingorders
FROM CTE
LEFT JOIN CTEA
  ON CTEA.ProviderID = CTE.ProviderID
LEFT JOIN CTEB
  ON CTEB.ProviderID = CTE.ProviderID
