import re, os, sys, collections
root = "/Users/joey.filichia/Projects/dbx_workspaces/FinanceMart/Assets"
DRY = "--apply" not in sys.argv
# Obsidian type -> GitHub alert type. GitHub has exactly five.
MAP = {'warning':'WARNING', 'danger':'CAUTION', 'info':'NOTE',
       'note':'NOTE', 'tip':'TIP', 'important':'IMPORTANT', 'caution':'CAUTION'}
HEAD = re.compile(r'^> ?\[!([a-zA-Z-]+)\](.*)$')
stats = collections.Counter()
unmapped = set()
for dp, _, fns in os.walk(root):
    for fn in sorted(fns):
        if not fn.endswith('.md'): continue
        p = os.path.join(dp, fn)
        lines = open(p, encoding='utf-8').read().split('\n')
        out, i, changed = [], 0, False
        while i < len(lines):
            m = HEAD.match(lines[i])
            if not m:
                out.append(lines[i]); i += 1; continue
            typ, title = m.group(1).lower(), m.group(2).strip()
            gh = MAP.get(typ)
            if gh is None:
                unmapped.add(typ); out.append(lines[i]); i += 1; continue
            stats[f'{typ} -> {gh}'] += 1
            out.append(f'> [!{gh}]')
            if title:
                # Nested ** inside a title would break the outer bold; demote to italic.
                if '**' in title:
                    title = title.replace('**', '*')
                    stats['nested-bold-demoted'] += 1
                out.append(f'> **{title}**')
                nxt = lines[i+1] if i+1 < len(lines) else ''
                # Separator only when real body content follows, so the title
                # renders as its own paragraph instead of running into it.
                if nxt.startswith('>') and nxt.strip() != '>':
                    out.append('>')
                    stats['separator-added'] += 1
            else:
                stats['no-title'] += 1
            changed = True
            i += 1
        if changed:
            stats['files'] += 1
            if not DRY:
                open(p, 'w', encoding='utf-8').write('\n'.join(out))
print(("DRY RUN" if DRY else "APPLIED"), dict(stats))
if unmapped: print("UNMAPPED TYPES:", unmapped)
