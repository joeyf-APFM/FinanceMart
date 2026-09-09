-- Power BI query shape 606 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             67,358,520
-- Rows returned         58,788
-- Avg duration          6,387 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.providerservicecoverage, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    MIN(cph.date) AS Date,
    LAST_DAY(cph.date) AS LastDay,
    cph.providerid,
    psc.postalcode,
    CASE WHEN cph.orderid = 2774 THEN 'Corporate' ELSE 'Individual' END AS OrderType
  FROM main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
  LEFT JOIN main.prod_homecare_actransactional_organization.providerservicecoverage AS psc
    ON psc.providerid = cph.providerid
  WHERE
    cph.date >= '2025'
    AND cph.orderstatusreason = 'Monthly Cap Reached'
    AND LOWER(cph.providername) LIKE 'home instead%'
    AND psc.deleted = 0
  GROUP BY
    2,
    3,
    4,
    5
), CTEA AS (
  SELECT
    CAST(hmcr.createdate AS DATE) AS RequestCreateDate,
    hmcr.hmcrequestid,
    hmcr.hmcprospectid,
    OrderType,
    COUNT(DISTINCT ref.referralid) AS Referrals
  FROM CTE
  JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON TRIM(hmcr.postalcode) = CTE.postalcode
    AND CAST(hmcr.createdate AS DATE) >= CTE.Date
    AND CAST(hmcr.createdate AS DATE) <= CTE.LastDay
  LEFT JOIN main.prod_homecare_insite_directory.hmcprospect AS hmcp
    ON hmcp.hmcprospectid = hmcr.hmcprospectid
  JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  GROUP BY
    1,
    2,
    3,
    4
)
SELECT
  CTEA.RequestCreateDate,
  CTEA.hmcrequestid,
  CTEA.Referrals,
  OrderType,
  TRIM(hmcr.postalcode) AS PostalCode,
  CASE
    WHEN hmcp.residentname IS NULL
    OR hmcp.residentname = ''
    AND NOT hmcr.residentname IS NULL
    THEN hmcr.residentname
    ELSE hmcp.residentname
  END AS ResidentName,
  SUM(CASE WHEN NOT ref.activatedon IS NULL THEN 1 ELSE 0 END) AS ReferralActivated,
  SUM(CASE WHEN NOT htr.referralid IS NULL THEN 1 ELSE 0 END) AS HotTransferred
FROM CTEA
JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
  ON hmcr.hmcrequestid = CTEA.hmcrequestid
JOIN main.prod_homecare_insite_directory.hmcprospect AS hmcp
  ON hmcp.hmcprospectid = hmcr.hmcprospectid
JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcrequestid = hmcr.hmcrequestid
JOIN main.prod_homecare_actransactional_homecare.referral AS ref
  ON ref.hmcleadid = hmcl.hmcleadid
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
  ON htr.referralid = ref.referralid AND htr.hottransferresponseid = 1
GROUP BY
  1,
  2,
  3,
  4,
  5,
  6
