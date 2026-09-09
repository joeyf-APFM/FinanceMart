-- Power BI query shape 621 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             0
-- Rows returned         203
-- Avg duration          267 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.accountstatustype, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype
--
-- Verbatim as executed; no Power BI envelope to strip.

select `accountid`,
    `AccountName`,
    `AccountStatus`,
    `orderid`,
    `OrderName`,
    `OrderCreateDate`,
    `OrderStatus`,
    `OrderStatusReason`,
    `prepaidtotal`,
    `balance`
from 
(
    Select  a.accountid 
     ,a.name AccountName
     ,ast.name AccountStatus
     ,o.orderid 
     ,o.name OrderName 
     ,o.createdon AS OrderCreateDate
     ,ost.name OrderStatus
     ,osrt.name OrderStatusReason 
     ,o.prepaidtotal  
     ,a.balance
FROM main.prod_homecare_actransactional_billing.account a
 LEFT JOIN main.prod_homecare_actransactional_billing.accountstatustype ast on ast.accountstatustypeid = a.accountstatustypeid
 LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order o on o.accountid = a.accountid
 LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype ost on ost.orderstatustypeid = o.orderstatustypeid
 LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype osrt on osrt.orderstatusreasontypeid = o.orderstatusreasontypeid
   WHERE --a.accountstatustypeid = 1 
    ost.name not in ('Active','Onboarding')
     --and a.createdon >= '2025-11-01'
     and a.balance < 0 
     and o.prepaidtotal IS NOT NULL
   --  and o.prepaidtotal > 0
) as `_`
order by `accountid` desc
