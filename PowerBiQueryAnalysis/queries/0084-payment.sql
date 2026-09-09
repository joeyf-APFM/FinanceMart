-- Power BI query shape 84 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            994
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             210,365,877
-- Rows returned         1,098,087
-- Avg duration          909 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.payment, prod_homecare_actransactional_billing.statement
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    paymentid,
    p.amount,
    accountid,
    resultmessage,
    createdon,
    ROW_NUMBER() OVER (PARTITION BY accountid ORDER BY p.paymentid DESC) AS rn
  FROM prod_homecare_actransactional_billing.payment AS p
  WHERE
    paymentstatustypeid = 2
), CTE1 AS (
  SELECT
    CTE.AccountID,
    CTE.Amount,
    stmt.balance,
    CTE.createdon
  FROM CTE
  LEFT JOIN (
    SELECT
      accountid,
      createdon,
      balance,
      ROW_NUMBER() OVER (PARTITION BY accountid ORDER BY createdon DESC) AS rn
    FROM prod_homecare_actransactional_billing.statement
  ) AS stmt
    ON stmt.accountid = cte.accountid AND stmt.rn = 1
  WHERE
    CTE.RN = 1
)
SELECT
  AccountID,
  Amount,
  Balance,
  createdon
FROM CTE1
WHERE
  Amount = Balance AND amount >= 0
