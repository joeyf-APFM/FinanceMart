-- Power BI query shape 298 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            60
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             8,323
-- Rows returned         12,180
-- Avg duration          409 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimcampaign
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  CampaignKey,
  CampaignSource,
  CampaignID,
  CampaignName
FROM prod_homecare_acreporting_reporting.dimcampaign
WHERE
  NOT CampaignName IS NULL
