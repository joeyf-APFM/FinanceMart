-- Power BI query shape 229 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            220
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             60,485,964
-- Rows returned         60,763,166
-- Avg duration          1,676 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_recruitment.applicant
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ApplicantID,
  CreatedOn
FROM prod_homecare_actransactional_recruitment.applicant
