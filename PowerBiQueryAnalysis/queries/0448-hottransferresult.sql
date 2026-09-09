-- Power BI query shape 448 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            4
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             27,424,914
-- Rows returned         475,126
-- Avg duration          751 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, prod_ygl_apfm.region, prod_ygl_apfm.region_use, prod_ygl_apfm.zip_region
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    r.region_id AS regionId,
    r.region_name AS regionName,
    zr.zip5
  FROM main.prod_ygl_apfm.zip_region AS zr
  JOIN main.prod_ygl_apfm.region AS r
    ON r.region_id = zr.region_id
  JOIN main.prod_ygl_apfm.region_use AS ru
    ON ru.region_id = zr.region_id AND ru.region_type_code = zr.region_type_code
  WHERE
    ru.region_type_code = 'ADVISOR'
    AND r.region_name = 'South Texas'
    AND r.active = 1
    AND zr.`_fivetran_deleted` = FALSE
    AND r.`_fivetran_deleted` = FALSE
    AND ru.`_fivetran_deleted` = FALSE
  ORDER BY
    r.region_id,
    zr.zip5
)
SELECT
  CAST(hmcr.createdate AS DATE) AS RequestCreatedate,
  hmcr.hmcrequestid,
  CASE
    WHEN hmcr.djstepid = 100
    THEN 'DJ Completed'
    WHEN hmcr.affiliateid = 72
    THEN 'SLA'
    WHEN hmcr.affiliateid IN (140, 141)
    THEN 'Grace'
    WHEN NOT htr.referralid IS NULL
    THEN 'CA HT'
    ELSE 'CA Not HT'
  END AS Referredby,
  ref.referralid,
  CASE
    WHEN ref.returnapproved IS TRUE
    THEN 'Returned'
    WHEN ref.returnapproved IS FALSE
    THEN 'Attempted'
    ELSE 'Not Attempted'
  END AS ReturnStatus,
  CONCAT(ref.providerid, '-', ref.orderid) AS ProviderOrders,
  CAST(ref.referredon AS DATE) AS ReferralDate,
  CASE
    WHEN DAY(hmcr.createdate) <= 7
    THEN 'First 7'
    WHEN DATEDIFF(DAY, hmcr.createdate, LAST_DAY(hmcr.createdate)) < 6
    THEN 'Last 7'
    ELSE 'Middle'
  END AS TimeFrame,
  DATEDIFF(DAY, requestcreatedate, activatedon) AS DaystoActivation,
  CASE WHEN NOT ref.activatedon IS NULL THEN 'Activated' ELSE 'Not Activated' END AS Activation,
  CAST(ref.activatedon AS DATE) AS ActivationDate,
  CASE WHEN NOT cte.zip5 IS NULL THEN 'South Texas' ELSE 'Other' END AS PilotGroup
FROM main.prod_homecare_insite_directory.hmcrequest AS hmcr
JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
  ON hmcl.hmcrequestid = hmcr.hmcrequestid
JOIN main.prod_homecare_actransactional_homecare.referral AS ref
  ON ref.hmcleadid = hmcl.hmcleadid AND ref.billingtypeid = 3
LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresult AS htr
  ON htr.referralid = ref.referralid AND htr.hottransferresponseid = 1
LEFT JOIN CTE
  ON cte.zip5 = hmcr.postalcode
WHERE
  hmcr.createdate >= '2026'
