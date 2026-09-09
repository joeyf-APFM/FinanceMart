-- Power BI query shape 646 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             16,979,301
-- Rows returned         1,461
-- Avg duration          42,788 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.case, community_salesforce.opportunity, community_salesforce.user, prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_ordermanagement.orderstatusreasontype, prod_homecare_actransactional_ordermanagement.orderstatustype, prod_homecare_actransactional_organization.provider
--
-- Verbatim as executed; no Power BI envelope to strip.

select `ProviderID`,
    `ProviderName`,
    `OrderID`,
    `ProviderOrderID`,
    `OrderStatus`,
    `OrderStatusReason`,
    `Close_Date`,
    `CARTFirstActive`,
    `FirstActiveDate`,
    `OrderRemoval`,
    `LastActiveDate`,
    `DaysActive`,
    `Status`,
    `FirstActivation`,
    `HasActivation`,
    `FirstCaseDate`,
    `ProviderOrder_Age`,
    `DaystoActivation`,
    `ordernumber`,
    `Activations`
from 
(
    WITH CTE5 AS( 
  WITH CTE4 AS( 
  WITH CTE3 AS( 
  WITH CTE2 AS( 
  WITH CTE1 AS( 
  WITH CTE AS( 
  Select o.id OpportunityID 
      ,o.close_date
      ,a.hmc_cart_provider_id_c ProviderID 
FROM main.community_salesforce.opportunity o 
 JOIN main.community_salesforce.account a on a.id = o.account_id 
 WHERE o.is_won = true
  and o.close_date >= '2026'
 -- and a.hmc_cart_provider_id_c = 40382
) 

,CTEA1 AS (
Select CTE.ProviderID 
      ,p.name ProviderName 
      ,cph.OrderID 
      ,CTE.close_date
      ,cph.date
      ,cph.orderstatus
      ,lag(cph.orderstatus) OVER (PARTITION BY cte.providerid, cph.orderid ORDER BY cph.date) Lag 
FROM CTE 
 LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory cph on cph.providerid =cte.providerid 
 LEFT JOIN main.prod_homecare_actransactional_organization.provider p on p.providerid = cte.providerid
  WHERE date >= '2022'
   and cph.contracttype = 'CPL'
   --and p.providerorganizationid is null 
   and cph.date >= '2025-10-01'
  GROUP BY 1,2,3,4,5,6
)

 ,CTEC AS(
   Select DISTINCT CTEA1.ProviderID 
      ,p.name ProviderName 
      ,cph.OrderID 
      ,CTEA1.close_date
      ,min(cph.date) FirstActiveDate
      ,max(cph.date) LastActiveDate 
FROM CTEA1
 LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory cph on cph.providerid =ctea1.providerid 
 LEFT JOIN main.prod_homecare_actransactional_organization.provider p on p.providerid = ctea1.providerid
  WHERE cph.date >= '2022'
   and cph.contracttype = 'CPL'
   and (cph.orderstatus in ('Active', 'Paused') or cph.orderstatusreason = 'Monthly Cap Reached')
   --and p.providerorganizationid is null 
   and cph.date >= '2025-10-01'
   and if(ctea1.orderstatus = 'Onboarding', ctea1.lag <> ctea1.orderstatus, ctea1.orderstatus = ctea1.orderstatus)
 GROUP BY 1,2,3,4  
 )

 Select DISTINCT CTE.ProviderID 
       ,CASE WHEN CTEC.OrderID is null then op.orderid else CTEC.OrderID end OrderID  
       ,CASE WHEN CTEC.ProviderName is null then p.name else CTEC.ProviderName end ProviderName 
       ,CASE WHEN CTEC.Close_Date is null then CTE.Close_Date else CTEC.Close_Date end close_date
       ,CTEC.firstactivedate
       ,CTEC.lastactivedate
      FROM CTE     
     LEFT JOIN CTEC on CTEC.ProviderID = CTE.ProviderID 
     LEFT JOIN main.prod_homecare_actransactional_organization.provider p on p.providerid = cte.providerid 
     LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider op on op.providerid = cte.providerid
  )

,CTEB AS(
Select CTE1.ProviderID 
      ,CTE1.ProviderName 
      ,CTE1.OrderID
      ,concat(CTE1.ProviderID, "-", CTE1.OrderID) ProviderOrderID 
      ,CASE WHEN cph.orderstatus is null then ost.name else cph.orderstatus end OrderStatus 
      ,case when cph.orderstatus is null then orst.name else cph.orderstatusreason end OrderStatusReason  
      ,Close_Date
      ,FirstActiveDate
      ,LastActiveDate 
      ,datediff(lastactivedate, firstactivedate) DaysActive
    --  ,CASE WHEN ost.name in ('Active', 'Paused') or orst.name in ('Monthly Cap Reached') then 'Active+' else 'Inactive' end Status
FROM CTE1 
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order o on o.orderid = cte1.orderid 
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype ost on ost.orderstatustypeid = o.orderstatustypeid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype orst on orst.orderstatusreasontypeid = o.orderstatusreasontypeid
LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory cph on cph.providerid = cte1.providerid and cph.orderid = cte1.orderid
 where cph.date = date(getdate()) 
)

 Select CTE1.ProviderID 
      ,CTE1.ProviderName 
      ,CTE1.OrderID
      ,concat(CTE1.ProviderID, "-", CTE1.OrderID) ProviderOrderID 
      ,CASE WHEN cteb.orderstatus is null then 'Cancelled' else cteb.orderstatus end OrderStatus 
      ,case when cteb.orderstatus is null then orst.name else cteb.orderstatusreason end OrderStatusReason  
      ,CTE1.Close_Date
      ,CTE1.FirstActiveDate
      ,CTE1.LastActiveDate 
      ,datediff(CTE1.lastactivedate, CTE1.firstactivedate) DaysActive
    --  ,CASE WHEN ost.name in ('Active', 'Paused') or orst.name in ('Monthly Cap Reached') then 'Active+' else 'Inactive' end Status
FROM CTE1 
LEFT JOIN CTEB on CTEB.providerid = cte1.providerid and cteb.orderid = cte1.orderid 
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order o on o.orderid = cte1.orderid 
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatustype ost on ost.orderstatustypeid = o.orderstatustypeid
LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderstatusreasontype orst on orst.orderstatusreasontypeid = o.orderstatusreasontypeid
LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory cph on cph.providerid = cte1.providerid and cph.orderid = cte1.orderid
WHERE cph.date = if(cte1.LastActiveDate is null, date(getdate()), cte1.LastActiveDate) 
)

,CTEA AS ( 
      Select ref.providerid 
            ,ref.orderid
            ,min(activatedon) FirstActivation 
      FROM main.prod_homecare_actransactional_homecare.referral ref 
      WHERE ref.hmcleadid is not null 
      group by 1,2
)

Select DISTINCT cte2.*
      ,CASE WHEN orderstatus in ('Active', 'Paused') or OrderStatusReason in ('Monthly Cap Reached') then 'Active+' 
       WHEN orderstatus ='Onboarding' then 'Onboarding' 
       else 'Inactive' end Status
      ,Date(ctea.FirstActivation) FirstActivation
      ,CASE WHEN Date(ctea.FirstActivation) is null then 'No' else 'Yes' end HasActivation 
FROM CTE2 
LEFT JOIN CTEA on CTEA.providerid = cte2.providerid and ctea.orderid = cte2.orderid
 where (firstactivedate >= '2025-10-01' or firstactivedate is null)
  and (lastactivedate >= '2026-01-01' or lastactivedate is null)
)

,CTED AS( 
  Select CTE3.ProviderID 
        ,min(c.created_date) FirstCaseCreateDate
  FROM CTE3
  JOIN main.community_salesforce.account a on a.hmc_cart_provider_id_c = CTE3.ProviderID
  JOIN main.community_salesforce.case c on c.account_id = a.id
  LEFT JOIN main.community_salesforce.user u on u.id = c.owner_id
   WHERE c.type = 'Independent Onboarding'
  and u.name in ('Cindy Spainhower','Jessica Perdue', 'Hannah Guilford')
  and c.created_date >= '2026'
    group by 1
)

,CTERemoval AS( 
      Select CTE3.ProviderID 
            ,CTE3.OrderID 
            ,CTE3.OrderStatus 
            ,CTE3.providerorderid
            ,CTE3.OrderStatusReason 
            ,CTE3.Close_Date 
            ,CTE3.FirstActiveDate 
            ,CTE3.LastActiveDate 
            ,CTE3.Status
            ,CTE3.DaysActive 
            ,CTED.FirstCaseCreateDate 
            ,date_diff(cte3.FirstActiveDate, date(cted.firstcasecreatedate)) DaysToCase
            ,CASE WHEN date_diff(cte3.FirstActiveDate, date(cted.firstcasecreatedate)) < -7 then 1
                  when date_diff(cte3.FirstActiveDate, date(cted.firstcasecreatedate)) > 7 and cte3.status = 'Inactive' then 1
                  else 0 end RemovalFlag
FROM CTE3 
 LEFT JOIN CTED on CTED.providerid = cte3.providerid
)

Select DISTINCT CTE3.ProviderID 
               ,CTE3.ProviderName 
               ,CTE3.OrderID 
               ,CTE3.ProviderOrderID 
               ,CTE3.OrderStatus 
               ,CTE3.OrderStatusReason 
               ,CTE3.Close_Date 
               ,CASE WHEN CTE3.FirstActiveDate < Date(CTED.firstcasecreatedate) then Date(CTED.firstcasecreatedate) else CTE3.FirstActiveDate end FirstActiveDate
               ,CTE3.LastActiveDate 
               ,CTE3.DaysActive 
               ,CTE3.Status 
               ,CTE3.FirstActivation 
               ,CTERemoval.removalflag 
               ,CTE3.HasActivation
               ,cteremoval.firstactivedate CARTFirstActive
      ,Date(CTED.firstcasecreatedate) FirstCaseDate
      ,CASE WHEN CTE3.Status ='Inactive' then 500 else 
       date_diff(Day, CTE3.firstactivedate, date(getdate())) end ProviderOrder_Age 
      ,date_diff(Day, CTE3.firstactivedate, CTE3.firstactivation) DaystoActivation
FROM CTE3 
 LEFT JOIN CTED on CTED.ProviderID = CTE3.ProviderID
 LEFT JOIN CTERemoval on CTERemoval.providerorderid= CTE3.providerorderid 
 where CTERemoval.RemovalFlag = 0 and 
 (cte3.lastactivedate >= Date(CTED.firstcasecreatedate) or cte3.lastactivedate is null)
)

Select DISTINCT CTE4.ProviderID 
               ,CTE4.ProviderName 
               ,CTE4.OrderID 
               ,CTE4.ProviderOrderID 
               ,CTE4.OrderStatus 
               ,CTE4.OrderStatusReason 
               ,CTE4.Close_Date 
               ,CTE4.CARTFirstActive
               ,CTE4.FirstActiveDate
               ,CASE WHEN CTE4.FirstActiveDate > CTE4.LastActiveDate then 1 else 0 end OrderRemoval
               ,CTE4.LastActiveDate 
               ,datediff(CTE4.lastactivedate, CTE4.firstactivedate) DaysActive
               ,CTE4.Status 
               ,CTE4.FirstActivation 
               ,CTE4.HasActivation
               ,CTE4.FirstCaseDate
               ,CTE4.ProviderOrder_Age
               ,CTE4.DaystoActivation
FROM CTE4 
) 

,CTEZ AS( 
      Select providerorderid
            ,count(distinct ref.referralid) Activations 
      FROM CTE5 
       LEFT JOIN main.prod_homecare_actransactional_homecare.referral ref on concat(ref.providerid, "-", ref.orderid) = cte5.providerorderid
        WHERE ref.activatedon is not null 
         Group by 1
)
Select distinct CTE5.*, ROW_NUMBER() OVER(PARTITION BY providerid ORDER BY orderid desc) ordernumber, Activations 
FROM CTE5 
 LEFT JOIN CTEZ on CTEZ.providerorderid = cte5.providerorderid
where orderremoval = 0
) as `_`
where `ordernumber` = 1
