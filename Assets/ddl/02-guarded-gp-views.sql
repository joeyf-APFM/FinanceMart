-- =====================================================================
-- Finance Catalog — 02 — guarded GP read layer
--
-- STATUS: NOT EXECUTED.
--
-- `_fivetran_deleted = false` on every GP query, always. Omitting it
-- overstates gl20000 activity roughly 5.7x: 16% of rows across the estate
-- are tombstones, and 82-99.9% in the tables users actually ask about.
--
-- Two deliberate properties of the pattern:
--   * `_fivetran_deleted` is dropped from the projection. If the column is
--     still visible, someone will filter on it again, and a second filter
--     is how a `= true` typo gets written.
--   * Named _live, not _safe. These views contain live rows. "Safe" would
--     imply a privacy guarantee they do not provide — RM00101 PII is just
--     as present here as in the raw replica.
--
-- This does NOT solve freshness. `_fivetran_synced` advances only when a
-- row changes, so gl30000's 2026-01-31 timestamp is the FY2025 close, not
-- a broken connector. Monitor connector `succeeded_at` instead. Do not
-- send anyone to investigate a healthy connector.
--
-- SCHEMA DRIFT: Databricks resolves `SELECT * EXCEPT (...)` at view
-- creation and pins the column list. A column Fivetran adds later will NOT
-- appear until the view is recreated. Regenerate this file from
-- information_schema on a schedule; do not assume the views self-heal.
-- The generator at the bottom of this file is the intended mechanism.
-- =====================================================================

-- ---------------------------------------------------------------------
-- main.prod_gp_apfm_dbo_live  — APFM company (cn, gl, mc, rm, sop, sy)
-- ---------------------------------------------------------------------
-- The 32 tables below are the documented subset (the ones carried in
-- GP to Genie/Dynamics GP Table and Column Metadata Reference). The GP
-- estate has 59 physical tables; the guarded layer must cover all of
-- them, which is what the generator is for.

CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.cn00500  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.cn00500 (Collections - Customer Info). Tombstones excluded.'                  AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.cn00500  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl00100  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl00100 (Account Master). Tombstones excluded.'                              AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl00100  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl00102  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl00102 (Account Category Master). Tombstones excluded.'                     AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl00102  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl00200  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl00200 (Budget Master). Tombstones excluded.'                               AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl00200  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl00201  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl00201 (Budget Summary Master). Tombstones excluded.'                       AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl00201  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl10000  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl10000 (Transaction Work — unposted headers). Tombstones excluded.'         AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl10000  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl10001  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl10001 (Transaction Amounts Work — unposted lines). Tombstones excluded.'   AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl10001  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl10100  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl10100 (Quick Journal Work). Tombstones excluded.'                          AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl10100  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl10101  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl10101 (Quick Journal Amounts Work). Tombstones excluded.'                  AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl10101  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl12000  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl12000 (Budget Transaction Work). Tombstones excluded.'                     AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl12000  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl12001  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl12001 (Budget Transaction Amounts Work). Tombstones excluded.'            AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl12001  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl20000  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl20000 (Year-to-Date Transaction Open — the open fiscal year). Tombstones excluded; omitting the guard overstates activity ~5.7x.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl20000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl30000  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl30000 (Account Transaction History — closed fiscal years). Tombstones excluded. A stale _fivetran_synced here is the FY close, not a broken connector.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl30000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl32000  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl32000 (Budget Transaction History). Tombstones excluded.'                  AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl32000  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl40000  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl40000 (General Ledger Setup). Tombstones excluded.'                        AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl40000  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.gl40200  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.gl40200 (Segment Description Master). Tombstones excluded.'                  AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.gl40200  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.mc00100  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.mc00100 (Exchange Rate Maintenance). Tombstones excluded.'                   AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.mc00100  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.mc00200  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.mc00200 (Multicurrency Account Master). Tombstones excluded.'                AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.mc00200  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.mc40000  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.mc40000 (Multicurrency Setup). Tombstones excluded.'                         AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.mc40000  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.mc40200  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.mc40200 (Currency Setup). Tombstones excluded.'                              AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.mc40200  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.mc40600  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.mc40600 (currency-to-exchange-table bridge; purpose inferred, not documented by Microsoft). Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.mc40600 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.rm00101  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.rm00101 (RM Customer Master). Tombstones excluded. CONTAINS PII — names, addresses, phone, bank name and branch, credit card fields, tax registration. No masking is applied here or in the raw table.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.rm00101 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.rm20101  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.rm20101 (RM Open File — outstanding AR documents). Tombstones excluded. A document leaves this table when fully applied; the history is in rm30101 and the apply trail.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.rm20101 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.rm20201  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.rm20201 (RM Apply Open File). Tombstones excluded. Carries DATE1, GLPOSTDT, APTODCDT and APPTOAMT, which is what makes as-of aging reconstructable.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.rm20201 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.rm30101  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.rm30101 (RM History File — fully applied / closed AR documents). Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.rm30101 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.rm30201  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.rm30201 (RM Apply History File). Tombstones excluded.'                       AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.rm30201  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.sop30300 COMMENT 'Guarded view of main.prod_gp_apfm_dbo.sop30300 (Sales Transaction Amounts History — invoice lines). Tombstones excluded. Its header table SOP30200 is NOT replicated, so there is no reliable header customer, document date, void status or salesperson.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.sop30300 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.sy00300  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.sy00300 (Account Format Setup). Tombstones excluded. This is the table that makes the account-segment count verifiable rather than assumed.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.sy00300 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.sy01400  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.sy01400 (Users Master). Tombstones excluded. Carries a PASSWORD column — exclude it downstream.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.sy01400 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.sy01500  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.sy01500 (Company Master). Tombstones excluded.'                              AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.sy01500  WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.sy40100  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.sy40100 (Period Setup). Tombstones excluded. CLOSED is a current-state boolean that Fivetran overwrites; as-of close history exists only if snapshotted.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.sy40100 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_apfm_dbo_live.sy40101  COMMENT 'Guarded view of main.prod_gp_apfm_dbo.sy40101 (Period Header — fiscal year definition). Tombstones excluded.'      AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_apfm_dbo.sy40101  WHERE _fivetran_deleted = false;

-- ---------------------------------------------------------------------
-- main.prod_gp_capfm_dbo_live — CAPFM company (cn, gl, mc, rm, sy — no sop)
-- ---------------------------------------------------------------------
-- CAPFM is Canadian, which is what makes multicurrency load-bearing rather
-- than optional. The absence of `sop` is why fact_invoice_line is
-- APFM-only and must say so rather than appear to cover both entities.

CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.cn00500 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.cn00500. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.cn00500 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl00100 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl00100. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl00100 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl00102 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl00102. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl00102 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl00200 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl00200. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl00200 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl00201 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl00201. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl00201 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl10000 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl10000. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl10000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl10001 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl10001. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl10001 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl10100 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl10100. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl10100 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl10101 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl10101. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl10101 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl12000 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl12000. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl12000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl12001 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl12001. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl12001 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl20000 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl20000. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl20000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl30000 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl30000. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl30000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl32000 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl32000. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl32000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl40000 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl40000. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl40000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.gl40200 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.gl40200. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.gl40200 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.mc00100 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.mc00100. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.mc00100 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.mc00200 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.mc00200. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.mc00200 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.mc40000 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.mc40000. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.mc40000 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.mc40200 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.mc40200. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.mc40200 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.mc40600 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.mc40600. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.mc40600 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.rm00101 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.rm00101. Tombstones excluded. CONTAINS PII. No masking applied.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.rm00101 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.rm20101 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.rm20101. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.rm20101 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.rm20201 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.rm20201. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.rm20201 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.rm30101 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.rm30101. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.rm30101 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.rm30201 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.rm30201. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.rm30201 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.sy00300 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.sy00300. Tombstones excluded. Confirm CAPFM uses the same account format as APFM before unioning dim_gl_account.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.sy00300 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.sy01400 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.sy01400. Tombstones excluded. Carries a PASSWORD column — exclude it downstream.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.sy01400 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.sy01500 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.sy01500. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.sy01500 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.sy40100 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.sy40100. Tombstones excluded. CAPFM keeps its own period-close state; do not assume it matches APFM.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.sy40100 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_capfm_dbo_live.sy40101 COMMENT 'Guarded view of main.prod_gp_capfm_dbo.sy40101. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_capfm_dbo.sy40101 WHERE _fivetran_deleted = false;

