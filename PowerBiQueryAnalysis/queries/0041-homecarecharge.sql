-- Power BI query shape 41 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,141
-- Distinct texts        6 (same query, different literals or projection)
-- Rows read             9,729,441,661
-- Rows returned         4,498,691,438
-- Avg duration          9,285 ms
-- Power BI datasets     2bcc3123-33ee-429b-9609-ef5534b5441c, b19514eb-b858-44d5-81a1-2c1a2e9f1483, eda315a6-a542-4102-b6ce-3551c75b1bdd
-- Tables                prod_homecare_actransactional_billing.homecarecharge, prod_homecare_actransactional_homecare.referral
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
  WHERE
    ReferredOn >= '2022-01-01'
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
