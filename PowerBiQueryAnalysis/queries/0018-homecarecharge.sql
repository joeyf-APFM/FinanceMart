-- Power BI query shape 18 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,757
-- Distinct texts        5 (same query, different literals or projection)
-- Rows read             13,166,496,680
-- Rows returned         6,202,839,683
-- Avg duration          6,317 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, b19514eb-b858-44d5-81a1-2c1a2e9f1483, c65e1078-f986-4629-8d3f-50f7370b5719
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
  CASE
    WHEN AccountID = 2426 AND IsCredit = 0
    THEN 34
    WHEN AccountID = 2426 AND IsCredit = 1
    THEN -34
    ELSE Amount
  END AS AdjustedAmount,
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
  CreatedOn >= '2023-01-01'
ORDER BY
  ReferralID
