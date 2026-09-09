#!/usr/bin/env python3
"""Analyze the distinct SQL in workspace_jf.landscape.qh with sqlglot.

`qh` is Power BI query-history telemetry: ~514k executions of ~2.3k distinct
statements against Databricks. The question this answers is what that traffic
actually touches — which tables and columns are load-bearing for the reporting
layer, how they are joined, and which statements are real work versus Power BI
probing a schema.

Everything is weighted by execution count. A statement shape run 100,000 times
and one run once are not equally interesting, and counting distinct shapes
instead of executions inverts the ranking.

Usage
-----
    # dump from the workspace, then analyze
    python3 scripts/analyze_qh_sql.py --fetch --profile <PROFILE> --out report.md

    # re-analyze an existing dump without touching the workspace
    python3 scripts/analyze_qh_sql.py --input qh_distinct.json --out report.md

--profile is never defaulted. dbc-88a3d066-4cdb is production *and* is the
Databricks CLI default, so the profile is always the caller's explicit choice.
The queries this issues are read-only.
"""

import argparse
import collections
import json
import os
import re
import subprocess
import sys

import sqlglot
from sqlglot import exp
from sqlglot.optimizer.scope import build_scope

DIALECT = "databricks"

DUMP_SQL = """
SELECT
    statement_text,
    count(*)                                   AS exec_count,
    count(DISTINCT session_id)                 AS sessions,
    collect_set(ctx_DatasetId)                 AS dataset_ids,
    collect_set(ctx_Source_Operation)          AS source_operations,
    min(start_time)                            AS first_seen,
    max(start_time)                            AS last_seen,
    sum(read_rows)                             AS read_rows_total,
    sum(produced_rows)                         AS produced_rows_total,
    avg(unix_millis(end_time) - unix_millis(start_time)) AS avg_ms
FROM workspace_jf.landscape.qh
WHERE statement_text IS NOT NULL
GROUP BY statement_text
"""

# SQL Server function spellings, detected on the raw text rather than on the parse
# tree: sqlglot canonicalizes cross-dialect functions while parsing -- CHARINDEX
# becomes LOCATE, getdate() becomes CURRENT_TIMESTAMP -- so a post-parse name scan
# never matches any of these.
#
# Classified by whether *Databricks* accepts the spelling, which is the question
# that matters. Note that sqlglot rewriting a name proves nothing about validity:
# it rewrites `charindex` to `locate`, but Databricks supports `charindex` too.
#
#   ALIAS_OK   Databricks accepts it as an alias. Runs correctly. A portability
#              signal about where the SQL came from, not a defect.
#   NO_EQUIV   No Databricks function of this name, so the statement errors.
TSQL_ALIAS_OK = {"charindex", "getdate", "len", "iif", "dateadd", "datepart"}
TSQL_NO_EQUIV = {
    "patindex", "stuff", "newid", "sysdatetime", "eomonth", "datename",
    "square", "choose", "datediff_big", "scope_identity", "getutcdate",
}
TSQL_ALL = TSQL_ALIAS_OK | TSQL_NO_EQUIV
TSQL_RE = {fn: re.compile(r"\b%s\s*\(" % re.escape(fn), re.I) for fn in TSQL_ALL}


# --------------------------------------------------------------------------
# input
# --------------------------------------------------------------------------

