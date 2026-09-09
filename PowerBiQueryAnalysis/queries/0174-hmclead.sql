-- Power BI query shape 174 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            282
-- Distinct texts        4 (same query, different literals or projection)
-- Rows read             3,121,701,386
-- Rows returned         735,438,821
-- Avg duration          9,325 ms
-- Power BI datasets     6af1511e-31cf-4529-b5ce-58c26f7ebcc8
-- Tables                prod_homecare_insite_directory.hmclead, prod_homecare_insite_directory.hmcprospect, prod_homecare_insite_directory.hmcprospectphonenumber
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  l.hmcleadid,
  l.hmcrequestid,
  l.hmcprospectid,
  l.createdate,
  ppn.phonenumber,
  p.firstname,
  p.lastname,
  p.emailaddress
FROM prod_homecare_insite_directory.hmclead AS l
JOIN prod_homecare_insite_directory.hmcprospectphonenumber AS ppn
  ON ppn.hmcprospectid = l.hmcprospectid
JOIN prod_homecare_insite_directory.hmcprospect AS p
  ON p.hmcprospectid = l.hmcprospectid
WHERE
  l.createdate >= '2025-01-01'
