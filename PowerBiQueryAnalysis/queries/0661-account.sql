-- Power BI query shape 661 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             323,094
-- Rows returned         1,000
-- Avg duration          13,413 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.statement, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTEA AS (
  SELECT DISTINCT
    s.accountid,
    s.balance,
    s.duedate,
    DATE_FORMAT(s.duedate, 'yyyyMM') AS paymentMonth,
    LAG(s.balance) OVER (PARTITION BY s.accountid ORDER BY s.duedate) AS PriorMonth
  FROM main.prod_homecare_actransactional_billing.statement AS s
  LEFT JOIN main.prod_homecare_actransactional_billing.account AS a
    ON a.accountid = s.accountid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.accountid = s.accountid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.orderid = o.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = op.providerid
  WHERE
    NOT p.providerorganizationid IS NULL AND a.paymentmethodtypeid = 3
), CTEB AS (
  SELECT
    AccountID,
    CASE WHEN priormonth IS NULL THEN balance ELSE balance - priormonth END AS Payment,
    DueDate,
    PaymentMonth
  FROM CTEA
)
SELECT
  *
FROM CTEB
