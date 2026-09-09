-- Power BI query shape 639 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             9
-- Rows returned         1
-- Avg duration          788 ms
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
  MAX(p.createdon)
FROM prod_homecare_actransactional_billing.payment AS p
WHERE
  p.paymentstatustypeid IN (2, 4) AND accountid = 21742
GROUP BY
  1,
  2
