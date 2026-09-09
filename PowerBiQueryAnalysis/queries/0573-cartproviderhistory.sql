-- Power BI query shape 573 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             718,500
-- Rows returned         42,424
-- Avg duration          3,660 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.contact, prod_homecare_actransactional_organization.contacttype, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providercontact, prod_homecare_actransactional_organization.providercontactcontacttype
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT /* p.Name AS 'Provider Name', */
  c.FirstName,
  c.LastName,
  c.Email,
  p.ProviderID
/* ,p.ProviderOrganizationID */
/* ,c.Phone */
/* ,ct.Name */
/* ,c.Title */
FROM prod_homecare_actransactional_organization.providercontact AS pc
LEFT JOIN prod_homecare_actransactional_organization.contact AS c
  ON c.ContactID = pc.ContactID
LEFT JOIN prod_homecare_actransactional_organization.provider AS p
  ON p.ProviderID = pc.ProviderID
LEFT JOIN prod_homecare_actransactional_organization.providercontactcontacttype AS pcct
  ON pcct.ProviderContactID = pc.ProviderContactID
LEFT JOIN prod_homecare_actransactional_organization.contacttype AS ct
  ON ct.ContactTypeID = pcct.ContactTypeID
LEFT JOIN prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  ON cph.ProviderID = p.ProviderID
WHERE
  1 = 1
  AND c.Email NOT LIKE '%agingcare.com%'
  AND c.Email NOT LIKE '%aplaceformom%'
  AND /* AND p.Name LIKE '%Interim%' */ c.Deleted = 0
  AND pc.Deleted = 0
  AND cph.Date = CAST(CURRENT_TIMESTAMP() AS DATE)
  AND NOT cph.ProviderID IS NULL
