-- Power BI query shape 138 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            385
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             9,306,457
-- Rows returned         9,479,156
-- Avg duration          1,069 ms
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
    case
        when cast(`orderstatustypeid` as DOUBLE) = 5.000000000000000E+000 and `orderstatustypeid` is not null
        then `modifiedon`
        else null
    end as `C1`
from `main`.`prod_homecare_actransactional_ordermanagement`.`order`
