import re, os, urllib.parse, collections
root = "/Users/joey.filichia/Projects/dbx_workspaces/FinanceMart/Assets"
MD = re.compile(r'(?<!\!)\[([^\]]*)\]\(([^)]+)\)')
WL = re.compile(r'\[\[')
bad, total, wl = [], 0, 0
per = collections.Counter()
for dp, _, fns in os.walk(root):
    for fn in sorted(fns):
        if not fn.endswith('.md'): continue
        p = os.path.join(dp, fn); rel = os.path.relpath(p, root)
        txt = open(p, encoding='utf-8').read()
        n = len(WL.findall(txt)); wl += n
        if n: bad.append((rel, f"{n} wikilink(s) remain"))
        for m in MD.finditer(txt):
            total += 1; per[rel] += 1
            text, url = m.group(1), m.group(2)
            if url.startswith(('http://','https://','#','mailto:')): continue
            path = urllib.parse.unquote(url.split('#')[0])
            tgt = os.path.normpath(os.path.join(os.path.dirname(p), path))
            if not os.path.exists(tgt):
                bad.append((rel, f"BROKEN [{text}]({url}) -> {tgt}"))
print(f"markdown links: {total}   files: {len(per)}   wikilinks remaining: {wl}")
if bad:
    print("PROBLEMS:")
    for f, msg in bad: print(f"  {f}: {msg}")
else:
    print("OK - every relative link resolves to an existing file, no wikilinks left")
