-- Power BI query shape 34 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,213
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             213,525,586
-- Rows returned         37,343,678
-- Avg duration          3,861 ms
-- Power BI datasets     aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483, c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  p.*,
  po.name AS Organization
FROM prod_homecare_actransactional_organization.provider AS p
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
LEFT JOIN prod_homecare_actransactional_homecare.referral AS r
  ON p.ProviderID = r.ProviderID
WHERE
  r.ReferredOn >= '2023-01-01' AND NOT r.ProviderID IS NULL
ORDER BY
  p.providerid