def fetch(profile, dest, warehouse=None):
    """Run the dump query through the Databricks CLI into `dest` as JSON."""
    sql_path = dest + ".sql"
    with open(sql_path, "w", encoding="utf-8") as fh:
        fh.write(DUMP_SQL)
    cmd = [
        "databricks", "experimental", "aitools", "tools", "query",
        "--file", sql_path, "--profile", profile, "--output", "json",
    ]
    if warehouse:
        cmd += ["--warehouse", warehouse]
    sys.stderr.write("running: %s\n" % " ".join(cmd))
    with open(dest, "w", encoding="utf-8") as out:
        proc = subprocess.run(cmd, stdout=out, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        sys.exit("dump failed: %s" % proc.stderr.decode("utf-8", "replace")[:2000])
    return dest


def load(path):
    with open(path, encoding="utf-8") as fh:
        rows = json.load(fh)
    if isinstance(rows, dict):            # single-query CLI shape
        rows = rows.get("rows", rows)
    out = []
    for r in rows:
        text = r.get("statement_text") or ""
        if not text.strip():
            continue
        out.append({
            "sql": text,
            "execs": int(r.get("exec_count") or 0),
            "datasets": _jlist(r.get("dataset_ids")),
            "ops": _jlist(r.get("source_operations")),
            "first_seen": r.get("first_seen"),
            "last_seen": r.get("last_seen"),
            "read_rows": int(r.get("read_rows_total") or 0),
            # Rows returned. Non-zero is the evidence that a statement actually
            # ran rather than erroring, which `qh` carries no status column for.
            "produced_rows": int(r.get("produced_rows_total") or 0),
            "avg_ms": float(r.get("avg_ms") or 0),
        })
    return out


def _jlist(v):
    """collect_set arrives as a JSON-encoded string through the CLI."""
    if v is None:
        return []
    if isinstance(v, list):
        return [x for x in v if x]
    try:
        parsed = json.loads(v)
        return [x for x in parsed if x] if isinstance(parsed, list) else [v]
    except (ValueError, TypeError):
        return [v]


# --------------------------------------------------------------------------
# classification
# --------------------------------------------------------------------------

# Two Power BI probe idioms, both of which learn a result shape without reading
# data. Measured on this dump: `WHERE 0=1` is 29,756 executions and `LIMIT 0` is
# 222,265, and every one of the 759 statements between them reports 0 rows read
# and 0 rows produced. `LIMIT 0` is the larger of the two by 7x, so missing it
# understates probe traffic badly -- it looked like real `select` work.
PROBE_RE = re.compile(
    r"\bwhere\s+0\s*=\s*1\b|\bwhere\s+1\s*=\s*0\b"
    r"|\blimit\s+0\s*;?\s*$",
    re.I,
)


def classify(sql, tree):
    """Bucket a statement by what it is for, not just by its root node."""
    if PROBE_RE.search(sql.strip()):
        return "schema_probe"
    if tree is None:
        return "unparsed"
    root = type(tree).__name__.lower()
    if isinstance(tree, exp.Select) or isinstance(tree, (exp.Union, exp.Subquery)):
        return "select"
    if isinstance(tree, (exp.Set, exp.SetItem)):
        return "session_set"
    if isinstance(tree, (exp.Show, exp.Describe)):
        return "metadata"
    if isinstance(tree, (exp.Create, exp.Drop, exp.Alter)):
        return "ddl"
    if isinstance(tree, (exp.Insert, exp.Update, exp.Delete, exp.Merge)):
        return "dml"
    if isinstance(tree, exp.Command):
        head = sql.strip().split(None, 1)[0].lower() if sql.strip() else ""
        return "command:" + head
    return root


def unwrap_pbi(tree):
    """Strip Power BI's `SELECT <cols> FROM (<real query>) AS `_`` envelope.

    Power BI emits the same generated query twice in different clothes: once as
    `SELECT * FROM (inner)` and once with the column list spelled out. Left
    alone they count as two unrelated shapes, which is how a handful of real
    queries turns into two thousand.

    Only unwrap when the outer layer adds nothing but a projection or a LIMIT --
    an outer WHERE, GROUP BY or ORDER BY is part of the query's meaning.
    """
    stripped = 0
    for _ in range(6):
        if not isinstance(tree, exp.Select) or tree.args.get("joins"):
            break
        frm = from_clause(tree)
        if frm is None:
            break
        src = frm.this
        if not isinstance(src, exp.Subquery):
            break
        inner = src.this
        if not isinstance(inner, (exp.Select, exp.Union, exp.With)):
            break
        if any(tree.args.get(k) for k in
               ("where", "group", "having", "qualify", "order", "distinct", "windows")):
            break
        tree, stripped = inner, stripped + 1
    return tree, stripped


def fingerprint(tree):
    """Collapse cosmetic variation so near-identical shapes group together.

    Three normalizations, in order of how much noise each removes: the Power BI
    envelope, identifier quoting and case (`DateID` and `dateid` are one column),
    and literals.
    """
    if tree is None:
        return None, 0
    clone, stripped = unwrap_pbi(tree.copy())
    clone = clone.copy()
    for ident in clone.find_all(exp.Identifier):
        ident.set("quoted", False)
        if isinstance(ident.this, str):
            ident.set("this", ident.this.lower())
    for lit in clone.find_all(exp.Literal):
        lit.replace(exp.Placeholder())
    for lst in clone.find_all(exp.In):
        if lst.args.get("expressions"):    # IN (?, ?, ?) -> IN (?)
            lst.set("expressions", [exp.Placeholder()])
    try:
        return clone.sql(dialect=DIALECT, normalize=True, comments=False), stripped
    except Exception:
        return None, stripped


# --------------------------------------------------------------------------
# extraction
# --------------------------------------------------------------------------

DEFAULT_CATALOG = "main"


def from_clause(select):
    """The FROM node of a Select.

    sqlglot 30 keys this as `from_`; earlier versions use `from`. Reading only
    one of them fails silently -- `args.get("from")` just returns None, so joins
    lose every edge touching the FROM-side table and nothing raises.
    """
    return select.args.get("from_") or select.args.get("from")


def table_name(t):
    """Canonical table identity, so one table counts once.

    Two normalizations, both of which otherwise split a table's traffic in half:
    case, and the default catalog. `main.schema.tbl` and `schema.tbl` are the same
    object because `main` is the default catalog in this workspace -- left alone,
    `provider` shows up twice with its executions divided between the spellings.
    """
    parts = [t.text("catalog"), t.text("db"), t.text("this")]
    parts = [p.lower() for p in parts if p]
    if len(parts) == 3 and parts[0] == DEFAULT_CATALOG:
        parts = parts[1:]
    return ".".join(parts)


def real_tables(tree):
    """Physical tables only — CTE and derived-table aliases are not sources."""
    cte_names = {c.alias_or_name.lower() for c in tree.find_all(exp.CTE)}
    found = set()
    for t in tree.find_all(exp.Table):
        name = table_name(t)
        if not name:
            continue
        if "." not in name and name.lower() in cte_names:
            continue
        found.add(name)
    return found


def columns_by_table(tree):
    """Attribute each column to its table using scope, honestly.

    No catalog is available here, so an unqualified column inside a scope with
    more than one source cannot be attributed. Those are counted separately
    rather than guessed at — a guessed attribution is worse than a known gap.
    """
    attributed = collections.defaultdict(set)
    ambiguous = set()
    try:
        root = build_scope(tree)
    except Exception:
        root = None
    if root is None:
        for c in tree.find_all(exp.Column):
            if c.table:
                attributed[c.table.lower()].add(c.name.lower())
            else:
                ambiguous.add(c.name.lower())
        return attributed, ambiguous

    for scope in root.traverse():
        # Physical tables only. A source that is itself a Scope is a CTE or
        # derived table, and its own base-table columns are already counted when
        # traverse() reaches that scope -- so skipping it here avoids double
        # counting rather than losing coverage.
        tables = {alias.lower(): table_name(src)
                  for alias, src in scope.sources.items()
                  if isinstance(src, exp.Table)}
        derived = {alias.lower() for alias, src in scope.sources.items()
                   if not isinstance(src, exp.Table)}
        # scope.columns is exactly this scope's columns, nested scopes excluded.
        for col in scope.columns:
            name = col.name.lower()
            qualifier = (col.table or "").lower()
            if qualifier:
                if qualifier in tables:
                    attributed[tables[qualifier]].add(name)
                elif qualifier not in derived:
                    ambiguous.add(name)
            elif len(tables) == 1 and not derived:
                attributed[next(iter(tables.values()))].add(name)
            elif tables or derived:
                ambiguous.add(name)
    return attributed, ambiguous


def join_pairs(tree):
    """Table pairs joined together, with the equality keys that link them.

    CTE references are excluded: a join to a CTE is a join to whatever the CTE
    selected from, and reporting `cte` as a table is worse than reporting nothing.
    Keys are lowercased so `HMCRequestID` and `hmcrequestid` are one edge.
    """
    cte_names = {c.alias_or_name.lower() for c in tree.find_all(exp.CTE)}
    pairs = set()
    for scope_expr in tree.find_all(exp.Select):
        alias_to_table = {}
        sources = [from_clause(scope_expr)] + list(scope_expr.args.get("joins") or [])
        for holder in sources:
            if holder is None:
                continue
            for t in holder.find_all(exp.Table):
                name = table_name(t)
                if "." not in name and name in cte_names:
                    continue
                alias_to_table[(t.alias or t.name).lower()] = name
        for j in scope_expr.args.get("joins") or []:
            on = j.args.get("on")
            if on is None:
                continue
            for eq in on.find_all(exp.EQ):
                left, right = eq.left, eq.right
                if not (isinstance(left, exp.Column) and isinstance(right, exp.Column)):
                    continue
                lt = alias_to_table.get((left.table or "").lower())
                rt = alias_to_table.get((right.table or "").lower())
                if not lt or not rt or lt == rt:
                    continue
                lo, hi = sorted([(lt, left.name.lower()), (rt, right.name.lower())])
                pairs.add((lo[0], hi[0], lo[1], hi[1], (j.side or "INNER").upper()))
    return pairs


def functions(tree):
    names = set()
    for f in tree.find_all(exp.Func):
        name = f.sql_name() if hasattr(f, "sql_name") else type(f).__name__
        if isinstance(f, exp.Anonymous):
            name = f.name
        names.add(name.lower())
    return names


def tsql_spellings(sql):
    """Scan raw text, because sqlglot rewrites these names away during parsing."""
    return {fn for fn, rx in TSQL_RE.items() if rx.search(sql)}


def filter_columns(tree):
    """Columns used in WHERE/HAVING predicates — the clustering candidates."""
    cols = set()
    for holder in list(tree.find_all(exp.Where)) + list(tree.find_all(exp.Having)):
        for c in holder.find_all(exp.Column):
            cols.add(c.name.lower())
    return cols


# --------------------------------------------------------------------------
# analysis
# --------------------------------------------------------------------------

class Counters(object):
    def __init__(self):
        self.kinds = collections.Counter()          # weighted by execs
        self.kinds_distinct = collections.Counter()
        self.tables = collections.Counter()
        self.tables_distinct = collections.Counter()
        self.table_rows_read = collections.Counter()
        self.columns = collections.defaultdict(collections.Counter)
        self.ambiguous_columns = collections.Counter()
        self.joins = collections.Counter()
        self.funcs = collections.Counter()
        self.tsql = collections.defaultdict(collections.Counter)
        self.tsql_produced = collections.Counter()   # rows returned, per function
        self.filters = collections.Counter()
        self.fingerprints = collections.Counter()
        self.fp_example = {}
        self.fp_tables = {}
        # Non-probe shapes only, with enough detail to export each one on its
        # own. Keyed by fingerprint; a probe and a real query can normalize to
        # the same fingerprint once `LIMIT 0` is stripped, so probe executions
        # must be excluded here rather than filtered out of the report later.
        self.shapes = {}
        self.tsql_examples = {}
        self.wrapped = 0
        self.parse_errors = []
        self.datasets = collections.Counter()
        self.dataset_tables = collections.defaultdict(set)
        self.heaviest = []
        self.execs_total = 0
        self.stmts_total = 0


def analyze(rows):
    c = Counters()
    for r in rows:
        sql, w = r["sql"], max(r["execs"], 1)
        c.execs_total += w
        c.stmts_total += 1
        for d in r["datasets"]:
            c.datasets[d] += w

        tree = None
        try:
            trees = sqlglot.parse(sql, dialect=DIALECT)
            tree = trees[0] if trees else None
        except Exception as e:            # ParseError and friends
            c.parse_errors.append((w, str(e).split("\n")[0][:160], sql[:200]))

        kind = classify(sql, tree)
        c.kinds[kind] += w
        c.kinds_distinct[kind] += 1

        # Raw-text scan, before the parse guard: a statement sqlglot could not
        # parse is exactly where a ported SQL Server function is most likely.
        for fn in tsql_spellings(sql):
            c.tsql[fn][kind] += w
            c.tsql_produced[fn] += r["produced_rows"]
            c.tsql_examples.setdefault(fn, sql)

        if tree is None:
            continue

        tabs = real_tables(tree)
        for t in tabs:
            c.tables[t] += w
            c.tables_distinct[t] += 1
            c.table_rows_read[t] += r["read_rows"]
            for d in r["datasets"]:
                c.dataset_tables[d].add(t)

        attributed, ambiguous = columns_by_table(tree)
        for t, cols in attributed.items():
            for col in cols:
                c.columns[t][col] += w
        for col in ambiguous:
            c.ambiguous_columns[col] += w

        for p in join_pairs(tree):
            c.joins[p] += w

        for fn in functions(tree):
            c.funcs[fn] += w

        for col in filter_columns(tree):
            c.filters[col] += w

        fp, stripped = fingerprint(tree)
        if fp:
            c.fingerprints[fp] += w
            c.fp_example.setdefault(fp, sql)
            c.fp_tables.setdefault(fp, sorted(tabs))
            if kind != "schema_probe":
                s = c.shapes.get(fp)
                if s is None:
                    s = c.shapes[fp] = {
                        "fp": fp, "execs": 0, "texts": 0, "tables": set(),
                        "datasets": set(), "read": 0, "produced": 0,
                        "example": None, "example_execs": -1, "avg_ms": 0.0,
                    }
                s["execs"] += w
                s["texts"] += 1
                s["tables"].update(tabs)
                s["datasets"].update(r["datasets"])
                s["read"] += r["read_rows"]
                s["produced"] += r["produced_rows"]
                # Keep the most-executed text as the representative, so the
                # exported file is the variant that actually dominates load.
                if w > s["example_execs"]:
                    s["example"], s["example_execs"] = sql, w
                    s["avg_ms"] = r["avg_ms"]
        if stripped:
            c.wrapped += w

        c.heaviest.append((r["read_rows"], w, r["avg_ms"], sorted(tabs), sql[:160]))
    return c


# --------------------------------------------------------------------------
# report
# --------------------------------------------------------------------------

def pct(n, d):
    return "%.1f%%" % (100.0 * n / d) if d else "n/a"


def num(n):
    return "{:,}".format(int(n))


def report(c, rows, limit):
    o = []
    w = o.append
    w("# Power BI SQL landscape — `workspace_jf.landscape.qh`\n")
    w("Parsed with sqlglot %s, dialect `%s`.\n" % (sqlglot.__version__, DIALECT))
    first = min([r["first_seen"] for r in rows if r["first_seen"]] or [""])
    last = max([r["last_seen"] for r in rows if r["last_seen"]] or [""])
    w("| | |")
    w("|---|---|")
    w("| Distinct statements | %s |" % num(c.stmts_total))
    w("| Executions | %s |" % num(c.execs_total))
    w("| Window | %s → %s |" % (first, last))
    w("| Power BI datasets | %s |" % num(len(c.datasets)))
    w("| Distinct physical tables | %s |" % num(len(c.tables)))
    err_w = sum(x[0] for x in c.parse_errors)
    w("| Parse failures | %s statements (%s of executions) |"
      % (num(len(c.parse_errors)), pct(err_w, c.execs_total)))
    w("")

    w("## Statement kinds\n")
    w("Weighted by execution, because that is what the warehouse actually ran.\n")
    w("| Kind | Executions | Share | Distinct statements |")
    w("|---|---:|---:|---:|")
    for k, n in c.kinds.most_common():
        w("| `%s` | %s | %s | %s |" % (k, num(n), pct(n, c.execs_total), num(c.kinds_distinct[k])))
    w("")

    w("## Tables by execution\n")
    w("Names are canonical: lowercased, and a leading `main.` dropped, so a table")
    w("referenced both ways counts once.\n")
    w("| Table | Executions | Share | Distinct statements | Rows read by those statements |")
    w("|---|---:|---:|---:|---:|")
    for t, n in c.tables.most_common(limit):
        w("| `%s` | %s | %s | %s | %s |"
          % (t, num(n), pct(n, c.execs_total), num(c.tables_distinct[t]), num(c.table_rows_read[t])))
    w("")
    w("> [!NOTE]")
    w("> **The rows-read column is per statement, not per table**")
    w(">")
    w("> Query history reports rows read for the whole statement. A statement")
    w("> touching six tables contributes its full count to all six, so two tables")
    w("> that always appear together show identical totals. Use it to rank, not to")
    w("> attribute volume to one table.")
    w("")

    w("## Query shapes after normalization\n")
    w("Power BI envelope stripped, identifiers unquoted and lowercased, literals")
    w("placeholdered — so `SELECT * FROM (q)` and `` SELECT `Col` FROM (q) `` are one shape.")
    w("**Schema probes are excluded**: stripping `LIMIT 0` would otherwise merge a")
    w("probe into the real shape it probes.\n")
    shapes = sorted(c.shapes.values(), key=lambda s: -s["execs"])
    real_execs = sum(s["execs"] for s in shapes)
    w("| Executions | Share of real | Tables | Shape (truncated) |")
    w("|---:|---:|---|---|")
    for s in shapes[:limit]:
        tabs = sorted(s["tables"])
        flat = " ".join(s["fp"].split())
        w("| %s | %s | %s | `%s` |"
          % (num(s["execs"]), pct(s["execs"], real_execs),
             ", ".join("`%s`" % t for t in tabs[:3]) or "—",
             flat[:110].replace("|", "\\|")))
    w("")
    w("Collapse: %s distinct statements → %s shapes, of which **%s are real queries** "
      "and the rest are probe-only. %s executions (%s) carried a Power BI envelope "
      "that was stripped.\n"
      % (num(c.stmts_total), num(len(c.fingerprints)), num(len(shapes)),
         num(c.wrapped), pct(c.wrapped, c.execs_total)))

    w("## Columns actually referenced, per table\n")
    w("Unqualified columns in a multi-source scope are not attributed — see the")
    w("unattributed list below rather than treating this as complete.\n")
    for t, _ in c.tables.most_common(limit):
        cols = c.columns.get(t)
        if not cols:
            continue
        w("**`%s`** — %s columns referenced\n" % (t, num(len(cols))))
        w("| Column | Executions |")
        w("|---|---:|")
        for col, n in cols.most_common(25):
            w("| `%s` | %s |" % (col, num(n)))
        w("")

    if c.ambiguous_columns:
        w("### Unattributed columns\n")
        w("Referenced without a qualifier in a scope with several sources.\n")
        w("| Column | Executions |")
        w("|---|---:|")
        for col, n in c.ambiguous_columns.most_common(30):
            w("| `%s` | %s |" % (col, num(n)))
        w("")

    w("## Join graph\n")
    w("What the reporting layer actually joins, and on what.\n")
    w("| Left | Right | Keys | Side | Executions |")
    w("|---|---|---|---|---:|")
    for (lt, rt, lk, rk, side), n in c.joins.most_common(limit):
        w("| `%s` | `%s` | `%s` = `%s` | %s | %s |" % (lt, rt, lk, rk, side, num(n)))
    if not c.joins:
        w("| — | — | — | — | — |")
    w("")

    w("## SQL Server function spellings\n")
    if c.tsql:
        w("Found by scanning the raw text, because sqlglot canonicalizes these while")
        w("parsing -- `CHARINDEX` becomes `LOCATE`, `getdate()` becomes")
        w("`CURRENT_TIMESTAMP` -- so a parse-tree scan never sees them.\n")
        w("`alias` means Databricks accepts the spelling and the statement runs")
        w("normally; the rows-returned column is the evidence. `no equivalent` means")
        w("Databricks has no function of that name, so those statements do error.\n")
        w("| Function | Class | Executions | Rows returned | Statement kinds | Example |")
        w("|---|---|---:|---:|---|---|")
        bad = []
        for fn, kinds in sorted(c.tsql.items(), key=lambda kv: -sum(kv[1].values())):
            alias = fn in TSQL_ALIAS_OK
            if not alias:
                bad.append(fn)
            ex = " ".join((c.tsql_examples.get(fn) or "").split())[:60]
            w("| `%s` | %s | %s | %s | %s | `%s` |"
              % (fn, "alias" if alias else "**no equivalent**",
                 num(sum(kinds.values())), num(c.tsql_produced[fn]),
                 ", ".join("%s (%s)" % (k, num(v)) for k, v in kinds.most_common(3)),
                 ex.replace("|", "\\|")))
        w("")
        if bad:
            w("> [!WARNING]")
            w("> **%d spelling(s) Databricks does not support**" % len(bad))
            w(">")
            w("> %s. These statements error rather than returning wrong answers."
              % ", ".join("`%s`" % f for f in bad))
        else:
            w("> [!NOTE]")
            w("> **These run correctly -- portability signal, not a defect**")
            w(">")
            w("> Every spelling found is one Databricks supports as an alias, and the")
            w("> rows-returned column confirms the statements execute. The %d"
              % len(TSQL_NO_EQUIV))
            w("> unsupported spellings scanned for (%s)"
              % ", ".join("`%s`" % f for f in sorted(TSQL_NO_EQUIV)))
            w("> appear nowhere. So nothing here needs fixing: it is a provenance")
            w("> signal -- SQL authored against SQL Server, still carrying its")
            w("> original spelling. Worth normalizing only to keep one dialect.")
    else:
        w("None found.")
    w("")

    w("## Most-used functions\n")
    w("These are sqlglot's canonical node names, not Databricks spellings, so")
    w("don't look them up in the Databricks docs: `str_position` is `charindex` /")
    w("`locate`, `time_to_str` is `date_format`, `ts_or_ds_to_date` is `to_date`.")
    w("`case` and `if` track the same expression and so report the same count.\n")
    w("| Function | Executions |")
    w("|---|---:|")
    for fn, n in c.funcs.most_common(30):
        w("| `%s` | %s |" % (fn, num(n)))
    w("")

    w("## Predicate columns\n")
    w("Filter and join columns — the evidence for clustering and partitioning.\n")
    w("| Column | Executions |")
    w("|---|---:|")
    for col, n in c.filters.most_common(limit):
        w("| `%s` | %s |" % (col, num(n)))
    w("")

    w("## Heaviest statements by rows read\n")
    w("| Rows read | Executions | Avg ms | Tables | SQL |")
    w("|---:|---:|---:|---|---|")
    for rr, ex, ms, tabs, snip in sorted(c.heaviest, reverse=True)[:20]:
        w("| %s | %s | %s | %s | `%s` |"
          % (num(rr), num(ex), num(ms), ", ".join("`%s`" % t for t in tabs[:3]) or "—",
             " ".join(snip.split())[:90].replace("|", "\\|")))
    w("")

    w("## Tables per dataset\n")
    w("| Dataset | Tables | Executions |")
    w("|---|---:|---:|")
    for d, n in c.datasets.most_common(limit):
        w("| `%s` | %s | %s |" % (d, num(len(c.dataset_tables.get(d, ()))), num(n)))
    w("")

    if c.parse_errors:
        w("## Parse failures\n")
        w("sqlglot could not parse these. Each is either genuinely invalid or a")
        w("dialect gap — check before concluding the statement is broken.\n")
        w("| Executions | Error | SQL |")
        w("|---:|---|---|")
        for ex, err, snip in sorted(c.parse_errors, reverse=True)[:25]:
            w("| %s | %s | `%s` |"
              % (num(ex), err.replace("|", "\\|"),
                 " ".join(snip.split())[:80].replace("|", "\\|")))
        w("")
    return "\n".join(o)


def dominant_table(tables):
    """A short label for a file name: the deepest-suffix table name, or none."""
    if not tables:
        return "no-table"
    t = sorted(tables)[0].split(".")[-1]
    return re.sub(r"[^a-z0-9]+", "-", t.lower()).strip("-") or "query"


def unwrapped_sql(sql):
    """The real query with Power BI's envelope removed, pretty-printed.

    Falls back to the original text when it will not parse or nothing was
    wrapped, so no file is ever silently emptied.
    """
    try:
        trees = sqlglot.parse(sql, dialect=DIALECT)
        tree = trees[0] if trees else None
    except Exception:
        return sql.strip(), False
    if tree is None:
        return sql.strip(), False
    inner, stripped = unwrap_pbi(tree)
    if not stripped:
        return sql.strip(), False
    try:
        return inner.sql(dialect=DIALECT, pretty=True), True
    except Exception:
        return sql.strip(), False


def write_queries(c, outdir):
    """One .sql file per distinct non-probe query shape, ranked by executions."""
    os.makedirs(outdir, exist_ok=True)
    for stale in sorted(os.listdir(outdir)):
        if stale.endswith((".sql", ".md")):
            os.remove(os.path.join(outdir, stale))

    shapes = sorted(c.shapes.values(), key=lambda s: -s["execs"])
    width = max(4, len(str(len(shapes))))
    index = []
    for i, s in enumerate(shapes, 1):
        tables = sorted(s["tables"])
        stem = "%0*d-%s" % (width, i, dominant_table(tables))
        body, stripped = unwrapped_sql(s["example"])
        head = [
            "-- Power BI query shape %d of %d, from workspace_jf.landscape.qh." % (i, len(shapes)),
            "-- Not a schema probe: this shape reads data and returns rows.",
            "--",
            "-- Executions            %s" % num(s["execs"]),
            "-- Distinct texts        %s (same query, different literals or projection)" % num(s["texts"]),
            "-- Rows read             %s" % num(s["read"]),
            "-- Rows returned         %s" % num(s["produced"]),
            "-- Avg duration          %s ms" % num(s["avg_ms"]),
            "-- Power BI datasets     %s" % (", ".join(sorted(s["datasets"])) or "none recorded"),
            "-- Tables                %s" % (", ".join(tables) or "none resolved"),
            "--",
            "-- %s" % ("Power BI's `SELECT ... FROM (...) AS `_`` envelope was stripped, so this"
                       if stripped else
                       "Verbatim as executed; no Power BI envelope to strip."),
        ]
        if stripped:
            head.append("-- is the inner query as written, reformatted by sqlglot -- not the exact")
            head.append("-- bytes Power BI sent.")
        with open(os.path.join(outdir, stem + ".sql"), "w", encoding="utf-8") as fh:
            fh.write("\n".join(head) + "\n\n" + body.rstrip() + "\n")
        index.append((i, stem, s, tables))

    total = sum(s["execs"] for s in shapes)
    with open(os.path.join(outdir, "INDEX.md"), "w", encoding="utf-8") as fh:
        o = fh.write
        o("# Power BI query shapes — schema probes excluded\n\n")
        o("%s distinct query shapes over %s executions, from"
          " `workspace_jf.landscape.qh`.\n\n" % (num(len(shapes)), num(total)))
        o("A *shape* is one query after Power BI's DirectQuery envelope is stripped,\n")
        o("identifiers are lowercased and unquoted, and literals are replaced with a\n")
        o("placeholder. Power BI emits the same generated query many times over with\n")
        o("different literals and projections; those collapse to one file here.\n\n")
        o("> [!NOTE]\n")
        o("> **Schema probes are excluded**\n")
        o(">\n")
        o("> `WHERE 0=1` and `LIMIT 0` statements are Power BI learning a result\n")
        o("> shape. Every one reads 0 rows and returns 0 rows, so none of them is a\n")
        o("> query anyone wrote. They are not in this folder.\n\n")
        o("| # | File | Executions | Rows returned | Tables |\n")
        o("|---:|---|---:|---:|---|\n")
        for i, stem, s, tables in index:
            o("| %d | [%s.sql](%s.sql) | %s | %s | %s |\n"
              % (i, stem, stem, num(s["execs"]), num(s["produced"]),
                 ", ".join("`%s`" % t for t in tables) or "—"))
    return outdir, len(shapes), total


def write_csvs(c, outdir):
    import csv
    os.makedirs(outdir, exist_ok=True)

    def dump(name, header, rows):
        with open(os.path.join(outdir, name), "w", newline="", encoding="utf-8") as fh:
            wr = csv.writer(fh)
            wr.writerow(header)
            wr.writerows(rows)

    def snippet(sql, n=300):
        """One-line, bounded example. Whole statements here would make the CSV
        unreadable and spread the literals embedded in them further than needed."""
        s = " ".join((sql or "").split())
        return s[:n] + (" ..." if len(s) > n else "")

    dump("tables.csv", ["table", "executions", "distinct_statements", "rows_read"],
         [(t, n, c.tables_distinct[t], c.table_rows_read[t]) for t, n in c.tables.most_common()])
    dump("columns.csv", ["table", "column", "executions"],
         [(t, col, n) for t, cols in c.columns.items() for col, n in cols.most_common()])
    dump("joins.csv", ["left_table", "right_table", "left_key", "right_key", "side", "executions"],
         [(lt, rt, lk, rk, side, n) for (lt, rt, lk, rk, side), n in c.joins.most_common()])
    dump("functions.csv", ["function", "executions"], c.funcs.most_common())
    dump("tsql_spellings.csv",
         ["function", "class", "executions", "produced_rows", "example"],
         [(fn, "alias" if fn in TSQL_ALIAS_OK else "no_equivalent",
           sum(kinds.values()), c.tsql_produced[fn], snippet(c.tsql_examples.get(fn)))
          for fn, kinds in sorted(c.tsql.items(), key=lambda kv: -sum(kv[1].values()))])
    dump("shapes.csv", ["executions", "shape", "example"],
         [(n, snippet(fp, 600), snippet(c.fp_example.get(fp)))
          for fp, n in c.fingerprints.most_common()])
    dump("predicate_columns.csv", ["column", "executions"], c.filters.most_common())
    return outdir


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    src = ap.add_argument_group("input")
    src.add_argument("--fetch", action="store_true",
                     help="dump distinct SQL from the workspace first (read-only)")
    src.add_argument("--profile", help="Databricks CLI profile; required with --fetch, never defaulted")
    src.add_argument("--warehouse", help="SQL warehouse id (optional)")
    src.add_argument("--input", default="qh_distinct.json",
                     help="path to the JSON dump (default: qh_distinct.json)")
    ap.add_argument("--out", help="write the markdown report here (default: stdout)")
    ap.add_argument("--csv-dir", help="also write machine-readable CSVs to this directory")
    ap.add_argument("--queries-dir",
                    help="write one .sql file per distinct non-probe query shape here, "
                         "plus an INDEX.md")
    ap.add_argument("--limit", type=int, default=30, help="rows per report table (default: 30)")
    args = ap.parse_args()

    if args.fetch:
        if not args.profile:
            ap.error("--fetch requires --profile. dbc-88a3d066-4cdb is production and is "
                     "the CLI default, so the profile must be chosen explicitly.")
        fetch(args.profile, args.input, args.warehouse)
    elif args.profile:
        sys.stderr.write("note: --profile given without --fetch; reading %s from disk\n" % args.input)

    if not os.path.exists(args.input):
        sys.exit("no dump at %s — run again with --fetch --profile <PROFILE>" % args.input)

    rows = load(args.input)
    if not rows:
        sys.exit("dump at %s has no statements" % args.input)
    sys.stderr.write("analyzing %d distinct statements\n" % len(rows))

    c = analyze(rows)
    text = report(c, rows, args.limit)

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(text)
        sys.stderr.write("report: %s\n" % args.out)
    else:
        sys.stdout.write(text)

    if args.csv_dir:
        sys.stderr.write("csvs: %s\n" % write_csvs(c, args.csv_dir))

    if args.queries_dir:
        d, n, execs = write_queries(c, args.queries_dir)
        sys.stderr.write("queries: %s (%s shapes, %s executions, probes excluded)\n"
                         % (d, num(n), num(execs)))


if __name__ == "__main__":
    main()
