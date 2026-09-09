-- Power BI query shape 135 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            393
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             113,736,198
-- Rows returned         6,421,408
-- Avg duration          1,621 ms
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
    paymentstatustypeid,
    ROW_NUMBER() OVER (PARTITION BY accountid, MONTH(createdon) ORDER BY createdon DESC) AS rn
  FROM prod_homecare_actransactional_billing.payment AS p
  WHERE
    p.createdon >= '2023-12-01'
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
      ROW_NUMBER() OVER (PARTITION BY accountid, MONTH(createdon) ORDER BY createdon ASC) AS rn
    FROM prod_homecare_actransactional_billing.statement
  ) AS stmt
    ON stmt.accountid = cte.accountid
    AND stmt.rn = 1
    AND DATE_FORMAT(stmt.createdon, 'MM-yyyy') = DATE_FORMAT(cte.createdon, 'MM-yyyy')
  WHERE
    CTE.RN = 1 AND cte.paymentstatustypeid = 2
)
SELECT
  AccountID,
  Amount,
  Balance,
  createdon,
  DATE_FORMAT(DATE_ADD(MONTH, -1, createdon), 'MM-yyyy') AS ChargeMonth
FROM CTE1
WHERE
  Amount = Balance AND amount >= 0
