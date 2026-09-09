-- Power BI query shape 175 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            281
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             3,812,946,635
-- Rows returned         6,356,774
-- Avg duration          8,361 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
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
    ) AND CreatedOn >= '2024-05-01'
)
SELECT
  *
FROM CTE
WHERE
  rn = 1
ORDER BY
  ReferralID
