import os, re, collections
root = '/Users/joey.filichia/Projects/dbx_workspaces/FinanceMart'
GH = {'NOTE','TIP','IMPORTANT','WARNING','CAUTION'}
marker = re.compile(r'^>\s*\[!([^\]]+)\](.*)$')
anybang = re.compile(r'\[!([^\]]+)\]')
stats = collections.Counter()
problems = []
files_with_alerts = set()
fenced_in_quote = 0
for dp, dn, fn in os.walk(root):
    dn[:] = [d for d in dn if d not in ('.git', '.venv', 'node_modules')]
    for f in fn:
        if not f.endswith('.md'):
            continue
        p = os.path.join(dp, f)
        rel = os.path.relpath(p, root)
        lines = open(p, encoding='utf-8').read().split('\n')
        for i, ln in enumerate(lines, 1):
            if ln.startswith('> ```'):
                fenced_in_quote += 1
            m = marker.match(ln)
            if m:
                t, rest = m.group(1), m.group(2)
                stats[t] += 1
                files_with_alerts.add(rel)
                if t not in GH:
                    problems.append(f'{rel}:{i} non-GitHub type [!{t}]')
                if rest.strip():
                    problems.append(f'{rel}:{i} trailing text after marker: {rest.strip()[:60]!r}')
                # first body line should be the bold title, second a bare separator
                nxt = lines[i] if i < len(lines) else ''
                if not re.match(r'^> \*\*.+\*\*$', nxt):
                    problems.append(f'{rel}:{i+1} expected bold title line, got {nxt[:60]!r}')
            elif anybang.search(ln) and not ln.lstrip().startswith('|'):
                for t in anybang.findall(ln):
                    if t.upper() in GH or t.lower() in ('warning','danger','info','note','tip','important','caution'):
                        problems.append(f'{rel}:{i} callout-looking marker not at line start: {ln.strip()[:70]!r}')
print('alerts by type:', dict(stats), 'total', sum(stats.values()))
print('files with alerts:', len(files_with_alerts))
print('fenced blocks inside blockquotes:', fenced_in_quote)
print('problems:', len(problems))
for x in problems[:20]:
    print('  ', x)
