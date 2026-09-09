-- Power BI query shape 170 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            288
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             8,773,723
-- Rows returned         8,773,723
-- Avg duration          1,348 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, aa36e346-e2cc-4210-a366-8c48278fcdbd, b23c969a-4a6b-4d76-bea0-6e46dcac27aa
-- Tables                prod_homecare_actransactional_ordermanagement.order
--
-- Verbatim as executed; no Power BI envelope to strip.

select `orderid`,
    `htmonthlysent`,
    `orderstatusreasonnote`,
    `minimumfee`,
    `costperlead`,
    `modifiedon`,
    `highpriority`,
    `autorenew`,
    `pausedon`,
    `isprefundedpackage`,
    `prepaidtotal`,
    `htmonthlycap`,
    `modifiedby`,
    `dmorderid`,
    `costperhtlead`,
    `name`,
    `monthlysent`,
    `postalmatch`,
    `sysstarttime`,
    `totalsent`,
    `billingtypeid`,
    `orderstatussubreasontypeid`,
    `sfrecordid`,
    `createdon`,
    `confirmationmailsent`,
    `activationdate`,
    `monthlycap`,
    `proximitymatch`,
    `packagecostperlead`,
    `packagetotalcap`,
    `parentsfaccountrecordid`,
    `sysendtime`,
    `orderstatusreasontypeid`,
    `createdby`,
    `monthlyavailable`,
    `accountid`,
    `rate`,
    `matchrulesetid`,
    `totalavailable`,
    `prepaidautorenew`,
    `proximitylimit`,
    `nextpackagetypeid`,
    `billingreminders`,
    `servicetypeid`,
    `dailysent`,
    `dailycap`,
    `orderstatustypeid`,
    `totalcap`,
    `_fivetran_deleted`,
    `_fivetran_synced`,
    `hcamownername`,
    `providerscount`,
    `pendingcancellationdate`,
    `resumedate`
from `main`.`prod_homecare_actransactional_ordermanagement`.`order`
