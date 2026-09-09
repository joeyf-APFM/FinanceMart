-- Power BI query shape 361 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            11
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             12,033,945
-- Rows returned         91,570
-- Avg duration          1,162 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_billing.account, prod_homecare_actransactional_billing.statement, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_ordermanagement.order, prod_homecare_actransactional_ordermanagement.orderprovider, prod_homecare_actransactional_organization.provider
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
    a.paymentmethodtypeid = 3 AND o.billingtypeid = 3
), CTEB AS (
  SELECT DISTINCT
    AccountID,
    CASE WHEN priormonth IS NULL THEN balance ELSE balance - priormonth END AS Payment,
    DueDate,
    PaymentMonth
  FROM CTEA
), CTER AS (
  SELECT
    COUNT(DISTINCT ref.referralid) AS ProviderReferrals,
    ref.providerid,
    o.accountid, /*  ,ref.orderid */
    CAST(DATE_TRUNC('MONTH', ref.referredon) AS DATE) AS date
  FROM main.prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = ref.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_actransactional_billing.account AS a
    ON a.accountid = o.accountid
  WHERE
    a.paymentmethodtypeid = 3 AND ref.referredon >= '2025'
  GROUP BY
    2,
    3,
    4
), CTERA AS (
  SELECT DISTINCT
    COUNT(DISTINCT ref.referralid) AS AccountReferrals,
    o.accountid, /* ,ref.orderid */
    CAST(DATE_TRUNC('MONTH', ref.referredon) AS DATE) AS date
  FROM main.prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_ordermanagement.order AS o
    ON o.orderid = ref.orderid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_actransactional_billing.account AS a
    ON a.accountid = o.accountid
  WHERE
    a.paymentmethodtypeid = 3 AND ref.referredon >= '2025'
  GROUP BY
    2,
    3
), CTERAT AS (
  SELECT DISTINCT
    providerreferrals / accountreferrals AS ReferralPercentage,
    ADD_MONTHS(cter.date, 1) AS date,
    providerreferrals,
    accountreferrals,
    cter.providerid,
    cter.accountid
  /* ,cter.orderid */
  FROM CTER
  LEFT JOIN CTERA
    ON CTERA.date = cter.date
    AND cter.accountid = ctera.accountid /* and cter.orderid = ctera.orderid */
), cte1 AS (
  SELECT DISTINCT
    CTEB.accountid,
    cteb.payment,
    cteb.paymentmonth,
    cterat.referralpercentage,
    cterat.providerid, /*  ,cterat.orderid */
    cterat.date
  FROM CTERAT
  JOIN CTEB
    ON cteb.duedate = cterat.date AND cteb.accountid = cterat.accountid
  WHERE
    payment > 0
)
SELECT DISTINCT
  *,
  referralpercentage * payment AS ReferralPayment
FROM CTE1
