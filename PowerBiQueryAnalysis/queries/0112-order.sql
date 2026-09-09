-- Power BI query shape 112 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            588
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             17,699,443
-- Rows returned         17,911,506
-- Avg duration          1,188 ms
-- Power BI datasets     f218dbf6-ff27-4a85-aeaa-0e0b0ca200a0
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
    `resumedate`,
    case
        when cast(`orderstatustypeid` as DOUBLE) = 5.000000000000000E+000 and `orderstatustypeid` is not null
        then `modifiedon`
        else null
    end as `C1`
from `main`.`prod_homecare_actransactional_ordermanagement`.`order`
