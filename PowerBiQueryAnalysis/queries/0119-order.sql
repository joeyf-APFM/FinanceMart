-- Power BI query shape 119 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            503
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             12,914,127
-- Rows returned         13,314,428
-- Avg duration          1,865 ms
-- Power BI datasets     none recorded
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
    `hcamownername`
from `main`.`prod_homecare_actransactional_ordermanagement`.`order`
