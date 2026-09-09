-- Power BI query shape 98 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            864
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             3,040,118,223
-- Rows returned         60,759,571
-- Avg duration          5,850 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralnote
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    ref.referralid,
    ref.referredon,
    ref.providerid,
    returnapproved,
    ref.modifiedon,
    rn.createdon AS ReturnApprovedDate,
    CASE
      WHEN DATEDIFF(DAY, ref.referredon, rn.createdon) <= 31
      THEN DATEDIFF(DAY, ref.referredon, rn.createdon)
      ELSE DATEDIFF(MONTH, ref.referredon, rn.createdon)
    END AS TimetoReturns,
    CASE
      WHEN DATEDIFF(DAY, ref.referredon, rn.createdon) = 1
      THEN 'Day'
      WHEN DATEDIFF(DAY, ref.referredon, rn.createdon) <= 31
      THEN 'Days'
      WHEN (
        DATEDIFF(MONTH, ref.referredon, rn.createdon) = 1
        AND DATEDIFF(DAY, ref.referredon, rn.createdon) > 31
      )
      THEN 'Month'
      ELSE 'Months'
    END AS ReturnTimeFrame,
    DATEDIFF(DAY, ref.referredon, rn.createdon) AS Days
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN prod_homecare_actransactional_homecare.referralnote AS rn
    ON rn.referralid = ref.referralid
  WHERE
    referralprocessstageid = 12
    AND ref.referredon >= '2024'
    AND NOT ref.hmcleadid IS NULL
)
SELECT
  CTE.*,
  CONCAT(TimetoReturns, ' ', ReturnTimeFrame) AS TimeToReturn,
  CASE
    WHEN ReturnTimeFrame LIKE 'Day%'
    THEN Timetoreturns
    WHEN ReturnTimeFrame LIKE 'Month%'
    THEN Timetoreturns * 100
  END AS SortID
FROM CTE
ORDER BY
  days
