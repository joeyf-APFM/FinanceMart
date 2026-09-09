import re, os, urllib.parse, difflib
new_root = "/Users/joey.filichia/Projects/dbx_workspaces/FinanceMart/Assets"
old_root = os.environ['CLAUDE_JOB_DIR'] + "/tmp/Assets.bak"
WL = re.compile(r'\[\[([^\]]+)\]\]')
MD = re.compile(r'(?<!\!)\[([^\]]*)\]\(([^)]+)\)')
def flat_old(t):
    return MD.sub(lambda m: m.group(1),
           WL.sub(lambda m: (m.group(1).replace(r'\|','|').split('|',1)+[None])[1]
                            or m.group(1).replace(r'\|','|'), t))
def flat_new(t):
    return MD.sub(lambda m: m.group(1), WL.sub(lambda m: m.group(1), t))
diffs = 0
for dp,_,fns in os.walk(new_root):
    for fn in sorted(fns):
        if not fn.endswith('.md'): continue
        rel = os.path.relpath(os.path.join(dp,fn), new_root)
        a = flat_old(open(os.path.join(old_root,rel),encoding='utf-8').read()).splitlines()
        b = flat_new(open(os.path.join(new_root,rel),encoding='utf-8').read()).splitlines()
        if a != b:
            diffs += 1
            print(f"--- {rel}")
            for line in difflib.unified_diff(a,b,lineterm='',n=0):
                if line.startswith(('---','+++','@@')): continue
                print("   ", line[:200])
print(f"\nfiles whose visible text changed: {diffs} of 32")
