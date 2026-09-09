-- Power BI query shape 9 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            3,210
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             124,330
-- Rows returned         1,053,115
-- Avg duration          392 ms
-- Power BI datasets     728529db-9b31-4ce3-9fd4-4fdf844d7334, f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_reporting.dimcampaign
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  CampaignKey,
  CampaignSource,
  CampaignID,
  CASE
    WHEN CampaignID = '18462205636'
    THEN 'HighValueT3'
    WHEN CampaignID = '18462205639'
    THEN 'MidValueT3'
    WHEN CampaignID = '18462209188'
    THEN 'MidValueT4'
    WHEN CampaignID = '18462209191'
    THEN 'HighValueT4'
    WHEN CampaignID = '18931315335'
    THEN 'HighValueT1 _CPA Test'
    WHEN CampaignID = '19088386289'
    THEN 'HighValueT1 _Interested_Test'
    WHEN CampaignID = '19830715574'
    THEN 'MidValueT1'
    WHEN CampaignID = '20159729698'
    THEN 'Mobile - Caregivers - T2'
    WHEN CampaignID = '20159729695'
    THEN 'Mobile - Caregivers - T1'
    WHEN CampaignID = '20108844850'
    THEN 'Desktop - Caregivers - T1'
    WHEN CampaignID = '20131684937'
    THEN 'Desktop - Caregivers - T2'
    WHEN CampaignID = '20156319791'
    THEN 'Non Brand + Location - Caregivers'
    WHEN CampaignID = '20259897987'
    THEN 'Mobile - Home Health Care - T1'
    WHEN CampaignID = '20259897990'
    THEN 'Mobile - Home Health Care - T2'
    WHEN CampaignID = '20259897981'
    THEN 'Desktop - Home Health Care - T1'
    WHEN CampaignID = '20259897984'
    THEN 'Desktop - Home Health Care - T2'
    WHEN CampaignID = '20268857185'
    THEN 'Non Brand - Location - Home Health Care'
    WHEN CampaignID = '21386079262'
    THEN 'NB:NAT:Memory Care:T1:Exact'
    WHEN CampaignID = '21386079292'
    THEN 'NB:NAT:Memory Care:T1'
    WHEN CampaignID = '21671962742'
    THEN 'Desktop - Home Health Care Agency - T1 _Quick-Fill_Test'
    WHEN CAMPAIGNID = '22202164461'
    THEN 'NB:NAT:Partner Network:T1:All'
    WHEN CAMPAIGNID = '638662372'
    THEN 'HomeCare - PMAX - MSFT'
    WHEN CAMPAIGNID = '22388527326'
    THEN 'Desktop - Agencies and Orgs - T1 DMA_ConvValueMod_Test'
    WHEN CAMPAIGNID = '22398509662'
    THEN 'Desktop - Caregivers - T1 DMA_ConvValueMod_Test'
    ELSE CampaignName
  END AS CampaignName
FROM prod_homecare_acreporting_reporting.dimcampaign
WHERE
  (
    (
      NOT CampaignName IS NULL OR CampaignKey >= 191
    )
    AND NOT CampaignID IN ('19582092870', '12794166142', '19582100304', '-1')
    AND CampaignKey <> 198
  )
