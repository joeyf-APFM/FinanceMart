-- Power BI query shape 356 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            14
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             2,096,546
-- Rows returned         105,784
-- Avg duration          1,450 ms
-- Power BI datasets     9385d9b6-44eb-425a-97c7-734e023fef3f
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.accountstatustype, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatussubreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization, prod_homecare_actransactional_organization.providerstatustype
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    a.accountid,
    a.name AS AccountName,
    ast.name AS AccountStatus,
    a.iscorporateaccount,
    o.orderid,
    o.name AS OrderName,
    ost.name AS OrderStatus,
    osrt.name AS OrderReason,
    CASE
      WHEN LOWER(o.name) LIKE '%corporate%' OR LOWER(o.name) LIKE '%national%'
      THEN 'Yes'
      ELSE 'No'
    END AS CorporateNationalOrder,
    p.providerid,
    CASE
      WHEN ost.name IN ('Active', 'Paused') OR osrt.name = 'Monthly Cap Reached'
      THEN 'Active+'
      ELSE 'Inactive'
    END AS Status,
    p.name AS ProviderName,
    pst.name AS YGLProviderStatus,
    po.name AS OrganizationName
  FROM main.prod_homecare_actransactional_billing.account AS a
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.accountid = a.accountid
  LEFT JOIN main.prod_homecare_actransactional_billing.accountstatustype AS ast
    ON ast.accountstatustypeid = a.accountstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.orderid = o.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = op.providerid
  LEFT JOIN main.prod_homecare_actransactional_organization.providerstatustype AS pst
    ON pst.providerstatustypeid = p.providerstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_organization.providerorganization AS po
    ON po.providerorganizationid = p.providerorganizationid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
    ON ost.orderstatustypeid = o.orderstatustypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
    ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatussubreasontype AS obst
    ON obst.orderstatussubreasontypeid = o.orderstatussubreasontypeid
  ORDER BY
    a.accountid,
    o.orderid,
    p.providerid
), CTEA AS (
  SELECT
    *
  FROM CTE
  WHERE
    corporatenationalorder = 'Yes' AND status = 'Active+'
), CTEB AS (
  SELECT
    *
  FROM cte
  WHERE
    corporatenationalorder = 'No' AND status = 'Active+'
)
SELECT
  CASE
    WHEN NOT CTEA.providerid IS NULL AND NOT CTEb.providerid IS NULL
    THEN 'Both'
    WHEN NOT CTEA.providerid IS NULL AND CTEb.providerid IS NULL
    THEN 'Corporate Only'
    WHEN CTEA.providerid IS NULL AND NOT CTEb.providerid IS NULL
    THEN 'Individual Only'
    ELSE 'Other'
  END AS OrderType,
  CTE.*
FROM CTE
LEFT JOIN CTEA
  ON CTEa.providerid = cte.providerid
LEFT JOIN CTEB
  ON CTEB.providerid = cte.providerid
