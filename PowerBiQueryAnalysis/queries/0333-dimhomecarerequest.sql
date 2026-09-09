-- Power BI query shape 333 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            29
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             758,717,039
-- Rows returned         14,203
-- Avg duration          9,357 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_acreporting_reporting.diminternaluser, prod_homecare_acreporting_reporting.facthomecarerequestsummary, prod_homecare_acreporting_reporting.factreferralhistory, prod_homecare_actransactional_geo.postalcode_01072025, prod_homecare_actransactional_geo.stateprovince, prod_homecare_actransactional_homecare.billingperiod, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_homecare.referralbilling, prod_homecare_actransactional_homecare.referralendcarereasontype, prod_homecare_actransactional_organization.provider, prod_homecare_insite_directory.hmcrequest
--
-- Verbatim as executed; no Power BI envelope to strip.

select `OTBL`.`referralbillingid`,
    `OTBL`.`sysendtime`,
    `OTBL`.`providerid`,
    `OTBL`.`createdby`,
    `OTBL`.`modifiedon`,
    `OTBL`.`reportedon`,
    `OTBL`.`rate`,
    `OTBL`.`amount`,
    `OTBL`.`billingperiodid`,
    `OTBL`.`modifiedby`,
    `OTBL`.`invoicedon`,
    `OTBL`.`sysstarttime`,
    `OTBL`.`referralid`,
    `OTBL`.`createdon`,
    `OTBL`.`_fivetran_deleted`,
    `OTBL`.`_fivetran_synced`,
    `OTBL`.`Name`
from 
(
    SELECT rb.*
      ,bp.Name
  FROM prod_homecare_actransactional_homecare.referralbilling rb
  LEFT JOIN prod_homecare_actransactional_homecare.billingperiod bp ON bp.BillingPeriodID = rb.BillingPeriodID
  WHERE ReportedOn >= '2022-02-01' AND Amount = 0
) as `OTBL`
where not exists 
(
    select 1
    from 
    (
        WITH CTE4 AS (
WITH CTE3 AS (
WITH CTE2 AS (
      WITH CTE1 AS(
            WITH CTE AS (
SELECT rh.ReferralID
,rh.LeadID
,rh.ActivatedOn
,rh.StartedCareOn
,rh.EndedCareOn 
,rh.SysStartTime
,ROW_NUMBER() OVER (PARTITION BY rh.ReferralID ORDER BY rh.SysStartTime DESC) rn
,ref.EndedCareOn EndedCareOnFinal
,ref.SysStartTime as SysStartTimeFinal
  FROM prod_homecare_acreporting_reporting.factreferralhistory rh
  JOIN prod_homecare_actransactional_homecare.referral ref on rh.ReferralID = ref.ReferralID
  )

  SELECT ReferralID
,LeadID
,ActivatedOn
,StartedCareOn
,EndedCareOn 
,SysStartTime
,EndedCareOnFinal
,SysStartTimeFinal
  ,ROW_NUMBER() OVER (PARTITION BY ReferralID ORDER BY SysStartTime ASC) rn
  FROM CTE
  WHERE (EndedCareOn = EndedCareOnFinal AND EndedCareOn IS NOT NULL)
  OR (rn =1 AND EndedCareOnFinal IS NOT NULL)
  )

  SELECT CTE1.ReferralID
  ,CTE1.LeadID
  ,ref.BillingTypeID
  ,CTE1.EndedCareOnFinal
  ,CASE WHEN CTE1.EndedCareOn IS NULL THEN SysStartTimeFinal ELSE CTE1.SysStartTime END AS ReportedEndedCareDate
  FROM CTE1
  JOIN prod_homecare_actransactional_homecare.referral ref on CTE1.ReferralID = ref.ReferralID
  WHERE rn = 1
  AND ref.BillingTypeID = 1
  )

  SELECT *
  FROM CTE2
  WHERE ReportedEndedCareDate >= '2021-11-19'
  ORDER BY ReferralID DESC
)

,CTEA AS (
SELECT RequestID,LeadKey,ROW_NUMBER() OVER (PARTITION BY LeadKey ORDER BY RequestDateTime desc) AS rn
FROM prod_homecare_acreporting_reporting.dimhomecarerequest
ORDER BY LeadKey
)

,CTEB AS (
SELECT *,ROW_NUMBER() OVER (PARTITION BY HMCProspectID ORDER BY HMCRequestID desc) AS rn
FROM prod_homecare_insite_directory.hmcrequest
)

SELECT hmcp.HMCRequestID
	,hmcp.HMCProspectID
	,temp.ReferralID
	,leads.ExternalIdentifier AS YGL_Lead_ID
	,CONCAT(leads.ContactFirstName,' ',leads.ContactLastName) AS Contact_Name
	,CONCAT(leads.FirstName,' ',leads.LastName) AS Resident_Name
	,prov.Name AS Business_Unit
	,diu.FirstName AS Care_Advisor
	,leads.Advisor
	,leads.ContactEmail
	,leads.ContactPhone
	,sp.Iso2Code
	,ref.ProviderID
	,ref.ReferredOn
	,ref.ActivatedOn
	,ref.StartedCareOn
	,temp.EndedCareOnFinal
	,temp.ReportedEndedCareDate
    ,ect.Name
	,ROW_NUMBER() OVER (PARTITION BY ContactPhone ORDER BY ReportedEndedCareDate desc) pn
FROM CTE3 temp
LEFT JOIN prod_homecare_actransactional_homecare.referral ref ON ref.ReferralID = temp.ReferralID
LEFT JOIN prod_homecare_actransactional_homecare.lead leads ON leads.LeadID = ref.LeadID
LEFT JOIN prod_homecare_actransactional_organization.provider prov ON ref.ProviderID = prov.ProviderID
LEFT JOIN prod_homecare_actransactional_geo.postalcode_01072025 pcv on prov.PostalCodeID = pcv.PostalCodeID
LEFT JOIN prod_homecare_actransactional_geo.stateprovince sp on pcv.StateProvinceID = sp.StateProvinceID
LEFT JOIN CTEB hmcp ON hmcp.firstname = leads.ContactFirstName AND hmcp.lastname = leads.ContactLastName AND hmcp.emailaddress = leads.ContactEmail
LEFT JOIN prod_homecare_acreporting_reporting.facthomecarerequestsummary hcrs ON hcrs.RequestID = hmcp.HMCRequestID
LEFT JOIN prod_homecare_acreporting_reporting.diminternaluser diu ON diu.InternalUserKey = hcrs.LastCareAdvisorInternalUserKey
LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequest dimhcr ON dimhcr.RequestID = hmcp.HMCRequestID
LEFT JOIN prod_homecare_actransactional_homecare.referralendcarereasontype ect ON ect.ReferralEndCareReasonTypeID = ref.ReferralEndCareReasonTypeID
WHERE rn = 1 OR rn IS NULL
ORDER BY HMCRequestID
)

SELECT *
FROM CTE4
WHERE pn = 1
    ) as `ITBL`
    where (`OTBL`.`referralid` = `ITBL`.`ReferralID` and `OTBL`.`referralid` is not null) and `ITBL`.`ReferralID` is not null or `OTBL`.`referralid` is null and `ITBL`.`ReferralID` is null
)
