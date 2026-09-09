-- Power BI query shape 24 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            2,461
-- Distinct texts        2 (same query, different literals or projection)
-- Rows read             1,238,241
-- Rows returned         1,241,289
-- Avg duration          2,271 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_insite_dbo.users
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  u.userid,
  u.userkey,
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
