-- Power BI query shape 585 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,359,250
-- Rows returned         606
-- Avg duration          889 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH cte AS (
  SELECT
    COUNT(DISTINCT referralid) AS Referrals,
    CAST(Referredon AS DATE) AS ReferredOn,
    DATE_FORMAT(Referredon, 'yyyyMM') AS MonthYearID
  FROM prod_homecare_actransactional_homecare.referral AS ref
  WHERE
    NOT hmcleadid IS NULL AND ref.referredon >= '2025' AND billingtypeid = 3
  GROUP BY
    2,
    3
), CTEA AS (
  SELECT
    ReferredOn,
    MonthYearID,
    SUM(Referrals) OVER (PARTITION BY MonthYearID ORDER BY ReferredOn) AS RunningReferrals
  FROM CTE
  GROUP BY
    referredon,
    monthyearid,
    referrals
)
SELECT
  CTE.*,
  RunningReferrals
FROM CTE
LEFT JOIN CTEA
  ON CTEA.Referredon = cte.referredon
