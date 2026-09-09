-- Power BI query shape 97 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            864
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             933,806,860
-- Rows returned         937,576,207
-- Avg duration          9,010 ms
-- Power BI datasets     a16a1e37-9a12-408d-ad05-9ea2571cb037, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_homecare.referralnote, prod_homecare_actransactional_homecare.referralprocessstage
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  rn.*,
  rps.name
FROM prod_homecare_actransactional_homecare.referralnote AS rn
JOIN prod_homecare_actransactional_homecare.referralprocessstage AS rps
  ON rps.ReferralProcessStageID = rn.ReferralProcessStageID
