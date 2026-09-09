-- Power BI query shape 114 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            571
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             3,513,001,227
-- Rows returned         1,083,383,986
-- Avg duration          8,271 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, b19514eb-b858-44d5-81a1-2c1a2e9f1483
-- Tables                prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    ref.leadid, /* ,ref.billingtypeid */ /* ,ref.referredon */
    SUM(CASE WHEN ref.activatedon IS NULL THEN NULL ELSE 1 END) AS Activated,
    COUNT(DISTINCT ref.providerid) AS NumProv,
    SUM(CASE WHEN htr.hottransferresponseid = 1 THEN 1 ELSE NULL END) AS HT
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN prod_homecare_actransactional_homecare.hottransferresult AS htr
    ON htr.referralid = ref.referralid
  WHERE
    referredon >= '2024'
  GROUP BY
    ref.leadid
  ORDER BY
    ref.leadid
)
SELECT DISTINCT
  ref.referralid,
  ref.leadid,
  CASE WHEN CTE.Activated IS NULL THEN 'No' ELSE 'Yes' END AS AnyActivations,
  NumProv,
  CASE WHEN HT IS NULL THEN 'No' ELSE 'Yes' END AS HT,
  temp.Name AS HTProvider,
  temp2.Activatedon
FROM prod_homecare_actransactional_homecare.referral AS ref
LEFT JOIN (
  SELECT
    p.name,
    ref.referralid,
    ref.leadid,
    htr.hottransferresponseid
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN prod_homecare_actransactional_homecare.hottransferresult AS htr
    ON htr.referralid = ref.referralid
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = htr.providerid
  WHERE
    htr.hottransferresponseid = 1 AND ref.referredon >= '2024'
) AS temp
  ON temp.leadid = ref.leadid
LEFT JOIN (
  SELECT
    r.leadid,
    r.activatedon
  FROM prod_homecare_actransactional_homecare.referral AS r
  WHERE
    NOT r.activatedon IS NULL
) AS temp2
  ON temp2.leadid = ref.leadid
LEFT JOIN CTE
  ON CTE.leadid = ref.leadid
WHERE
  ref.referredon >= '2024'
ORDER BY
  ref.leadid
