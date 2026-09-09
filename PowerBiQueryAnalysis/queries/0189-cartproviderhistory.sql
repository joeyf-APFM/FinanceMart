-- Power BI query shape 189 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            264
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,113,870,240
-- Rows returned         483,312
-- Avg duration          3,453 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 95e62086-9ac7-4ac5-81fb-5c045316c4fc
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_organization.provider
--
-- Verbatim as executed; no Power BI envelope to strip.

select `date`,
    `Org`,
    `ProviderOrders`,
    `CappedProviderOrders`,
    `Providers`,
    `Orders`
from 
(
    Select distinct cph.date
      ,CASE WHEN p.providerorganizationid is null then "Independent"
        else "Franchise"
        END Org
      ,count(distinct concat(cph.providerid, '-',cph.orderid)) ProviderOrders
      ,Count(distinct case when cph.orderstatusreason = 'Monthly Cap Reached' then concat(cph.providerid, '-',cph.orderid) else null end) CappedProviderOrders
      ,count(cph.providerid) Providers
      ,count(cph.orderid) Orders
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory cph 
LEFT JOIN main.prod_homecare_actransactional_organization.provider p on p.providerid = cph.providerid 
      WHERE date >= '2024'
      and contracttype = 'CPL'
      and (cph.orderstatus in ('Active', 'Paused') or cph.orderstatusreason = 'Monthly Cap Reached')
      GROUP BY 1,2
) as `_`
order by `date`
