-- Power BI query shape 204 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            244
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             132,307,229
-- Rows returned         132,307,229
-- Avg duration          3,598 ms
-- Power BI datasets     da74b405-09e2-41e3-bed6-583fc3c4acae
-- Tables                prod_homecare_actransactional_homecare.addonreferral
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  AddOnReferralID,
  ProviderID,
  OrderID,
  CASE WHEN PickedUpOn IS NULL THEN 0 ELSE 1 END AS AcceptedAddon,
  ReferralID,
  CreatedOn,
  CASE
    WHEN r.addontypeid = 1
    THEN 'Add-On'
    WHEN r.addontypeid = 2
    THEN 'Zip'
    WHEN r.addontypeid = 3
    THEN 'Zip Add-On'
  END AS Addon
FROM prod_homecare_actransactional_homecare.addonreferral AS r
