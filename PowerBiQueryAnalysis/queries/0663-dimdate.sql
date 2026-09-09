-- Power BI query shape 663 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             731
-- Rows returned         731
-- Avg duration          302 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimdate
--
-- Verbatim as executed; no Power BI envelope to strip.

select `dateid`,
    `quarter`,
    `dayofweek`,
    `weekenddate`,
    `dayofmonth`,
    `monthyearid`,
    `date`,
    `month`,
    `year`,
    `weekstartdate`,
    `dayofyear`,
    `weekdayname`,
    `monthname`,
    `_fivetran_deleted`,
    `_fivetran_synced`
from 
(
    Select *, CASE WHEN date <'2025-12-01' then 'Pre Test' else 'Post Test' end as Test
FROM prod_homecare_acreporting_reporting.dimdate
where date >= dateadd(Year, -1, date_trunc('YEAR',getdate()))
and date <= dateadd(Year,1,date_trunc('YEAR',getdate()))
) as `_`
order by `date`
