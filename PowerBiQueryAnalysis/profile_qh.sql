SELECT
    count(*)                        AS rows_total,
    count(DISTINCT statement_text)  AS distinct_text,
    count(DISTINCT statement_id)    AS distinct_statement_id,
    count(DISTINCT ctx_DatasetId)   AS distinct_datasets,
    min(start_time)                 AS first_seen,
    max(start_time)                 AS last_seen,
    max(length(statement_text))     AS max_text_len,
    avg(length(statement_text))     AS avg_text_len
FROM workspace_jf.landscape.qh
