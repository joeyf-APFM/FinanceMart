-- Power BI query shape 47 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            1,853
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             9,051,821,037
-- Rows returned         4,283,798,345
-- Avg duration          9,213 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, aa36e346-e2cc-4210-a366-8c48278fcdbd, b23c969a-4a6b-4d76-bea0-6e46dcac27aa, c65e1078-f986-4629-8d3f-50f7370b5719
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.hottransferresult, prod_homecare_actransactional_homecare.referral
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
    hottransferresultid,
    CASE WHEN r.digitaljourney = TRUE THEN 'Yes' ELSE 'No' END AS DJReferral,
    HMCLeadIDUpdateBy,
    ReferralDisplayStatusTypeID,
    ReferralActivationSourceId,
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
