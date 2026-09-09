-- Power BI query shape 567 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             13,045,956
-- Rows returned         1,392
-- Avg duration          2,055 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory
--
-- Verbatim as executed; no Power BI envelope to strip.

select `date`,
    `ProviderOrders`,
    `CappedProviderOrders`,
    `Providers`,
    `Orders`
from 
(
    Select distinct cph.date
      ,count(distinct concat(cph.providerid, '-',cph.orderid)) ProviderOrders
      ,Count(distinct case when cph.orderstatusreason = 'Monthly Cap Reached' then concat(cph.providerid, '-',cph.orderid) else null end) CappedProviderOrders
      ,count(cph.providerid) Providers
      ,count(cph.orderid) Orders
FROM main.prod_homecare_acreporting_reporting.cartproviderhistory cph 
      WHERE date >= '2024'
      and contracttype = 'CPL'
      and (cph.orderstatus in ('Acitve', 'Paused') or cph.orderstatusreason = 'Monthly Cap Reached')
      GROUP BY 1
) as `_`
order by `date`
limit 1000
