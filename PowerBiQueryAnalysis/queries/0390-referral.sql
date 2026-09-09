-- Power BI query shape 390 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            7
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             2,569,813
-- Rows returned         5,062
-- Avg duration          759 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH cte AS (
  SELECT
    COUNT(DISTINCT referralid) AS Referrals,
    CAST(Referredon AS DATE) AS ReferredOn,
    DATE_FORMAT(Referredon, 'yyyyMM') AS MonthYearID,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  WHERE
    NOT hmcleadid IS NULL AND ref.referredon >= '2025' AND ref.billingtypeid = 3
  GROUP BY
    2,
    3,
    4
), CTEA AS (
  SELECT
    ReferredOn,
    MonthYearID,
    Org,
    SUM(Referrals) OVER (PARTITION BY MonthYearID, org ORDER BY ReferredOn) AS RunningReferrals
  FROM CTE
  GROUP BY
    referredon,
    monthyearid,
    referrals,
    org
)
SELECT
  CTE.*,
  RunningReferrals
FROM CTE
LEFT JOIN CTEA
  ON CTEA.Referredon = cte.referredon AND ctea.org = cte.org
