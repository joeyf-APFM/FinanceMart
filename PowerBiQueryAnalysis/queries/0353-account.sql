-- Power BI query shape 353 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            15
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             544,274
-- Rows returned         14,130
-- Avg duration          368 ms
-- Power BI datasets     none recorded
-- Tables                community_salesforce.account, community_salesforce.case, community_salesforce.user
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  c.id AS CaseID,
  c.type,
  c.status,
  CAST(c.created_date AS DATE) AS CaseCreateDate,
  CAST(c.closed_date AS DATE) AS CaseCloseDate,
  c.origin,
  c.initial_onboarding_c,
  c.service_area_set_up_guide_c,
  c.the_art_of_conversion_c,
  c.rise_above_c,
  c.nurturing_for_results_c,
  c.portal_proficiency_c,
  c.catered_follow_up_c,
  c.hmc_ob_outreach_attempts_c,
  c.apfm_internal_onboarding_comments_c,
  u.name AS CSM,
  c.account_id,
  a.hmc_cart_provider_id_c AS ProviderID
FROM main.community_salesforce.case AS c
LEFT JOIN main.community_salesforce.user AS u
  ON u.id = c.owner_id
LEFT JOIN main.community_salesforce.account AS a
  ON a.id = c.account_id
WHERE
  c.type = 'Independent Onboarding'
  AND u.name IN ('Cindy Spainhower', 'Jessica Perdue', 'Hannah Guilford')
