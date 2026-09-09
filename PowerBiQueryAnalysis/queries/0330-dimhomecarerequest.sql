-- Power BI query shape 330 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            29
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             758,617,792
-- Rows returned         252,426
-- Avg duration          8,385 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_acreporting_reporting.diminternaluser, prod_homecare_acreporting_reporting.facthomecarerequestsummary, prod_homecare_acreporting_reporting.factreferralhistory, prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_geo.stateprovince, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralendcarereasontype, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmcrequest
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    rh.ReferralID,
    rh.LeadID,
    rh.ActivatedOn,
    rh.StartedCareOn,
    rh.EndedCareOn,
    rh.SysStartTime,
    ROW_NUMBER() OVER (PARTITION BY rh.ReferralID ORDER BY rh.SysStartTime DESC) AS rn,
    ref.EndedCareOn AS EndedCareOnFinal,
    ref.SysStartTime AS SysStartTimeFinal
  FROM prod_homecare_acreporting_reporting.factreferralhistory AS rh
  JOIN prod_homecare_actransactional_homecare.referral AS ref
    ON rh.ReferralID = ref.ReferralID
), CTE1 AS (
  SELECT
    ReferralID,
    LeadID,
    ActivatedOn,
    StartedCareOn,
    EndedCareOn,
    SysStartTime,
    EndedCareOnFinal,
    SysStartTimeFinal,
    ROW_NUMBER() OVER (PARTITION BY ReferralID ORDER BY SysStartTime ASC) AS rn
  FROM CTE
  WHERE
    (
      EndedCareOn = EndedCareOnFinal AND NOT EndedCareOn IS NULL
    )
    OR (
      rn = 1 AND NOT EndedCareOnFinal IS NULL
    )
), CTE2 AS (
  SELECT
    CTE1.ReferralID,
    CTE1.LeadID,
    ref.BillingTypeID,
    CTE1.EndedCareOnFinal,
    CASE WHEN CTE1.EndedCareOn IS NULL THEN SysStartTimeFinal ELSE CTE1.SysStartTime END AS ReportedEndedCareDate
  FROM CTE1
  JOIN prod_homecare_actransactional_homecare.referral AS ref
    ON CTE1.ReferralID = ref.ReferralID
  WHERE
    rn = 1 AND ref.BillingTypeID = 1
), CTE3 AS (
  SELECT
    *
  FROM CTE2
  WHERE
    ReportedEndedCareDate >= '2021-11-19'
  ORDER BY
    ReferralID DESC
), CTEA AS (
  SELECT
    RequestID,
    LeadKey,
    ROW_NUMBER() OVER (PARTITION BY LeadKey ORDER BY RequestDateTime DESC) AS rn
  FROM prod_homecare_acreporting_reporting.dimhomecarerequest
  ORDER BY
    LeadKey
), CTEB AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY HMCProspectID ORDER BY HMCRequestID DESC) AS rn
  FROM prod_homecare_insite_directory.hmcrequest
), CTE4 AS (
  SELECT
    hmcp.HMCRequestID,
    hmcp.HMCProspectID,
    temp.ReferralID,
    leads.ExternalIdentifier AS YGL_Lead_ID,
    CONCAT(leads.ContactFirstName, ' ', leads.ContactLastName) AS Contact_Name,
    CONCAT(leads.FirstName, ' ', leads.LastName) AS Resident_Name,
    prov.Name AS Business_Unit,
    diu.FirstName AS Care_Advisor,
    leads.Advisor,
    leads.ContactEmail,
    leads.ContactPhone,
    sp.Iso2Code,
    ref.ProviderID,
    ref.ReferredOn,
    ref.ActivatedOn,
    ref.StartedCareOn,
    temp.EndedCareOnFinal,
    temp.ReportedEndedCareDate,
    ect.Name,
    ROW_NUMBER() OVER (PARTITION BY ContactPhone ORDER BY ReportedEndedCareDate DESC) AS pn
  FROM CTE3 AS temp
  LEFT JOIN prod_homecare_actransactional_homecare.referral AS ref
    ON ref.ReferralID = temp.ReferralID
  LEFT JOIN prod_homecare_actransactional_homecare.lead AS leads
    ON leads.LeadID = ref.LeadID
  LEFT JOIN prod_homecare_actransactional_organization.provider AS prov
    ON ref.ProviderID = prov.ProviderID
  LEFT JOIN prod_homecare_actransactional_geo.postalcode_01072025 AS pcv
    ON prov.PostalCodeID = pcv.PostalCodeID
  LEFT JOIN prod_homecare_actransactional_geo.stateprovince AS sp
    ON pcv.StateProvinceID = sp.StateProvinceID
  LEFT JOIN CTEB AS hmcp
    ON hmcp.firstname = leads.ContactFirstName
    AND hmcp.lastname = leads.ContactLastName
    AND hmcp.emailaddress = leads.ContactEmail
  LEFT JOIN prod_homecare_acreporting_reporting.facthomecarerequestsummary AS hcrs
    ON hcrs.RequestID = hmcp.HMCRequestID
  LEFT JOIN prod_homecare_acreporting_reporting.diminternaluser AS diu
    ON diu.InternalUserKey = hcrs.LastCareAdvisorInternalUserKey
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequest AS dimhcr
    ON dimhcr.RequestID = hmcp.HMCRequestID
  LEFT JOIN prod_homecare_actransactional_homecare.referralendcarereasontype AS ect
    ON ect.ReferralEndCareReasonTypeID = ref.ReferralEndCareReasonTypeID
  WHERE
    rn = 1 OR rn IS NULL
  ORDER BY
    HMCRequestID
)
SELECT
  *
FROM CTE4
WHERE
  pn = 1
