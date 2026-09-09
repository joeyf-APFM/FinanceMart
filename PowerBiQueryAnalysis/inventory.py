import re, os, collections
root = "/Users/joey.filichia/Projects/dbx_workspaces/FinanceMart/Assets"
WL = re.compile(r'\[\[([^\]]+)\]\]')
shapes = collections.Counter()
anchors, esc, targets = [], 0, collections.Counter()
for dp,_,fns in os.walk(root):
    for fn in fns:
        if not fn.endswith('.md'): continue
        p = os.path.join(dp,fn)
        for m in WL.finditer(open(p,encoding='utf-8').read()):
            inner = m.group(1)
            has_esc = r'\|' in inner
            if has_esc: esc += 1
            norm = inner.replace(r'\|','|')
            if '|' in norm:
                tgt,lab = norm.split('|',1); shapes['target|label'] += 1
            else:
                tgt,lab = norm,None; shapes['target only'] += 1
            if '#' in tgt:
                anchors.append((os.path.relpath(p,root), inner)); shapes['has anchor'] += 1
            targets[tgt.strip()] += 1
print("shapes:", dict(shapes)); print("escaped-pipe count:", esc)
print("\nanchors:", anchors[:20])
print("\n=== target resolution ===")
def resolve(tgt, srcdir):
    if '/' in tgt or tgt.endswith('.sql'):
        cand = os.path.normpath(os.path.join(srcdir, tgt))
        return cand, os.path.exists(cand)
    for d in (srcdir, os.path.join(root,'Table Specifications'), root):
        cand = os.path.join(d, tgt + '.md')
        if os.path.exists(cand): return cand, True
    return os.path.join(srcdir, tgt + '.md'), False
seen = {}
for dp,_,fns in os.walk(root):
    for fn in fns:
        if not fn.endswith('.md'): continue
        p = os.path.join(dp,fn); srcdir = os.path.dirname(p)
        for m in WL.finditer(open(p,encoding='utf-8').read()):
            norm = m.group(1).replace(r'\|','|')
            tgt = norm.split('|',1)[0].split('#',1)[0].strip()
            path, ok = resolve(tgt, srcdir)
            key = (tgt, os.path.relpath(srcdir, root))
            if key not in seen: seen[key] = (ok, os.path.relpath(path, root) if ok else path)
for (tgt, sd), (ok, path) in sorted(seen.items(), key=lambda x: (x[1][0], x[0][0])):
    if not ok: print(f"  MISSING  from {sd:22} {tgt!r}  ->  {path}")
print()
for (tgt, sd), (ok, path) in sorted(seen.items()):
    if ok: print(f"  ok       from {sd:22} {tgt!r}  ->  {path}")
