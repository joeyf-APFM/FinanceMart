-- Power BI query shape 649 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             5,307,291
-- Rows returned         1,000
-- Avg duration          1,469 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_auth.users, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Verbatim as executed; no Power BI envelope to strip.

select `ProviderID`,
    `ProviderName`,
    `OrderID`,
    `OrderCreateDate`,
    `FirstActiveDate`,
    `LastActiveDate`,
    `CurrentOrderStatus`,
    `CurrentOrderStatusReasonType`,
    `HCAM`,
    `CSM`,
    `DaystoCancel`
from 
(
    WITH CTE AS (
      SELECT cph.ProviderID
        ,p.name ProviderName
        ,cph.OrderID
        ,o.createdon AS OrderCreateDate
        ,MIN(Date) AS FirstActiveDate
        ,Max(date) AS LastActiveDate
        ,ost.name As CurrentOrderStatus
        ,osrt.name As CurrentOrderStatusReasonType
        ,u2.FirstName AS HCAM
        ,u.FirstName AS CSM
FROM prod_homecare_acreporting_reporting.cartproviderhistory cph
LEFT JOIN prod_homecare_actransactional_ordermanagement.`order` o ON o.orderid = cph.OrderID
LEFT JOIN prod_homecare_actransactional_ordermanagement.orderstatustype ost ON ost.orderstatustypeid = o.orderstatustypeid
LEFT JOIN  prod_homecare_actransactional_ordermanagement.orderstatusreasontype osrt ON osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
LEFT JOIN prod_homecare_actransactional_organization.provider p ON p.ProviderID = cph.ProviderID
LEFT JOIN prod_homecare_actransactional_auth.users u ON u.UserID = AccountSpecialistUserID
LEFT JOIN prod_homecare_actransactional_auth.users u2 ON u2.UserID = HCAMUserID
WHERE Date >= '2019-01-01' and (cph.orderstatus = 'Active' OR cph.orderstatusreason = 'Monthly Cap Reached' OR cph.orderstatus = 'Paused')
GROUP BY cph.ProviderID,p.name,cph.OrderID,o.createdon,ost.name,osrt.name,u2.FirstName,u.FirstName
)

Select CTE.*, datediff(LastActiveDate, firstactivedate) DaystoCancel
FROM CTE
) as `_`
where `CurrentOrderStatus` <> 'Onboarding' or `CurrentOrderStatus` is null
limit 1000
