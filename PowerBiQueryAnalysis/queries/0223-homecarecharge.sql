-- Power BI query shape 223 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            221
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             476,487,354
-- Rows returned         241,104
-- Avg duration          5,197 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.deliverylog
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hcc.*,
    log.DeliveryStatusTypeID,
    CASE
      WHEN AccountID = 2426
      AND log.DeliveryStatusTypeID IN (2, 3)
      AND hcc.CreatedOn >= '2024-01-01'
      AND IsHotTransfer = 0
      THEN -42
      WHEN AccountID = 2426
      AND Amount < 0
      AND hcc.CreatedOn >= '2024-01-01'
      AND IsHotTransfer = 0
      THEN -42
      WHEN AccountID = 2426
      AND Amount > 0
      AND hcc.CreatedOn >= '2024-01-01'
      AND IsHotTransfer = 0
      THEN 42
      WHEN AccountID = 2426 AND Amount < 0 AND IsHotTransfer = 0
      THEN -34
      WHEN AccountID = 2426 AND Amount > 0 AND IsHotTransfer = 0
      THEN 34
      WHEN AccountID = 2426 AND IsHotTransfer = 1
      THEN 0
      ELSE Amount
    END AS AmountAdj
  FROM prod_homecare_actransactional_billing.homecarecharge AS hcc
  LEFT JOIN (
    SELECT
      DeliveryLogID,
      DeliveryName,
      ReferralID,
      DeliveryStatusTypeID
    FROM prod_homecare_actransactional_homecare.deliverylog
    WHERE
      DeliveryName = 'HomeInsteadProvider'
  ) AS log
    ON hcc.ReferralID = log.ReferralID
  WHERE
    CreatedOn >= '2023'
)
SELECT DISTINCT
  CAST(CONVERT_TIMEZONE('UTC', 'America/Detroit', CAST(CreatedOn AS TIMESTAMP_NTZ)) AS DATE) AS Date,
  SUM(AmountAdj) AS CPL
FROM CTE
GROUP BY
  CAST(CONVERT_TIMEZONE('UTC', 'America/Detroit', CAST(CreatedOn AS TIMESTAMP_NTZ)) AS DATE)
ORDER BY
  Date DESC
