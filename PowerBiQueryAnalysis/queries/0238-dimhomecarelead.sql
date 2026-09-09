-- Power BI query shape 238 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            220
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             3,810,836,419
-- Rows returned         80,518,610
-- Avg duration          8,731 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_acreporting_reporting.dimhomecarelead, prod_homecare_acreporting_reporting.dimhomecarerequest, prod_homecare_acreporting_reporting.dimprovider, prod_homecare_acreporting_reporting.facthomecarereferraltransaction, prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.companyinfo
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CART AS (
  SELECT
    ReferralID,
    r.LeadID,
    l.Advisor,
    l.ContactEmail,
    l.ContactPhone,
    ProviderID,
    BillingTypeID,
    ReferredOn
  FROM prod_homecare_actransactional_homecare.referral AS r
  LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
    ON r.LeadID = l.LeadID
  WHERE
    ReferredOn > '2019'
), AC AS (
  SELECT
    HMCLeadID,
    hcrt.RequestID,
    dhcl.ContactEmail,
    dhcl.ContactPhone,
    LeadSentDateID,
    TO_DATE(CAST(LeadSentDateID AS STRING), 'yyyyMMdd') AS LeadSentDate,
    hcrt.AccountID,
    HotTransferred,
    ScreeningResultID,
    dp.CompanyID,
    ci.ProviderID
  FROM prod_homecare_acreporting_reporting.facthomecarereferraltransaction AS hcrt
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarerequest AS dhcr
    ON hcrt.RequestID = dhcr.RequestID
  LEFT JOIN prod_homecare_acreporting_reporting.dimhomecarelead AS dhcl
    ON dhcr.LeadKey = dhcl.LeadKey
  LEFT JOIN prod_homecare_acreporting_reporting.dimprovider AS dp
    ON hcrt.ProviderKey = dp.ProviderKey
  LEFT JOIN prod_homecare_insite_directory.companyinfo AS ci
    ON ci.companyid = dp.CompanyID
  WHERE
    LeadSentDateID > 20190000 AND hcrt.AccountID = 10435
), CTE AS (
  SELECT
    ReferralID,
    LeadID,
    HMCLeadID,
    RequestID,
    ScreeningResultID,
    HotTransferred
  FROM CART
  JOIN AC
    ON (
      CART.ContactEmail = AC.ContactEmail
    )
    AND DATEDIFF(DAY, LeadSentDate, ReferredOn) BETWEEN 0 AND 40
  UNION
  SELECT
    ReferralID,
    LeadID,
    HMCLeadID,
    RequestID,
    ScreeningResultID,
    HotTransferred
  FROM CART
  JOIN AC
    ON (
      CART.ContactPhone = AC.ContactPhone
    )
    AND DATEDIFF(DAY, LeadSentDate, ReferredOn) BETWEEN 0 AND 40
), CTE2 AS (
  SELECT
    ReferralID,
    LeadID,
    HMCLeadID,
    RequestID,
    ScreeningResultID,
    HotTransferred,
    ROW_NUMBER() OVER (PARTITION BY ReferralID ORDER BY RequestID DESC) AS rn
  FROM CTE
)
SELECT
  *,
  'AgingCare' AS BusinessUnit
FROM CTE2
WHERE
  rn = 1
