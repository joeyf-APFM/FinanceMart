-- Power BI query shape 30 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,263
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             489,103,114
-- Rows returned         7,658,900
-- Avg duration          3,282 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_actransactional_auth.users, prod_homecare_actransactional_billing.account, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT DISTINCT
  o.AccountID,
  a.Name AS AccountName,
  hcamacc.HCAM
FROM prod_homecare_actransactional_ordermanagement.order AS o
LEFT JOIN prod_homecare_actransactional_billing.account AS a
  ON a.AccountID = o.AccountID
LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype AS ost
  ON ost.OrderStatusTypeID = o.OrderStatusTypeID
LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatusreasontype AS osrt
  ON osrt.OrderStatusReasonTypeID = o.OrderStatusReasonTypeID
RIGHT JOIN (
  SELECT DISTINCT
    a.AccountID,
    u2.FirstName AS HCAM
  FROM prod_homecare_actransactional_organization.provider AS p
  LEFT JOIN prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.ProviderID = p.ProviderID
  LEFT JOIN prod_homecare_actransactional_ordermanagement.order AS o
    ON o.OrderID = op.OrderID
  LEFT JOIN prod_homecare_actransactional_billing.account AS a
    ON a.AccountID = o.AccountID
  LEFT JOIN prod_homecare_actransactional_auth.users AS u
    ON u.UserID = AccountSpecialistUserID
  LEFT JOIN prod_homecare_actransactional_auth.users AS u2
    ON u2.UserID = HCAMUserID
  WHERE
    NOT a.AccountID IS NULL AND NOT u2.FirstName IS NULL
) AS hcamacc
  ON hcamacc.AccountID = o.AccountID
WHERE
  (
    NOT osrt.Name IN ('Manual Suspend', 'Account Suspended', 'No Provider Assigned')
    OR osrt.Name IS NULL
  )
  AND ServiceTypeID = 2
  AND BillingTypeID = 3
  AND NOT ost.Name IN ('Completed', 'Cancelled', 'Onboarding')
