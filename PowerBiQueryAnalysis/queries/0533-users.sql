-- Power BI query shape 533 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             992
-- Rows returned         992
-- Avg duration          349 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_insite_dbo.users
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  u.userid, /*  ,u.userkey */
  CASE WHEN u.usercode = 'tonyamarrillo' THEN 'tonya' ELSE u.usercode END AS usercode,
  CASE
    WHEN u.usercode IN (
      'gilav',
      'edt',
      'julietf',
      'abnerp',
      'charmaines',
      'loum',
      'maryn',
      'loria',
      'jesieliton',
      'jeand',
      'ninob',
      'andreb',
      'clarissep',
      'debbiem',
      'lovelyt',
      'lenzib',
      'candyr',
      'kayn',
      'clairen',
      'reymarc',
      'cindyd',
      'irisha',
      'jessf',
      'annm'
    )
    THEN 'Buget Test Group'
    ELSE 'Control'
  END AS Group
FROM prod_homecare_insite_dbo.users AS u
WHERE
  NOT u.usercode IS NULL
