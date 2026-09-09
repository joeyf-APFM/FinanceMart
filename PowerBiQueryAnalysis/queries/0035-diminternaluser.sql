-- Power BI query shape 35 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,212
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             31,835,091,772
-- Rows returned         67,983,595
-- Avg duration          6,909 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, aa36e346-e2cc-4210-a366-8c48278fcdbd
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
