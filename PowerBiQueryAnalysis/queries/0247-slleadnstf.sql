-- Power BI query shape 247 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            146
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             2,509,527,192
-- Rows returned         281,646,538
-- Avg duration          8,030 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_import.slleadnstf, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcscreeningresult
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    sl.hmcrequestid,
    sl.processedon,
    sl.sub_status,
    ROW_NUMBER() OVER (PARTITION BY sr.hmcrequestid ORDER BY sr.hmcscreeningresultid DESC) AS rn,
    sr.outcomeid
  FROM prod_homecare_actransactional_import.slleadnstf AS sl
  LEFT JOIN main.prod_homecare_insite_directory.hmcscreeningresult AS sr
    ON sr.hmcrequestid = sl.hmcrequestid
  WHERE
    outcomeid <> 15
)
SELECT
  CTE.hmcrequestid,
  CTE.processedon,
  CTE.sub_status,
  CTE.outcomeid,
  hmcr.requeststatusid,
  CAST(hmcr.createdate AS DATE) AS RequestCreateDate
FROM CTE
LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.hmcrequestid = CTE.hmcrequestid
WHERE
  RN = 1
