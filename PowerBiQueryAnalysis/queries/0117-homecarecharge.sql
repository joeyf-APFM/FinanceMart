-- Power BI query shape 117 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            544
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,179,698,816
-- Rows returned         1,211,155,208
-- Avg duration          5,367 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.homecarecharge
--
-- Verbatim as executed; no Power BI envelope to strip.

select `homecarechargeid`,
    `accountid`,
    `createdby`,
    `modifiedon`,
    `amount`,
    `ishottransfer`,
    `tohomecarechargeid`,
    `modifiedby`,
    `iscredit`,
    `statementid`,
    `entryid`,
    `referralid`,
    `createdon`,
    `_fivetran_deleted`,
    `_fivetran_synced`
from `main`.`prod_homecare_actransactional_billing`.`homecarecharge`
