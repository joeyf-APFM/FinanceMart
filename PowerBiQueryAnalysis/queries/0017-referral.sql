-- Power BI query shape 17 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,948
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             5,320,078,404
-- Rows returned         5,182,257,711
-- Avg duration          9,655 ms
-- Power BI datasets     aa36e346-e2cc-4210-a366-8c48278fcdbd, af940fd5-99cd-4e93-a620-822230b10ce8, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  r.*,
  p.name
FROM prod_homecare_actransactional_homecare.referral AS r
JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.providerid = r.providerid
WHERE
  r.createdon >= '2024-01-01' AND NOT r.hmcleadid IS NULL
