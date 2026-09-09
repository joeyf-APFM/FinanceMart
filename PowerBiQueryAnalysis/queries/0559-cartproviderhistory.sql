-- Power BI query shape 559 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             13,437,952
-- Rows returned         61,979
-- Avg duration          25,609 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.providerservicecoverage, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    MIN(cph.date) AS Date,
    LAST_DAY(cph.date) AS LastDay,
    cph.providerid,
    psc.postalcode
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  WHERE
    cph.date >= '2025'
    AND cph.orderstatusreason = 'Monthly Cap Reached'
    AND LOWER(cph.providername) LIKE 'home instead%'
    AND psc.deleted = 0
  GROUP BY
    2,
    3,
    4
)
SELECT
  hmcr.hmcrequestid,
  hmcr.hmcprospectid,
  TRIM(hmcr.postalcode) AS PostalCode,
  CAST(hmcr.createdate AS DATE) AS RequestCreateDate,
  CASE
    WHEN hmcp.residentname IS NULL
    OR hmcp.residentname = ''
    AND NOT hmcr.residentname IS NULL
    THEN hmcr.residentname
    ELSE hmcp.residentname
  END AS ResidentName
FROM CTE
JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
  ON TRIM(hmcr.postalcode) = CTE.postalcode
  AND CAST(hmcr.createdate AS DATE) >= CTE.Date
  AND CAST(hmcr.createdate AS DATE) <= CTE.LastDay
LEFT JOIN main.prod_homecare_insite_directory.hmcprospect AS hmcp
  ON hmcp.hmcprospectid = hmcr.hmcprospectid
WHERE
  hmcr.requeststatusid = 6