-- ---------------------------------------------------------------------
-- main.prod_gp_dynamics_dbo_live — GP system database (mc, sy)
-- ---------------------------------------------------------------------
-- The system database is the cross-company scope. sy01500 here is the
-- company list, and it is the authoritative source for dim_legal_entity.

CREATE OR REPLACE VIEW main.prod_gp_dynamics_dbo_live.mc40200 COMMENT 'Guarded view of main.prod_gp_dynamics_dbo.mc40200 (Currency Setup, system scope). Tombstones excluded. System-scope currency setup is the preferred source for dim_currency, since it is defined once rather than per company.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_dynamics_dbo.mc40200 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_dynamics_dbo_live.mc40600 COMMENT 'Guarded view of main.prod_gp_dynamics_dbo.mc40600. Tombstones excluded.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_dynamics_dbo.mc40600 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_dynamics_dbo_live.sy01400 COMMENT 'Guarded view of main.prod_gp_dynamics_dbo.sy01400 (Users Master, system scope). Tombstones excluded. This is the authoritative user list; per-company sy01400 is company access. Carries a PASSWORD column — exclude it downstream.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_dynamics_dbo.sy01400 WHERE _fivetran_deleted = false;
CREATE OR REPLACE VIEW main.prod_gp_dynamics_dbo_live.sy01500 COMMENT 'Guarded view of main.prod_gp_dynamics_dbo.sy01500 (Company Master, system scope). Tombstones excluded. Authoritative source for dim_legal_entity: one row per GP company, which is how APFM and CAPFM become two legal entities.' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.prod_gp_dynamics_dbo.sy01500 WHERE _fivetran_deleted = false;

-- ---------------------------------------------------------------------
-- Generator — regenerate this file, do not hand-maintain it
-- ---------------------------------------------------------------------
-- Run against the target workspace and execute the emitted text. This
-- covers all 59 physical GP tables rather than the 32 documented ones, and
-- it re-pins the column list after Fivetran schema drift.
--
-- Guard: it emits a view only for tables that actually carry
-- _fivetran_deleted, so a table replicated without the tombstone column
-- does not get a view whose WHERE clause would fail.

-- SELECT concat(
--          'CREATE OR REPLACE VIEW main.', t.table_schema, '_live.', t.table_name,
--          ' COMMENT ''Guarded view of main.', t.table_schema, '.', t.table_name,
--          '. Tombstones excluded. Generated by ddl/02-guarded-gp-views.sql on ',
--          current_date(), '.''',
--          ' AS SELECT * EXCEPT (_fivetran_deleted) FROM main.', t.table_schema, '.', t.table_name,
--          ' WHERE _fivetran_deleted = false;'
--        ) AS stmt
-- FROM   main.information_schema.tables t
-- JOIN   main.information_schema.columns c
--        ON  c.table_catalog = t.table_catalog
--        AND c.table_schema  = t.table_schema
--        AND c.table_name    = t.table_name
--        AND c.column_name   = '_fivetran_deleted'
-- WHERE  t.table_catalog = 'main'
--   AND  t.table_schema IN ('prod_gp_apfm_dbo', 'prod_gp_capfm_dbo', 'prod_gp_dynamics_dbo')
--   AND  t.table_type <> 'VIEW'
-- ORDER  BY t.table_schema, t.table_name;
