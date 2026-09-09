-- Power BI query shape 141 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            382
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             858,580,636
-- Rows returned         358,585,181
-- Avg duration          3,625 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c, eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_actransactional_billing.homecarecharge
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  HomeCareChargeID,
  AccountID,
  ReferralID,
  Amount,
  StatementID,
  ToHomeCareChargeID,
  IsCredit,
  CreatedOn,
  CreatedBy,
  ModifiedOn,
  ModifiedBy,
  EntryID
FROM prod_homecare_actransactional_billing.homecarecharge
WHERE
  CreatedOn >= '2025-02-01'
ORDER BY
  ReferralID
