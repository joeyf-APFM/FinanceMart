-- Power BI query shape 54 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,746
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             1,337
-- Rows returned         12,222
-- Avg duration          420 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483
-- Tables                prod_homecare_actransactional_homecare.hottransferresponse
--
-- Verbatim as executed; no Power BI envelope to strip.

select `hottransferresponseid`,
    `createdby`,
    `hottransferresponsetypeid`,
    `createdon`,
    `name`,
    `_fivetran_deleted`,
    `_fivetran_synced`
from `main`.`prod_homecare_actransactional_homecare`.`hottransferresponse`
