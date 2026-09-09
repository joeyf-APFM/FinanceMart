-- Power BI query shape 143 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            381
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             817,358,384
-- Rows returned         20,679,482
-- Avg duration          4,029 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_acreporting_reporting.facthomecarereferraltransaction, prod_homecare_insite_directory.hmccallbackresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    HMCCallBackResultID,
    HMCProspectID,
    createdate,
    outcomeid,
    userid,
    AttemptCount,
    FollowUpDate,
    SecondsInProspect,
    HMCRequestID,
    SurveyResponse,
    HMCCallBackReason,
    ROW_NUMBER() OVER (PARTITION BY HMCRequestID ORDER BY createdate) AS rn
  FROM prod_homecare_insite_directory.hmccallbackresult
  WHERE
    outcomeid <> 15 AND createdate > '2021-07-21'
  ORDER BY
    HMCRequestID
), CTE1 AS (
  SELECT
    *
  FROM CTE
  WHERE
    rn = 1
)
SELECT DISTINCT
  RequestID,
  temp.HMCRequestID,
  temp.HMCProspectID,
  LeadSentDateID,
  temp.createdate,
  AccountID,
  DATEDIFF(DAY, TO_DATE(LeadSentDateID, 'yyyyMMdd'), temp.createdate) AS DATE_DIFF,
  CASE WHEN NOT HMCRequestID IS NULL THEN 1 ELSE 0 END AS Survey_Callback,
  CASE
    WHEN NOT HMCRequestID IS NULL
    AND DATEDIFF(DAY, TO_DATE(LeadSentDateID, 'yyyyMMdd'), temp.createdate) <= 14
    THEN 1
    ELSE 0
  END AS 14_Day_Survey
FROM prod_homecare_acreporting_reporting.facthomecarereferraltransaction AS hcrt
LEFT JOIN CTE1 AS temp
  ON hcrt.RequestID = temp.HMCRequestID
WHERE
  LeadSentDateID >= 20210721 AND AccountID = 10435
ORDER BY
  LeadSentDateID DESC
