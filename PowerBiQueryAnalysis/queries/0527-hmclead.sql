-- Power BI query shape 527 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             8,686,351
-- Rows returned         6,007
-- Avg duration          4,734 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    hmcr.hmcrequestid,
    CAST(hmcr.createdate AS DATE) AS CreateDate,
    DATE_ADD(DAY, 2, DATE_TRUNC('MONTH', hmcr.createdate)) AS First3Days,
    DATE_ADD(DAY, -2, LAST_DAY(hmcr.createdate)) AS Last3Days,
    DATE_FORMAT(hmcr.createdate, 'yyyyMM') AS MonthYearID,
    dma.dma
  FROM main.prod_homecare_insite_directory.hmcrequest AS hmcr
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcr.hmcrequestid = hmcl.hmcleadid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = TRIM(hmcr.postalcode)
  WHERE
    hmcr.createdate >= '2024' AND hmcr.requeststatusid = 2
), CTE1 AS (
  SELECT
    DMA,
    MonthYearID,
    CASE
      WHEN createdate >= Last3Days AND CreateDate <= LAST_DAY(createdate)
      THEN hmcrequestid
      ELSE NULL
    END AS Last3DayRls,
    CASE
      WHEN createdate <= First3Days AND CreateDate >= DATE_TRUNC('MONTH', createdate)
      THEN hmcrequestid
      ELSE NULL
    END AS First3DayRls,
    createdate,
    hmcrequestid
  FROM CTE
)
SELECT
  DMA,
  MonthYearID,
  COUNT(DISTINCT hmcrequestid) AS TotalRls,
  COUNT(DISTINCT Last3DayRls) AS Last3DayRls,
  COUNT(DISTINCT First3DayRls) AS First3DayRls
FROM cte1
WHERE
  DMA <> 'NA'
GROUP BY
  1,
  2
