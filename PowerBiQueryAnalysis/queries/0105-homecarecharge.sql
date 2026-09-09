-- Power BI query shape 105 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            621
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             3,246,094,921
-- Rows returned         1,471,511,500
-- Avg duration          13,966 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.hottransferresponse, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    r.ReferralID,
    LeadID,
    ProviderID,
    BillingTypeID,
    ReferralStatusTypeID,
    ReferredOn,
    ActivatedOn,
    AdvisorActivatedOn,
    StartedCareOn,
    AdvisorStartedCareOn,
    EndedCareOn,
    AdvisorEndedCareOn,
    ExternalIdentifier,
    r.ModifiedOn,
    r.ModifiedBy,
    r.CreatedOn,
    r.CreatedBy,
    SysStartTime,
    SysEndTime,
    AdvisorReferralStatusTypeID,
    PreviousEndedCareOn,
    ReferralEndCareReasonTypeID,
    ReturnApproved,
    CONCAT(MONTH(ReferredOn), '-', YEAR(ReferredOn)) AS MonthYear,
    HMCLeadID,
    OrderID,
    htr.hottransferresultid,
    CASE WHEN r.digitaljourney = TRUE THEN 'Yes' ELSE 'No' END AS DJReferral,
    HMCLeadIDUpdateBy,
    ReferralDisplayStatusTypeID,
    ReferralActivationSourceId,
    HotTransferResult,
    CASE
      WHEN r.OrderID = 2774
      THEN 34
      WHEN r.BillingTypeID = 1
      THEN 18
      ELSE hcc.Amount
    END AS ReferralRevenue,
    ROW_NUMBER() OVER (PARTITION BY r.ReferralID ORDER BY ReferredOn DESC) AS rn
  FROM prod_homecare_actransactional_homecare.referral AS r
  LEFT JOIN prod_homecare_actransactional_billing.homecarecharge AS hcc
    ON hcc.ReferralID = r.ReferralID AND hcc.IsCredit = 0
  LEFT JOIN (
    SELECT
      referralid,
      hottransferresultid
    FROM prod_homecare_actransactional_homecare.hottransferresult
    WHERE
      hottransferresponseid = 1
  ) AS htr
    ON htr.referralid = r.referralid
  LEFT JOIN (
    SELECT
      referralid,
      hottransferresultid,
      htrr.name AS HotTransferResult
    FROM prod_homecare_actransactional_homecare.hottransferresult AS htr
    LEFT JOIN main.prod_homecare_actransactional_homecare.hottransferresponse AS htrr
      ON htrr.hottransferresponseid = htr.hottransferresponseid
  ) AS htrr
    ON htrr.referralid = r.referralid
  WHERE
    ReferredOn >= '2023-01-01'
    AND (
      (
        BillingTypeID = 3 AND NOT HMCLeadID IS NULL
      ) OR BillingTypeID = 1
    )
)
SELECT
  *
FROM CTE
WHERE
  rn = 1
