-- Power BI query shape 194 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            259
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             305,709,273
-- Rows returned         286,462
-- Avg duration          2,296 ms
-- Power BI datasets     95e62086-9ac7-4ac5-81fb-5c045316c4fc
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
    NOT hmcleadid IS NULL
    AND ref.referredon >= '2025'
    AND ref.billingtypeid = 3
    AND (
      ref.returnapproved <> TRUE OR ref.returnapproved IS NULL
    )
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
