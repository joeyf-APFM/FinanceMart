-- Power BI query shape 206 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            242
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,086,539,436
-- Rows returned         3,156,072
-- Avg duration          21,645 ms
-- Power BI datasets     0e88940d-a1f3-4c92-b384-af62bb64e2e4
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.accountstatusreasontype, prod_homecare_actransactional_billing.accountstatustype, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    p.providerid,
    psc.postalcode
  FROM main.prod_homecare_actransactional_organization.provider AS p
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = p.providerid
  WHERE
    p.providerorganizationid = 123 AND psc.deleted = 0
), CTEA AS (
  SELECT
    cte.providerid,
    COUNT(DISTINCT cte.postalcode) AS PostalCodes
  FROM CTE
  GROUP BY
    1
), CTEB AS (
  SELECT
    cte.postalcode,
    COUNT(DISTINCT cte.providerid) AS Providers
  FROM cte
  GROUP BY
    1
)
SELECT DISTINCT
  CTE.Providerid,
  CTE.Postalcode,
  CTEA.PostalCodes AS Provider_PostalCodes,
  CTEB.providers AS ProvidersinPostalcode,
  ost.name AS AccountStatus,
  osrt.name AS AccountReason
FROM CTE
LEFT JOIN CTEA
  ON ctea.providerid = cte.providerid
LEFT JOIN CTEB
  ON cteb.postalcode = cte.postalcode
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
  ON op.providerid = cte.providerid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
  ON o.orderid = op.orderid
LEFT JOIN main.prod_homecare_actransactional_billing.account AS a
  ON a.accountid = o.accountid
LEFT JOIN main.prod_homecare_actransactional_billing.accountstatustype AS ost
  ON ost.accountstatustypeid = a.accountstatustypeid
LEFT JOIN main.prod_homecare_actransactional_billing.accountstatusreasontype AS osrt
  ON osrt.accountstatusreasontypeid = a.accountstatusreasontypeid
