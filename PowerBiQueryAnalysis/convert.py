import re, os, sys, urllib.parse, collections
root = "/Users/joey.filichia/Projects/dbx_workspaces/FinanceMart/Assets"
DRY = "--apply" not in sys.argv
WL = re.compile(r'\[\[([^\]]+)\]\]')
# Links whose targets live outside this repo -- left for manual handling.
EXTERNAL = ('../../plans/', '../Finance Semantic Layer')

def enc(p):
    return urllib.parse.quote(p, safe='/.-_')

def resolve(tgt, srcdir):
    """Return repo-relative URL for a wikilink target, or None if unresolvable."""
    if '/' in tgt or tgt.endswith('.sql'):
        # already a path; append .md when it points at a note without extension
        cand = os.path.normpath(os.path.join(srcdir, tgt))
        if os.path.isdir(cand):
            return enc(tgt)
        if os.path.exists(cand):
            return enc(tgt)
        if os.path.exists(cand + '.md'):
            return enc(tgt + '.md')
        return None
    for d, prefix in ((srcdir, ''),
                      (os.path.join(root, 'Table Specifications'), 'Table Specifications/'),
                      (root, '')):
        if os.path.exists(os.path.join(d, tgt + '.md')):
            rel = os.path.relpath(os.path.join(d, tgt + '.md'), srcdir)
            return enc(rel)
    return None

stats = collections.Counter()
unresolved = []
for dp, _, fns in os.walk(root):
    for fn in sorted(fns):
        if not fn.endswith('.md'):
            continue
        p = os.path.join(dp, fn)
        srcdir = os.path.dirname(p)
        orig = open(p, encoding='utf-8').read()

        def sub(m):
            inner = m.group(1)
            norm = inner.replace(r'\|', '|')
            tgt, label = (norm.split('|', 1) + [None])[:2]
            tgt = tgt.strip()
            if tgt.startswith(EXTERNAL):
                stats['skipped-external'] += 1
                return m.group(0)
            url = resolve(tgt, srcdir)
            if url is None:
                unresolved.append((os.path.relpath(p, root), inner))
                stats['unresolved'] += 1
                return m.group(0)
            text = label if label is not None else tgt
            stats['converted'] += 1
            return f'[{text}]({url})'

        new = WL.sub(sub, orig)
        if new != orig and not DRY:
            open(p, 'w', encoding='utf-8').write(new)
        if new != orig:
            stats['files-changed'] += 1

print(("DRY RUN" if DRY else "APPLIED"), dict(stats))
if unresolved:
    print("UNRESOLVED:")
    for f, i in unresolved:
        print("  ", f, i)
