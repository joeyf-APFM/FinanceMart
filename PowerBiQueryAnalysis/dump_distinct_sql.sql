-- Distinct statement_text from the Power BI query-history landscape table,
-- with execution weight so analysis can be ranked by real load rather than
-- by how many distinct shapes happen to exist.
SELECT
    statement_text,
    count(*)                                   AS exec_count,
    count(DISTINCT session_id)                 AS sessions,
    collect_set(ctx_DatasetId)                 AS dataset_ids,
    collect_set(ctx_Source_Operation)          AS source_operations,
    collect_set(trctx_WorkspaceName)           AS pbi_workspaces,
    min(start_time)                            AS first_seen,
    max(start_time)                            AS last_seen,
    sum(read_rows)                             AS read_rows_total,
    sum(read_files)                            AS read_files_total,
    sum(produced_rows)                         AS produced_rows_total,
    avg(unix_millis(end_time) - unix_millis(start_time)) AS avg_ms
FROM workspace_jf.landscape.qh
WHERE statement_text IS NOT NULL
GROUP BY statement_text
