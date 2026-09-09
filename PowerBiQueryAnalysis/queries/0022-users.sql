-- Power BI query shape 22 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,482
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             349,892,273
-- Rows returned         117,545,366
-- Avg duration          1,284 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_actransactional_auth.users, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  ProviderID,
  u.FirstName AS CSM,
  u2.FirstName AS HCAM
FROM prod_homecare_actransactional_organization.provider
LEFT JOIN prod_homecare_actransactional_auth.users AS u
  ON u.UserID = AccountSpecialistUserID
LEFT JOIN prod_homecare_actransactional_auth.users AS u2
  ON u2.UserID = HCAMUserID
ORDER BY
  ProviderID DESC
