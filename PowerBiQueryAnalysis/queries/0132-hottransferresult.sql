-- Power BI query shape 132 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            419
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,387,247,597
-- Rows returned         740,553,504
-- Avg duration          4,892 ms
-- Power BI datasets     c65e1078-f986-4629-8d3f-50f7370b5719
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
  HT,
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
