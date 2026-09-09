-- Power BI query shape 440 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             414,149
-- Rows returned         29,434
-- Avg duration          397 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.payment
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  p.accountid,
  p.amount,
  MAX(
    DATE_FORMAT(
      CASE
        WHEN NOT p.forstatementid IS NULL
        THEN DATE_ADD(MONTH, -1, DATE_TRUNC('MONTH', p.createdon))
        ELSE p.createdon
      END,
      'yyyyMM'
    )
  ) AS PaymentDate,
  MAX(p.createdon) AS createdon
FROM prod_homecare_actransactional_billing.payment AS p
WHERE
  p.paymentstatustypeid IN (2, 4)
GROUP BY
  1,
  2
