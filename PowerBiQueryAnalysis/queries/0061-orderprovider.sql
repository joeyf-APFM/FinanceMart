-- Power BI query shape 61 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,481
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             62,743,181
-- Rows returned         62,782,594
-- Avg duration          1,507 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, aa36e346-e2cc-4210-a366-8c48278fcdbd, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_ordermanagement.orderprovider
--
-- Verbatim as executed; no Power BI envelope to strip.

select `orderproviderid`,
    `htmonthlysent`,
    `providerid`,
    `monthlyavailable`,
    `createdby`,
    `modifiedon`,
    `totalavailable`,
    `htmonthlycap`,
    `orderid`,
    `modifiedby`,
    `monthlysent`,
    `dmproviderid`,
    `totalsent`,
    `sfrecordid`,
    `createdon`,
    `monthlycap`,
    `totalcap`,
    `_fivetran_deleted`,
    `_fivetran_synced`
from `main`.`prod_homecare_actransactional_ordermanagement`.`orderprovider`
