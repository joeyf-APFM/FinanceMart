-- Power BI query shape 32 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,260
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             2,107,954,894
-- Rows returned         2,002,200
-- Avg duration          3,824 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_billing.account, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    ProviderHistoryID,
    Date,
    cph.ProviderID,
    o.OrderID,
    cph.AccountID,
    a.AccountStatusReasonTypeID,
    ProviderName,
    OrderName,
    AccountName,
    cph.ContractType,
    OrderStatus,
    OrderStatusReason,
    cph.MonthlyCap,
    cph.MonthlySent,
    o.CreatedOn AS OrderCreateDate,
    CCFail,
    u2.FirstName AS HCAM,
    u.FirstName AS CSM,
    ROW_NUMBER() OVER (PARTITION BY cph.ProviderID ORDER BY cph.Date) AS rn,
    ROW_NUMBER() OVER (PARTITION BY cph.ProviderID ORDER BY cph.Date DESC) AS DaysSuspended
  FROM prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN prod_homecare_actransactional_billing.account AS a
    ON a.AccountID = cph.AccountID
  LEFT JOIN prod_homecare_actransactional_ordermanagement.order AS o
    ON o.OrderID = cph.OrderID
  LEFT JOIN prod_homecare_actransactional_organization.provider AS p
    ON p.ProviderID = cph.ProviderID
  LEFT JOIN prod_homecare_actransactional_auth.users AS u
    ON u.UserID = AccountSpecialistUserID
  LEFT JOIN prod_homecare_actransactional_auth.users AS u2
    ON u2.UserID = HCAMUserID
  WHERE
    a.AccountStatusReasonTypeID IN (1, 23)
    AND cph.ContractType = 'CPL'
    AND OrderStatus = 'Suspended'
    AND OrderStatusReason = 'Account Suspended'
), CTE1 AS (
  SELECT
    *,
    LAG(Date) OVER (PARTITION BY ProviderID ORDER BY Date) AS LagDate
  FROM CTE
  ORDER BY
    ProviderID,
    Date
), CTE2 AS (
  SELECT
    *,
    DATEDIFF(DAY, LagDate, Date) AS DaysBetweenSusp
  FROM CTE1
  WHERE
    DATEDIFF(DAY, LagDate, Date) > 1 OR LagDate IS NULL
  ORDER BY
    ProviderID
), CTE3 AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY ProviderID ORDER BY Date DESC) AS new_rn
  FROM CTE2
  ORDER BY
    ProviderID,
    Date
), CTE4 AS (
  SELECT
    *,
    LAG(Date) OVER (PARTITION BY ProviderID ORDER BY Date) AS FirstSusp
  FROM CTE3
  WHERE
    rn = 1 OR new_rn = 1
  ORDER BY
    ProviderID,
    OrderID,
    Date DESC
)
SELECT
  *
FROM CTE4
WHERE
  new_rn = 1
