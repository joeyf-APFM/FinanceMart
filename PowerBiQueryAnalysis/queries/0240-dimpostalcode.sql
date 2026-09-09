-- Power BI query shape 240 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            218
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             219,574,161
-- Rows returned         958,726
-- Avg duration          4,104 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimpostalcode, prod_homecare_actransactional_geo.stateprovince, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerstatustype, prod_homecare_insite_dbo.orderstatusreference, prod_homecare_insite_directory.account, prod_homecare_insite_directory.companyinfo, prod_homecare_insite_directory.leadorder, prod_homecare_insite_directory.organization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    ci.ProviderID,
    ci.companyid,
    ci.companyname,
    ci.accountid,
    a.accountname,
    CASE WHEN a.accountid = 10435 THEN 'CPA' ELSE 'CPL' END AS ContractType,
    lo.leadorderid,
    lo.monthlymax AS AccountMonthlyMax,
    osr.OrderStatus,
    a.OrderStatus AS OrderCode,
    osr.OrderStatusCause,
    osr.OrderStatusID
  FROM prod_homecare_insite_directory.companyinfo AS ci
  LEFT JOIN prod_homecare_insite_directory.account AS a
    ON ci.accountid = a.accountid
  LEFT JOIN prod_homecare_insite_dbo.orderstatusreference AS osr
    ON a.OrderStatusID = osr.OrderStatusID
  LEFT JOIN prod_homecare_insite_directory.leadorder AS lo
    ON a.accountid = lo.accountid
  LEFT JOIN prod_homecare_insite_directory.organization AS org
    ON org.OrganizationID = a.OrganizationID
  WHERE
    a.isactive = 1
    AND ci.isactive = 1
    AND (
      NOT osr.OrderStatusID IN (2) OR ci.accountid = 11399
    )
    AND a.accountid <> 50
    AND a.accountid <> 320 /* COMFORT KEEPERS - CHECK IF STILL VALID */
  /* AND ProviderID is null */
  UNION
  SELECT
    prov.ProviderID,
    NULL,
    prov.Name AS Provider,
    NULL,
    NULL,
    'CPA',
    NULL,
    NULL,
    pst.Name AS OrderStatus,
    NULL,
    NULL,
    NULL
  FROM prod_homecare_actransactional_organization.provider AS prov
  LEFT JOIN prod_homecare_acreporting_reporting.dimpostalcode AS pcv
    ON TRIM(prov.PostalCodeID) = TRIM(pcv.PostalCodeID)
  LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS sp
    ON pcv.StateProvinceID = sp.StateProvinceID
  LEFT JOIN prod_homecare_actransactional_organization.providerstatustype AS pst
    ON pst.ProviderStatusTypeID = prov.ProviderStatusTypeID
  WHERE
    (
      prov.BillingTypeID = 1
      AND prov.ProviderStatusTypeID = 1
      AND (
        Iso2Code = 'WA' OR sp.CountryID <> 1
      )
    )
    OR (
      prov.BillingTypeID = 1 AND prov.ProviderStatusTypeID = 2
    )
)
SELECT
  CASE WHEN NOT CTE.ProviderID IS NULL THEN CTE.ProviderID ELSE lo.ProviderID END AS ProviderID,
  CTE.companyid,
  CTE.companyname,
  CTE.accountid,
  CTE.accountname,
  CTE.ContractType,
  CASE WHEN NOT lo.ProviderID IS NULL THEN 1 ELSE 0 END AS RecruitmentOrder,
  CTE.leadorderid,
  CTE.AccountMonthlyMax,
  CTE.OrderStatus,
  CTE.OrderCode,
  CTE.OrderStatusCause,
  CTE.OrderStatusID,
  CASE
    WHEN OrderCode = 'S' AND OrderStatusID <> 7
    THEN 1
    WHEN ContractType = 'CPA' AND OrderStatus = 'Suspended'
    THEN 1
    ELSE 0
  END AS Suspended
FROM CTE
FULL OUTER JOIN (
  SELECT DISTINCT
    ProviderID
  FROM prod_homecare_actransactional_ordermanagement.order AS o
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON o.OrderID = op.OrderID
  WHERE
    OrderStatusTypeID IN (1, 5) AND ServiceTypeID = 1
) AS lo
  ON CTE.ProviderID = lo.ProviderID
WHERE
  CTE.ProviderID > 0 OR CTE.ProviderID IS NULL
ORDER BY
  ProviderID ASC
