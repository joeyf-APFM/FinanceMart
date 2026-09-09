-- Power BI query shape 648 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,096
-- Rows returned         1,096
-- Avg duration          857 ms
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
    Select *
FROM prod_homecare_acreporting_reporting.dimdate
where date>= '2025'
) as `_`
order by `date`
