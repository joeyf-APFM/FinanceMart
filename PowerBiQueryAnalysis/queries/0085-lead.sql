-- Power BI query shape 85 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            994
-- Distinct texts        3 (same query, different literals or projection)
-- Rows read             28,593,223,420
-- Rows returned         2,224,806,434
-- Avg duration          18,219 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483, c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_actransactional_homecare.lead, prod_homecare_actransactional_homecare.referral, prod_homecare_insite_directory.companyinfo, prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcprospectphonenumber, prod_homecare_insite_directory.hmcproviderleadstatushistory, prod_homecare_insite_directory.lead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT
    p.HMCProspectID,
    p.emailaddress,
    hmcl.HMCLeadID,
    HotTransferred,
    l.leadid,
    l.leadinfoid,
    hmcl.CreateDate AS ReferralDate,
    hmcl.CompanyID,
    ci.ProviderID,
    ci.accountid,
    ci.companyname,
    stat.createdate AS ActivationDate,
    ROW_NUMBER() OVER (PARTITION BY p.HMCProspectID ORDER BY ci.companyname ASC) AS rn
  FROM prod_homecare_insite_directory.hmcprospect AS p
  JOIN prod_homecare_insite_directory.hmclead AS hmcl
    ON p.HMCProspectID = hmcl.HMCProspectID
    AND hmcl.CreateDate > '2023-01-01' /* AND hmcl.CreateDate < '2022-10-05' */
  LEFT JOIN prod_homecare_insite_directory.companyinfo AS ci
    ON hmcl.CompanyID = ci.companyid
  LEFT JOIN prod_homecare_insite_directory.lead AS l
    ON l.HMCLeadID = hmcl.HMCLeadID
  LEFT JOIN (
    SELECT DISTINCT
      HMCProspectID,
      PhoneNumber,
      ROW_NUMBER() OVER (PARTITION BY HMCProspectID ORDER BY PhoneNumber DESC) AS rn
    FROM prod_homecare_insite_directory.hmcprospectphonenumber
    WHERE
      PhoneRank = 1
  ) AS phone
    ON phone.HMCProspectID = p.HMCProspectID AND phone.rn = 1
  LEFT JOIN (
    SELECT
      leadid,
      lsh.createdate,
      ROW_NUMBER() OVER (PARTITION BY leadid ORDER BY createdate DESC) AS rn
    FROM prod_homecare_insite_directory.hmcproviderleadstatushistory AS lsh
    WHERE
      hmcleadstatusid = 7
  ) AS stat
    ON stat.leadid = l.leadid AND stat.rn = 1
  WHERE
    NOT hmcl.CompanyID IS NULL
), CTE1 AS (
  SELECT
    CTE.HMCProspectID,
    CTE.emailaddress,
    CTE.ReferralDate,
    CTE.HMCLeadID,
    HotTransferred,
    CASE WHEN NOT HotTransferred IS NULL THEN 1 ELSE 0 END AS HotTransferredNum,
    CTE.leadid,
    CTE.leadinfoid,
    CTE.CompanyID,
    CTE.ProviderID,
    CTE.accountid,
    CART.rn,
    CTE.companyname,
    CASE
      WHEN (
        NOT CTE.ActivationDate IS NULL OR NOT CART.ActivatedOn IS NULL
      )
      THEN 1
      ELSE 0
    END AS Activated,
    COALESCE(CTE.ActivationDate, CART.ActivatedOn) AS MinActivationDate,
    CASE WHEN COALESCE(CTE.ActivationDate, CART.ActivatedOn) IS NULL THEN 0 ELSE 1 END AS AnyActivation
  FROM CTE
  LEFT JOIN (
    SELECT
      ReferralID,
      ref.LeadID,
      l.ContactEmail,
      l.ContactPhone,
      ProviderID,
      ReferredOn,
      ActivatedOn,
      StartedCareOn,
      EndedCareOn,
      ROW_NUMBER() OVER (PARTITION BY ContactEmail, ProviderID ORDER BY ReferralID DESC) AS rn
    FROM prod_homecare_actransactional_homecare.referral AS ref
    LEFT JOIN prod_homecare_actransactional_homecare.lead AS l
      ON ref.LeadID = l.LeadID
    WHERE
      ReferredOn > '2023-01-01' AND NOT ContactEmail IS NULL
  ) AS CART
    ON LOWER(CART.ContactEmail) = LOWER(CTE.emailaddress)
    AND CART.ProviderID = CTE.ProviderID
    AND CART.rn = 1
  WHERE
    1 = 1
    AND /* AND CTE.s>0 */ (
      (
        CART.rn <= 4 AND CAST(CTE.ReferralDate AS DATE) < '2024-09-01'
      )
      OR (
        CART.rn <= 5 AND CAST(CTE.ReferralDate AS DATE) >= '2024-09-01'
      )
    )
  ORDER BY
    HMCProspectID DESC
)
SELECT
  t2.HMCProspectID,
  t2.ReferralDate,
  NumProv,
  ActDate,
  t2.HMCLeadID,
  r.ReferralID,
  r.ReturnApproved,
  r.BillingTypeID,
  t2.HotTransferred,
  t2.companyname,
  t2.ProviderID,
  t2.Activated AS ProvActivation,
  t2.MinActivationDate,
  prop.HTAny,
  prop.ActivatedAny
FROM CTE1 AS t2
LEFT JOIN prod_homecare_actransactional_homecare.referral AS r
  ON r.HMCLeadID = t2.HMCLeadID
LEFT JOIN (
  SELECT
    HMCProspectID,
    CASE WHEN SUM(HotTransferredNum) > 0 THEN 1 ELSE 0 END AS HTAny,
    CASE WHEN SUM(Activated) > 0 THEN 1 ELSE 0 END AS ActivatedAny,
    COUNT(HMCLeadID) AS NumProv,
    MinActivationDate AS ActDate
  FROM CTE1
  WHERE
    NOT MinActivationDate IS NULL
  GROUP BY
    HMCProspectID,
    MinActivationDate
) AS prop
  ON prop.HMCProspectID = t2.HMCProspectID
/* where r.referralid = 3043182 */
ORDER BY
  t2.HMCProspectID
