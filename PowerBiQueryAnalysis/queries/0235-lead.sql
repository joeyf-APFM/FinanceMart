-- Power BI query shape 235 of 663, from workspace_jf.landscape.qh.
-- Not a schema probe: this shape reads data and returns rows.
--
-- Executions            220
-- Distinct texts        1 (same query, different literals or projection)
-- Rows read             51,465,060
-- Rows returned         58,362,605
-- Avg duration          1,786 ms
-- Power BI datasets     none recorded
-- Tables                prod_homecare_actransactional_recruitment.lead
--
-- Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this
-- is the inner query as written, reformatted by sqlglot -- not the exact
-- bytes Power BI sent.

SELECT
  `leadid`,
  `providerid`,
  `accountid`,
  `costperlead`,
  `createdby`,
  `modifiedon`,
  `matchrulesetid`,
  `isexactmatch`,
  `modifiedby`,
  `orderid`,
  `leadproviderdeliverytypeid`,
  `isproximitymatch`,
  `sfrecordid`,
  `applicantid`,
  `createdon`,
  `_fivetran_deleted`,
  `_fivetran_synced`,
  (
    CAST(YEAR(`createdon`) AS DOUBLE) * 1.000000000000000E+004 + CAST(MONTH(`createdon`) AS DOUBLE) * 1.000000000000000E+002
  ) + CAST(DAYOFMONTH(`createdon`) AS DOUBLE) AS `C1`
FROM `main`.`prod_homecare_actransactional_recruitment`.`lead`
