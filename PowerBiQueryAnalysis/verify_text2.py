import os, re, difflib

CUR = '/Users/joey.filichia/Projects/dbx_workspaces/FinanceMart/Assets'
BAK = os.path.join(os.environ['CLAUDE_JOB_DIR'], 'tmp', 'Assets.bak')

wiki = re.compile(r'\[\[([^\]]+)\]\]')
mdlink = re.compile(r'\[([^\]]*)\]\(([^)]+)\)')
alert = re.compile(r'^>\s*\[!([a-zA-Z-]+)\]\s*(.*)$')


def flatten(text):
    """Reduce to visible prose: links -> label, callout scaffolding -> normalized."""
    out = []
    lines = text.split('\n')
    i = 0
    while i < len(lines):
        ln = lines[i]
        m = alert.match(ln)
        if m:
            typ, rest = m.group(1).lower(), m.group(2).strip()
            title = rest
            if not title:
                # GitHub form: title is on the next line as > **Title**
                nxt = lines[i + 1] if i + 1 < len(lines) else ''
                tm = re.match(r'^>\s*\*+(.+?)\*+\s*$', nxt)
                if tm:
                    title = tm.group(1)
                    i += 1
                    # skip an inserted bare '>' separator
                    if i + 1 < len(lines) and lines[i + 1].strip() == '>':
                        i += 1
            # normalize the Obsidian/GitHub type spellings onto one token
            typ = {'danger': 'caution', 'info': 'note'}.get(typ, typ)
            # inner bold demoted to italic in titles -> normalize emphasis away
            title = title.replace('**', '').replace('*', '')
            out.append(f'CALLOUT {typ}: {title}')
            i += 1
            continue
        ln = wiki.sub(lambda m: m.group(1).split('|')[-1].replace('\\', ''), ln)
        ln = mdlink.sub(lambda m: m.group(1), ln)
        out.append(ln.rstrip())
        i += 1
    return [l for l in out if l != '']


changed = []
for f in sorted(os.listdir(BAK)):
    pass

pairs = []
for dp, dn, fn in os.walk(BAK):
    for f in fn:
        if f.endswith('.md'):
            b = os.path.join(dp, f)
            c = os.path.join(CUR, os.path.relpath(b, BAK))
            pairs.append((os.path.relpath(b, BAK), b, c))

for rel, b, c in sorted(pairs):
    if not os.path.exists(c):
        changed.append((rel, ['MISSING in current']))
        continue
    fb = flatten(open(b, encoding='utf-8').read())
    fc = flatten(open(c, encoding='utf-8').read())
    if fb != fc:
        d = [l for l in difflib.unified_diff(fb, fc, lineterm='', n=0)
             if l.startswith(('+', '-')) and not l.startswith(('+++', '---'))]
        changed.append((rel, d))

print(f'files compared: {len(pairs)}')
print(f'files whose visible text changed: {len(changed)}')
for rel, d in changed:
    print(f'\n--- {rel}')
    for l in d[:8]:
        print('   ', l[:200])
