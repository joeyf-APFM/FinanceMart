-- Power BI query shape 4 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            5,059
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             124,649,595
-- Rows returned         186,072,069
-- Avg duration          1,706 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, 75a0183c-2c90-4d23-9c69-cdb19108448e, af940fd5-99cd-4e93-a620-822230b10ce8, da74b405-09e2-41e3-bed6-583fc3c4acae, eda315a6-a542-4102-b6ce-3551c75b1bdd, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_reporting.dimcampaign, prod_homecare_acreporting_reporting.factdailycampaigncost
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    fdcc.CampaignKey,
    dc.CampaignName,
    dc.CampaignSource,
    dc.CampaignID,
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
    Cost,
    ROW_NUMBER() OVER (PARTITION BY dc.CampaignKey, CampaignSource, DateID ORDER BY CampaignName) AS rn
  FROM prod_homecare_acreporting_reporting.factdailycampaigncost AS fdcc
  LEFT JOIN prod_homecare_acreporting_reporting.dimcampaign AS dc
    ON dc.CampaignKey = fdcc.CampaignKey
  WHERE
    DateID >= 20211231
  ORDER BY
    DateID DESC
)
SELECT
  *
FROM CTE
WHERE
  rn = 1
