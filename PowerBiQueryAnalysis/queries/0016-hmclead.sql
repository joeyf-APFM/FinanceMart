-- Power BI query shape 16 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,949
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             9,513,871,395
-- Rows returned         5,193,920,331
-- Avg duration          6,760 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, a16a1e37-9a12-408d-ad05-9ea2571cb037, aa36e346-e2cc-4210-a366-8c48278fcdbd, af940fd5-99cd-4e93-a620-822230b10ce8, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  r.HMCRequestID,
  l.HMCLeadID,
  r.postalcode,
  r.requeststatusid,
  r.createdate
FROM prod_homecare_insite_directory.hmcrequest AS r
JOIN prod_homecare_insite_directory.hmclead AS l
  ON l.HMCRequestID = r.HMCRequestID
WHERE
  r.createdate >= '2024-01-01' AND r.requeststatusid = 2
