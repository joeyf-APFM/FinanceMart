-- Power BI query shape 177 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            281
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             36,221,171
-- Rows returned         16,859,486
-- Avg duration          2,145 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimcampaign, prod_homecare_acreporting_reporting.factdailycampaigncost
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  fdcc.CampaignKey,
  dc.CampaignName,
  dc.CampaignSource,
  CASE
    WHEN dc.CampaignSource = 'Bing'
    THEN 'SEM - Bing'
    WHEN CampaignSource = 'Google'
    THEN 'SEM - Google'
    WHEN CampaignSource = 'Yahoo'
    THEN 'SEM - Bing'
  END AS SEM_Source,
  CASE
    WHEN dc.CampaignName LIKE '%T1%'
    OR dc.CampaignName LIKE '%Tier_1%'
    OR dc.CampaignName LIKE '%Tier1%'
    THEN 'T1'
    WHEN dc.CampaignName LIKE '%T2%'
    OR dc.CampaignName LIKE '%Tier_2%'
    OR dc.CampaignName LIKE '%T3%'
    OR dc.CampaignName LIKE '%Tier_3%'
    OR dc.CampaignName LIKE '%alll%'
    THEN 'T2'
    WHEN NOT dc.CampaignName IS NULL
    THEN 'Other'
  END AS SEM_Tier,
  CASE
    WHEN dc.CampaignName LIKE '%HighValue%'
    OR dc.CampaignName LIKE '%MidValue%'
    OR dc.CampaignName = 'Competitor'
    OR dc.CampaignName = 'Brand'
    THEN 'New Structure'
    ELSE 'Old Structure'
  END AS SEM_Structure,
  DateID,
  Cost
FROM prod_homecare_acreporting_reporting.factdailycampaigncost AS fdcc
LEFT JOIN prod_homecare_acreporting_reporting.dimcampaign AS dc
  ON dc.CampaignKey = fdcc.CampaignKey
WHERE
  DateID > 20210000
ORDER BY
  DateID DESC
