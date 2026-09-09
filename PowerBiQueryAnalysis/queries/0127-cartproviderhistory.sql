-- Power BI query shape 127 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            463
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             5,553,360,953
-- Rows returned         11,406,997
-- Avg duration          406,189 ms
-- Power BI datasets     3fdd5aed-f1c1-47e1-b7b0-5d4b81493a8d, 7d311f0f-60c1-430c-b0dc-ad78a0550d05, aa36e346-e2cc-4210-a366-8c48278fcdbd, b19514eb-b858-44d5-81a1-2c1a2e9f1483
-- Tables                prod_homecare_acreporting_reporting.cartproviderhistory, prod_homecare_actransactional_homecare.referral, prod_homecare_actransactional_organization.provider, prod_homecare_actransactional_organization.providerorganization
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

WITH CTE AS (
  SELECT DISTINCT
    p.providerid,
    p.name,
    po.name AS Organization,
    p.orgid,
    cph.orderid,
    ROW_NUMBER() OVER (PARTITION BY cph.providerid, cph.orderid ORDER BY date DESC) AS rn,
    date,
    CASE
      WHEN NOT cph.orderid IS NULL AND cph.monthlycap IS NULL
      THEN 'Unlimited'
      ELSE cph.monthlycap
    END AS MonthlyCap
  FROM prod_homecare_actransactional_organization.provider AS p
  LEFT JOIN prod_homecare_actransactional_organization.providerorganization AS po
    ON po.providerorganizationid = p.providerorganizationid
  LEFT JOIN prod_homecare_actransactional_homecare.referral AS r
    ON p.ProviderID = r.ProviderID
  LEFT JOIN main.prod_homecare_acreporting_reporting.cartproviderhistory AS cph
    ON cph.providerid = p.providerid
  WHERE
    r.ReferredOn >= '2023-01-01' AND NOT r.ProviderID IS NULL
  /* and cph.date = date(getdate()) */
  ORDER BY
    p.providerid
)
SELECT
  *
FROM cte
WHERE
  rn = 1
