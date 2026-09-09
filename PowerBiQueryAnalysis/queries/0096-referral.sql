-- Power BI query shape 96 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            864
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             1,908,404,172
-- Rows returned         1,916,058,048
-- Avg duration          11,748 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, a16a1e37-9a12-408d-ad05-9ea2571cb037, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_homecare.referral
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  rh.*,
  CASE WHEN returnapproved = TRUE THEN 1 ELSE 0 END AS returnapproved1
FROM prod_homecare_actransactional_homecare.referral AS rh
WHERE
  rh.createdon >= '2023-01-01' AND NOT hmcleadid IS NULL
