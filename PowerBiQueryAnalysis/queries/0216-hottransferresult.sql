-- Power BI query shape 216 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            233
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             9,304,595,985
-- Rows returned         9,626,855
-- Avg duration          57,183 ms
-- Power BI datasets     0e88940d-a1f3-4c92-b384-af62bb64e2e4
-- Tables                prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, prod_homecare_insite_directory.hmcrequestphonenumber
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    hmcr.hmcrequestid,
    ref.referralid,
    CAST(ref.referredon AS DATE) AS ReferralDate,
    CASE WHEN NOT ref.activatedon IS NULL THEN 'Yes' ELSE 'No' END AS Cornerstone_Activation,
    CONCAT(hmcr.firstname, ' ', hmcr.lastname) AS Name,
    hmcr.emailaddress,
    hpn.phonenumber,
    ref.providerid,
    hmcr.postalcode,
    CASE
      WHEN hmcr.djtypeid = 1
      THEN 'SEM After Hours'
      WHEN hmcr.djtypeid = 2
      THEN 'Re-Engagement Text'
      WHEN hmcr.djtypeid = 3
      THEN 'Re-Engagement Email'
      WHEN hmcr.djtypeid = 4
      THEN 'SEM In-Hours'
      WHEN hmcr.djtypeid = 5
      THEN 'SEO ADJ'
      WHEN hmcr.djtypeid = 6
      THEN 'SEO IDJ'
    END AS DJType,
    CASE WHEN NOT ref.digitaljourney IS NULL THEN 'Yes' ELSE 'No' END AS DJReferral
  FROM main.prod_homecare_insite_directory.hmcrequest AS hmcr
  JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = hmcr.hmcrequestid
  JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequestphonenumber AS hpn
    ON hpn.hmcrequestid = hmcr.hmcrequestid
  WHERE
    p.providerorganizationid = 123
    AND ref.billingtypeid = 3
    AND ref.referredon >= '2026'
), CTEA AS (
  SELECT
    CTE.HMCREQUESTID,
    COUNT(DISTINCT ref.referralid) AS Providers_Referred
  FROM CTE
  JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = cte.hmcrequestid
  JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  GROUP BY
    1
), CTEB AS (
  SELECT
    CTE.HMCRequestID,
    CASE
      WHEN p.providerorganizationid = 123 AND NOT ref.activatedon IS NULL
      THEN 'Yes'
      ELSE 'No'
    END AS Cornerstone_Activation,
    CASE WHEN NOT ref.activatedon IS NULL THEN 'Yes' ELSE 'No' END AS AnyActivation,
    ref.activatedon
  FROM CTE
  JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = cte.hmcrequestid
  JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
), CTEC AS (
  SELECT
    CTE.HMCRequestID,
    CASE WHEN p.providerorganizationid = 123 THEN 'Yes' ELSE 'No' END AS Cornerstone_HotTransfer
  FROM CTE
  JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcrequestid = cte.hmcrequestid
  JOIN main.prod_homecare_actransactional_homecare.referral AS ref
    ON ref.hmcleadid = hmcl.hmcleadid
  JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
    ON htr.referralid = ref.referralid
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  WHERE
    htr.hottransferresponseid = 1
)
SELECT DISTINCT
  CTE.Name,
  CTE.emailaddress,
  CTE.phonenumber,
  cte.postalcode,
  cte.djtype,
  cte.djreferral,
  cte.referralid,
  cte.providerid,
  cte.referraldate,
  cte.hmcrequestid,
  CTEA.Providers_Referred,
  CTEB.ActivatedOn,
  CTEB.Cornerstone_Activation,
  CTEB.AnyActivation,
  CASE WHEN ctec.cornerstone_hottransfer IS NULL THEN 'No' ELSE 'Yes' END AS Cornerstone_HotTransfer,
  CASE WHEN ctec.hmcrequestid IS NULL THEN 'No' ELSE 'Yes' END AS Any_HotTransfer
FROM cte
LEFT JOIN ctea
  ON ctea.hmcrequestid = cte.hmcrequestid
LEFT JOIN CTEB
  ON CTEB.hmcrequestid = cte.hmcrequestid
LEFT JOIN CTEC
  ON CTEc.hmcrequestid = cte.hmcrequestid
