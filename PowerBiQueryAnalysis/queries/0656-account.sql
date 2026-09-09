-- Power BI query shape 656 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             199,729
-- Rows returned         1,000
-- Avg duration          8,494 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.othercharge, prod_homecare_actransactional_billing.otherchargetype, prod_homecare_actransactional_billing.payment, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_organization.provider
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    p.AccountID,
    p.amount,
    p.createdon,
    DATE_FORMAT(p.createdon, 'yyyyMM') AS PaymentMonthYearId,
    CASE WHEN p.paymentstatustypeid = 1 THEN 'Payment' ELSE NULL END AS Payment
  FROM main.prod_homecare_actransactional_billing.payment AS p
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.accountid = p.accountid
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.orderprovider AS op
    ON op.orderid = o.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS pro
    ON pro.providerid = op.providerid
  LEFT JOIN main.prod_homecare_actransactional_billing.account AS a
    ON a.accountid = p.accountid
  WHERE
    p.paymentstatustypeid = 1
    AND p.createdon >= '2024'
    AND (
      pro.providerorganizationid IS NULL
      OR (
        NOT pro.providerorganizationid IS NULL AND a.paymentmethodtypeid <> 3
      )
    )
  UNION
  SELECT
    p.AccountID,
    p.amount,
    p.createdon,
    DATE_FORMAT(p.createdon, 'yyyyMM') AS PaymentMonthYearId,
    oct.name AS OtherChargeType
  FROM main.prod_homecare_actransactional_billing.othercharge AS p
  LEFT JOIN main.prod_homecare_actransactional_billing.otherchargetype AS oct
    ON oct.otherchargetypeid = p.otherchargetypeid
  WHERE
    p.otherchargetypeid IN (2, 10)
)
SELECT
  *
FROM CTE
