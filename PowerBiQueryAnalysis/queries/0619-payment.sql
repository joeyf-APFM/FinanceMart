-- Power BI query shape 619 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             10
-- Rows returned         2
-- Avg duration          531 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.payment
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    p.accountid,
    CASE WHEN p.paymentstatustypeid = 1 THEN p.amount ELSE -p.amount END AS amount,
    DATE_FORMAT(
      CASE
        WHEN p.forstatementid IS NULL
        THEN DATE_ADD(MONTH, 0, DATE_TRUNC('MONTH', p.createdon))
        ELSE DATE_ADD(MONTH, -1, DATE_TRUNC('MONTH', p.createdon))
      END,
      'yyyyMM'
    ) AS PaymentDate
  FROM prod_homecare_actransactional_billing.payment AS p
  WHERE
    accountid = 21742
), CTE1 AS (
  SELECT
    accountid,
    ROW_NUMBER() OVER (PARTITION BY accountid, amount ORDER BY paymentdate ASC) AS Rn,
    amount,
    PaymentDate
  FROM CTE
)
SELECT
  *
FROM cte1
WHERE
  rn = 1
