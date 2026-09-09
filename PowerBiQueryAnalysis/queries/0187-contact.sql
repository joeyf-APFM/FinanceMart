-- Power BI query shape 187 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            265
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             52,203,311
-- Rows returned         18,355,221
-- Avg duration          6,494 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c
-- Tables                prod_homecare_actransactional_organization.contact, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providercontact
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.providerid,
  p.name AS ProviderName,
  p.providerorganizationid,
  c.email,
  c.firstname,
  c.lastname,
  c.phone
FROM main.prod_homecare_actransactional_organization.provider AS p
LEFT JOIN main.prod_homecare_actransactional_organization.providercontact AS pc
  ON pc.providerid = p.providerid
LEFT JOIN main.prod_homecare_actransactional_organization.contact AS c
  ON c.contactid = pc.contactid
WHERE
  c.deleted = 0
  AND pc.deleted = 0
  AND c.Email NOT LIKE '%agingcare.com%'
  AND c.Email NOT LIKE '%aplaceformom%'
