-- Power BI query shape 624 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1
-- Rows returned         1
-- Avg duration          333 ms
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
    `_fivetran_synced`,
    `MonthYear`,
    `Today`
from 
(
    Select distinct *,concat(Monthname, " ", year) MonthYear
      ,datediff(date, getdate()) Today
from main.prod_homecare_acreporting_reporting.dimdate
where date>= '2025' and date < date_add(Year, 2,date_trunc('year',getdate()))
) as `_`
where `Today` = 0 and `Today` is not null
order by `Today`
limit 1000
