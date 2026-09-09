-- Power BI query shape 566 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             19,493,418
-- Rows returned         6,404
-- Avg duration          2,498 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcrequest, reporting.dim_geography_zip_dma
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    COUNT(DISTINCT referralid) AS Referrals, /*   ,date(Referredon) ReferredOn */
    DATE_FORMAT(Referredon, 'yyyyMM') AS MonthYearID,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org,
    dma.dma
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcleadid = ref.hmcleadid
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = hmcl.hmcleadid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = TRIM(hmcr.postalcode)
  WHERE
    NOT ref.hmcleadid IS NULL
    AND ref.referredon >= '2025'
    AND ref.billingtypeid = 3
    AND (
      ref.returnapproved = FALSE OR ref.returnapproved IS NULL
    )
  GROUP BY
    2,
    3,
    4
), CTEA AS (
  SELECT
    COUNT(DISTINCT ref.referralid) AS First3DayReferrals,
    DATE_FORMAT(ref.referredon, 'yyyyMM') AS MonthYearID,
    DMA,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcleadid = ref.hmcleadid
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = hmcl.hmcleadid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = TRIM(hmcr.postalcode)
  WHERE
    NOT ref.hmcleadid IS NULL
    AND (
      ref.referredon >= DATE_TRUNC('MONTH', ref.referredon)
      AND ref.referredon <= DATE_ADD(DAY, 2, DATE_TRUNC('MONTH', ref.referredon))
    )
    AND ref.billingtypeid = 3
    AND ref.referredon >= '2025'
    AND (
      ref.returnapproved = FALSE OR ref.returnapproved IS NULL
    )
  GROUP BY
    2,
    3,
    4
), CTEB AS (
  SELECT
    COUNT(DISTINCT ref.referralid) AS Last3DayReferrals,
    DATE_FORMAT(ref.referredon, 'yyyyMM') AS MonthYearID,
    DMA,
    CASE WHEN p.providerorganizationid IS NULL THEN 'Independent' ELSE 'Franchise' END AS Org
  FROM prod_homecare_actransactional_homecare.referral AS ref
  LEFT JOIN main.prod_homecare_actransactional_organization.provider AS p
    ON p.providerid = ref.providerid
  LEFT JOIN main.prod_homecare_insite_directory.hmclead AS hmcl
    ON hmcl.hmcleadid = ref.hmcleadid
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcrequestid = hmcl.hmcleadid
  LEFT JOIN main.reporting.dim_geography_zip_dma AS dma
    ON dma.zip = TRIM(hmcr.postalcode)
  WHERE
    NOT ref.hmcleadid IS NULL
    AND (
      ref.referredon <= LAST_DAY(ref.referredon)
      AND ref.referredon >= DATE_ADD(DAY, -2, LAST_DAY(ref.referredon))
    )
    AND ref.billingtypeid = 3
    AND ref.referredon >= '2025'
    AND (
      ref.returnapproved = FALSE OR ref.returnapproved IS NULL
    )
  GROUP BY
    2,
    3,
    4
)
SELECT
  CTE.Referrals,
  CTE.MonthYearID,
  CTE.Org,
  CTE.DMA,
  CTEA.first3dayreferrals,
  CTEB.last3dayreferrals
FROM CTE
LEFT JOIN CTEA
  ON CTEA.dma = CTE.DMA AND CTEA.monthyearid = CTE.monthyearid AND ctea.org = cte.org
LEFT JOIN CTEB
  ON CTEB.dma = CTE.DMA AND CTEB.monthyearid = CTE.monthyearid AND CTEB.org = cte.org
