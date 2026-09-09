-- Power BI query shape 190 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            263
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             83,336
-- Rows returned         192,255
-- Avg duration          430 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, 95e62086-9ac7-4ac5-81fb-5c045316c4fc
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
    `_fivetran_synced`,
    `Test`
from 
(
    Select *, CASE WHEN date <'2025-12-01' then 'Pre Test' else 'Post Test' end as Test
FROM prod_homecare_acreporting_reporting.dimdate
where date >= dateadd(Year, -1, date_trunc('YEAR',getdate()))
and date <= dateadd(Year,1,date_trunc('YEAR',getdate()))
) as `_`
order by `date`
