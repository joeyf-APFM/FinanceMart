-- Power BI query shape 525 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             7,797,572
-- Rows returned         28,311
-- Avg duration          8,803 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_dbo.users, prod_homecare_insite_directory.hmcfollowupsurveyresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    sr.hmcprospectid,
    sr.outcomeid,
    CAST(sr.createdate AS DATE) AS SurveyCallCreateDate,
    hmcfollowupsurveyresultid,
    usercode,
    CASE WHEN resultactionid = 1 THEN sr.hmcprospectid ELSE NULL END AS SLPP,
    ROW_NUMBER() OVER (PARTITION BY sr.hmcprospectid ORDER BY sr.createdate) AS AttemptCount,
    CASE
      WHEN outcomeid IN (12, 13, 14, 16, 17, 18, 20, 22, 24)
      THEN hmcfollowupsurveyresultid
      ELSE NULL
    END AS Connnections
  FROM prod_homecare_insite_directory.hmcfollowupsurveyresult AS sr
  LEFT JOIN main.prod_homecare_insite_dbo.users AS u
    ON u.userid = sr.userid
  WHERE
    sr.createdate >= '2025' AND sr.outcomeid <> 15
)
SELECT
  COUNT(DISTINCT CTE.hmcfollowupsurveyresultid) AS TotalCalls,
  CTE.AttemptCount,
  COUNT(DISTINCT CTE.Connnections) AS Connections,
  CTE.usercode AS CA,
  SurveyCallCreateDate
FROM CTE
GROUP BY
  2,
  4,
  5
