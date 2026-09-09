-- Power BI query shape 572 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             39,664,374
-- Rows returned         31,648
-- Avg duration          4,217 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.diminternaluser, prod_homecare_acreporting_reporting.facthomecarerequestsummary, prod_homecare_actransactional_seniorliving.referral, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    ReferralID,
    ProviderID,
    HomeCareReferralID,
    r.FirstName,
    r.LastName,
    r.EmailAddress,
    Phone,
    CareRecipientFirstName,
    CareRecipientLastName,
    r.WhyIsCareNeeded,
    r.PostalCode,
    u.FirstName AS CareAdvisor,
    req.RequestDateTime,
    hmcp.HMCProspectID,
    ReferralDate,
    ReferralStatusTypeID,
    ClientApproval,
    CASE
      WHEN hmcr.affiliateid = 140
      THEN 'Grace'
      WHEN hmcr.affiliateid = 72
      THEN 'APFM'
      WHEN hmcr.affiliateID IN (
        98,
        100,
        101,
        102,
        103,
        104,
        105,
        109,
        110,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132,
        134
      )
      THEN 'SEM'
      WHEN hmcr.affiliateID = 87
      THEN 'SEO'
      WHEN hmcr.affiliateID = 92
      THEN 'SEO'
      WHEN hmcr.affiliateID IN (90, 107, 113, 133)
      THEN 'Affiliates'
      WHEN hmcr.affiliateID IN (93, 94, 95, 96, 97, 99, 106, 108, 117, 119, 121, 136)
      THEN 'APFM DQ'
      WHEN hmcr.url LIKE '%msclkid%'
      OR hmcr.url LIKE '%gclid%'
      OR hmcr.url LIKE '%campaignid%'
      THEN 'SEM'
      WHEN hmcr.url LIKE '%email%' OR hmcr.affiliateID = 111
      THEN 'Email'
      WHEN hmcr.affiliateid IN (6, 49)
      OR hmcr.url LIKE '%/local%'
      OR hmcr.url LIKE '%local/%'
      THEN 'SEO'
      WHEN hmcr.affiliateid = 112
      THEN 'SEO'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid = 138
      THEN 'AgingCare Manual'
      WHEN hmcr.url IS NULL AND hmcr.affiliateid IN (36, 47)
      THEN 'Unknown'
      ELSE 'Affiliates'
    END AS AdjChannel,
    ExternalIdentifier,
    CreatedOn,
    CreatedBy,
    SysStartTime,
    SysEndTime,
    hmcp.SLPPSourceTypeID,
    ROW_NUMBER() OVER (PARTITION BY ReferralID ORDER BY req.RequestDateTime DESC) AS rn
  FROM prod_homecare_actransactional_seniorliving.referral AS r
  LEFT JOIN prod_homecare_insite_directory.hmcprospect AS hmcp
    ON r.FirstName = hmcp.FirstName
    AND r.LastName = hmcp.LastName
    AND r.EmailAddress = hmcp.emailaddress
  LEFT JOIN main.prod_homecare_insite_directory.hmcrequest AS hmcr
    ON hmcr.hmcprospectid = hmcp.hmcprospectid
  LEFT JOIN (
    SELECT
      fhcr.RequestID,
      fhcr.RequestDateTime,
      hmcr.HMCProspectID,
      LastCareAdvisorInternalUserKey,
      ROW_NUMBER() OVER (
        PARTITION BY HMCProspectID, CAST(RequestDateTime AS DATE)
        ORDER BY RequestDateTime DESC
      ) AS rn
    FROM prod_homecare_acreporting_reporting.facthomecarerequestsummary AS fhcr
    LEFT JOIN prod_homecare_insite_directory.hmcrequest AS hmcr
      ON hmcr.HMCRequestID = fhcr.RequestID
  ) AS req
    ON req.HMCProspectID = hmcp.HMCProspectID /* AND (CAST(req.RequestDateTime AS Date) = CAST(r.ReferralDate AS Date) OR DATEADD(day,-1,CAST(req.RequestDateTime AS Date)) = CAST(r.ReferralDate AS Date) OR DATEADD(day,1,CAST(req.RequestDateTime AS Date)) = CAST(r.ReferralDate AS Date)) */
  LEFT JOIN prod_homecare_acreporting_reporting.diminternaluser AS u
    ON u.InternalUserKey = req.LastCareAdvisorInternalUserKey
  WHERE
    r.FirstName <> 'SLPP' AND (
      rn = 1 OR rn IS NULL
    )
)
SELECT
  *
FROM CTE
WHERE
  rn = 1
ORDER BY
  ReferralID
