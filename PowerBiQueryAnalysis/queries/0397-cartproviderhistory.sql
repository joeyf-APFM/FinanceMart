-- Power BI query shape 397 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            6
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             10,659,238
-- Rows returned         2,611,667
-- Avg duration          2,420 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerservicecoverage, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  cph.providerid,
  CAST(hmcr.createdate AS DATE) AS RequestCreateDate,
  p.name AS ProviderName,
  COUNT(DISTINCT hmcr.hmcrequestid) AS RLs
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
  ON psc.providerid = cph.providerid
LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.postalcode = psc.postalcode
JOIN main.prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = cph.providerid
WHERE
  cph.contracttype = 'CPL'
  AND cph.date = CAST(CURRENT_TIMESTAMP() AS DATE)
  AND (
    cph.orderstatusreason = 'Monthly Cap Reached'
    OR cph.orderstatus IN ('Active', 'Paused')
  )
  AND psc.deleted = 0
  AND hmcr.createdate >= '2025'
GROUP BY
  1,
  2,
  3
