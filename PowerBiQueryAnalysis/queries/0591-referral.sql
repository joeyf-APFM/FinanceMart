-- Power BI query shape 591 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             28,645,552
-- Rows returned         5,361
-- Avg duration          1,851 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_insite_dbo.users, prod_homecare_insite_directory.hmcfollowupsurveyresult, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    sr.hmcprospectid,
    sr.outcomeid,
    MONTH(sr.createdate) AS Month,
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
), CTE1 AS (
  SELECT
    CTE.hmcprospectid,
    CTE.hmcfollowupsurveyresultid,
    CTE.AttemptCount,
    CTE.Connnections,
    Ref.Activations,
    CTE.SLPP,
    CTE.usercode,
    CTE.Month
  FROM CTE
  LEFT JOIN (
    SELECT
      hmcr.hmcprospectid,
      CASE WHEN NOT ref.activatedon IS NULL THEN ref.referralid ELSE NULL END AS Activations
    FROM prod_homecare_insite_directory.hmcrequest AS hmcr
    JOIN prod_homecare_insite_directory.hmclead AS hmcl
      ON hmcl.hmcrequestid = hmcr.hmcrequestid
    JOIN prod_homecare_actransactional_homecare.referral AS ref
      ON ref.hmcleadid = hmcl.hmcleadid
  ) AS ref
    ON ref.hmcprospectid = CTE.hmcprospectid
), CTE2 AS (
  SELECT
    Month,
    attemptcount,
    usercode,
    COUNT(DISTINCT hmcfollowupsurveyresultid) AS TotalCalls,
    COUNT(DISTINCT Connnections) AS Connections,
    COUNT(DISTINCT SLPP) AS SLPP,
    COUNT(DISTINCT hmcprospectid) AS TotalProspects,
    COUNT(DISTINCT Activations) AS Activations
  FROM CTE1
  GROUP BY
    1,
    2,
    3
)
SELECT
  Month,
  AttemptCount,
  usercode,
  (
    Connections / TotalCalls
  ) AS ConnectionRate,
  Connections,
  TotalCalls,
  SLPP,
  TotalProspects,
  Activations,
  Activations / TotalProspects AS ActivationRate,
  SLPP / TotalProspects AS SLPPRate
FROM CTE2
ORDER BY
  2,
  1,
  3
