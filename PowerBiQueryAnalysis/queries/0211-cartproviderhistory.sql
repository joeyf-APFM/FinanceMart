-- Power BI query shape 211 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            234
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             3,389,380,748
-- Rows returned         41,436,472
-- Avg duration          16,647 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c, 36a8e73a-5aae-46e5-a621-b847af424af7
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_acreporting_reporting.dimcustomeracquisition, prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_acreporting_reporting.facthomecarerequestsummary, prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_geo.stateprovince, prod_homecare_actransactional_organization.providerservicecoverage, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    COUNT(DISTINCT (
      hmcr.hmcrequestid
    )) AS Leads,
    hmcr.postalcode,
    CAST(hmcr.createdate AS DATE) AS createdate,
    SUM(DISTINCT (
      ppc.providercount
    )) AS Provider_Count,
    sp.name AS State
  FROM prod_homecare_acreporting_reporting.facthomecarerequestsummary AS hcrs
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequest AS dhcr
    ON hcrs.RequestID = dhcr.RequestID
  LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.HMCRequestID = hcrs.RequestID
  LEFT JOIN prod_homecare_acreporting_reporting.dimcustomeracquisition AS dca
    ON dca.CustomerAcquisitionKey = dhcr.CustomerAcquisitionKey
  LEFT JOIN prod_homecare_actransactional_geo.postalcode_01072025 AS pcv
    ON pcv.code = hmcr.postalcode
  LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS sp
    ON sp.StateProvinceID = pcv.StateProvinceID
  LEFT JOIN (
    SELECT
      COUNT(DISTINCT (
        cph.providername
      )) AS providercount,
      psc.PostalCode,
      cph.Date
    FROM prod_homecare_actransactional_organization.providerservicecoverage AS psc
    LEFT JOIN prod_homecare_acreporting_reporting.cartproviderhistory AS cph
      ON cph.providerid = psc.providerid
    WHERE
      psc.deleted = 0
      AND cph.Date > DATE_ADD(MONTH, -3, CURRENT_TIMESTAMP())
      AND (
        OrderStatus = 'Active' OR OrderStatusReason = 'Monthly Cap Reached'
      )
      AND ContractType = 'CPL'
    GROUP BY
      psc.PostalCode,
      cph.Date
  ) AS ppc
    ON ppc.postalcode = hmcr.postalcode AND ppc.Date = CAST(hmcr.createdate AS DATE)
  WHERE
    hmcr.createdate >= DATE_ADD(MONTH, -3, CURRENT_TIMESTAMP())
    AND NOT affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108)
  GROUP BY
    hmcr.postalcode,
    CAST(hmcr.createdate AS DATE),
    sp.name
)
SELECT
  *,
  CASE
    WHEN Provider_Count IS NULL
    THEN Leads * 1.5
    WHEN Provider_Count < 7
    THEN Leads * 1.5 / Provider_Count
    WHEN Provider_Count > 10
    THEN Leads * 0.8 / Provider_Count
    ELSE Leads * 1.0 / Provider_Count
  END AS Provider_Value,
  Leads * 1.0 / Provider_Count AS Base_Value
FROM CTE
ORDER BY
  postalcode,
  createdate DESC
