-- Power BI query shape 319 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            36
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,635,029
-- Rows returned         1,631,620
-- Avg duration          2,935 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ProviderID,
  p.Name,
  Rate,
  ProviderStatusTypeID,
  BillingTypeID,
  OrgID,
  PostalCodeID,
  p.Deleted,
  p.ModifiedOn,
  p.ModifiedBy,
  p.CreatedOn,
  p.CreatedBy,
  po.name AS Organization
FROM prod_homecare_actransactional_organization.provider AS p
LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
  ON po.providerorganizationid = p.providerorganizationid
