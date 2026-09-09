-- Power BI query shape 562 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             32,346,049
-- Rows returned         179,813
-- Avg duration          7,507 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    COUNT(DISTINCT referralid) AS Referrals, /*   ,date(Referredon) ReferredOn */
    DATE_FORMAT(hmcr.createdate, 'yyyyMM') AS MonthYearID,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    dma.dma,
    TRIM(hmcr.postalcode) AS postalcode
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcleadid = ref.hmcleadid
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = hmcl.hmcrequestid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = TRIM(hmcr.postalcode)
  WHERE
    NOT ref.hmcleadid IS NULL
    AND hmcr.createdate >= '2025'
    AND ref.billingtypeid = 3
    AND ref.orderid <> 2774
    AND (
      ref.returnapproved = FALSE OR ref.returnapproved IS NULL
    )
  GROUP BY
    2,
    3,
    4,
    5
), CTEA AS (
  SELECT
    COUNT(DISTINCT ref.referralid) AS First3DayReferrals,
    DATE_FORMAT(hmcr.createdate, 'yyyyMM') AS MonthYearID,
    DMA,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    TRIM(hmcr.postalcode) AS postalcode
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcleadid = ref.hmcleadid
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = hmcl.hmcrequestid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = TRIM(hmcr.postalcode)
  WHERE
    NOT ref.hmcleadid IS NULL
    AND (
      hmcr.createdate >= DATE_TRUNC('MONTH', hmcr.createdate)
      AND hmcr.createdate <= DATE_ADD(DAY, 2, DATE_TRUNC('MONTH', hmcr.createdate))
    )
    AND ref.billingtypeid = 3
    AND ref.orderid <> 2774
    AND hmcr.createdate >= '2025'
    AND (
      ref.returnapproved = FALSE OR ref.returnapproved IS NULL
    )
  GROUP BY
    2,
    3,
    4,
    5
), CTEB AS (
  SELECT
    COUNT(DISTINCT ref.referralid) AS Last3DayReferrals,
    DATE_FORMAT(hmcr.createdate, 'yyyyMM') AS MonthYearID,
    DMA,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    TRIM(hmcr.postalcode) AS postalcode
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcleadid = ref.hmcleadid
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = hmcl.hmcrequestid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = TRIM(hmcr.postalcode)
  WHERE
    NOT ref.hmcleadid IS NULL
    AND (
      hmcr.createdate <= LAST_DAY(hmcr.createdate)
      AND hmcr.createdate >= DATE_ADD(DAY, -2, LAST_DAY(hmcr.createdate))
    )
    AND ref.billingtypeid = 3
    AND ref.orderid <> 2774
    AND hmcr.createdate >= '2025'
    AND (
      ref.returnapproved = FALSE OR ref.returnapproved IS NULL
    )
  GROUP BY
    2,
    3,
    4,
    5
)
SELECT
  CTE.Referrals,
  CTE.MonthYearID,
  CTE.Org,
  CTE.DMA,
  CTEA.first3dayreferrals,
  CTEB.last3dayreferrals,
  CTE.postalcode
FROM CTE
LEFT JOIN CTEA
  ON CTEA.dma = CTE.DMA
  AND CTEA.monthyearid = CTE.monthyearid
  AND ctea.org = cte.org
  AND ctea.postalcode = cte.postalcode
LEFT JOIN CTEB
  ON CTEB.dma = CTE.DMA
  AND CTEB.monthyearid = CTE.monthyearid
  AND CTEB.org = cte.org
  AND cteb.postalcode = cte.postalcode
WHERE
  cte.dma <> 'NA'
