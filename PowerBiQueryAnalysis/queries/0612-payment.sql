-- Power BI query shape 612 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             743,660
-- Rows returned         7,652
-- Avg duration          792 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.payment
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
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
), CTEA AS (
  SELECT DISTINCT
    accountid,
    p.amount,
    DATE_FORMAT(
      CASE
        WHEN NOT p.forstatementid IS NULL
        THEN DATE_ADD(MONTH, -1, DATE_TRUNC('MONTH', p.createdon))
        ELSE p.createdon
      END,
      'yyyyMM'
    ) AS PaymentDate,
    p.createdon AS createdon,
    p.paymentstatustypeid,
    ROW_NUMBER() OVER (PARTITION BY accountid, amount ORDER BY paymentid DESC) AS rn
  FROM prod_homecare_actransactional_billing.payment AS p
), CTEB AS (
  SELECT DISTINCT
    accountid,
    amount,
    paymentdate,
    CASE WHEN paymentstatustypeid = 1 AND rn = 1 THEN 1 ELSE 0 END AS paid
  FROM CTEA
  WHERE
    rn = 1
)
SELECT
  CTE.accountid,
  CTE.amount,
  CTE.PaymentDate,
  cteb.paid
FROM CTE
LEFT JOIN CTEB
  ON CTEB.accountid = CTE.accountid AND cte.paymentdate = cteb.paymentdate
WHERE
  paid = 0
