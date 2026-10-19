#!/usr/bin/env python3
"""Opt-in native AppModel probe, own UUID stores only; no system alarms/audio asset.

Requires macOS/Xcode and the project's already built FeedKit/XMLKit Debug products.
Writes a new external output directory and retains its synthetic UUID stores.
"""
from pathlib import Path
import argparse,hashlib,json,plistlib,subprocess,time,uuid

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--products',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args();w=Path(__file__).resolve().parents[1];out=a.output.resolve()
assert a.output.is_absolute() and not out.exists() and not out.is_relative_to(w)
products=a.products.resolve();assert all((products/n).is_file() for n in ['FeedKit.o','XMLKit.o'])
out.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
write=lambda p,x:p.write_text(json.dumps(x,indent=2)+'\n')
source_paths=sorted(p for root in ['Sources','Tests','Resources','Scripts','HomeViewReplica.xcodeproj'] for p in (w/root).rglob('*') if p.is_file() and not {'xcuserdata','__pycache__'}.intersection(p.parts))
source_paths+=sorted(p for p in [w/'Package.swift',w/'Package.resolved'] if p.exists())
source=[dict(path=str(p.relative_to(w)),sha256=sha(p)) for p in source_paths]
write(out/'source-before.json',source)
model=out/'AppModelInspected.swift';model.write_bytes((w/'Sources/App/AppModel.swift').read_bytes()+b'\nextension AppModel { var gateStoreURL:URL { store } }\n')
app=out/'SimultaneousTimerExpiry.app';binary=app/'Contents/MacOS/SimultaneousTimerExpiry';binary.parent.mkdir(parents=True);(app/'Contents/Resources').mkdir()
(app/'Contents/Info.plist').write_bytes(plistlib.dumps(dict(CFBundleExecutable=binary.name,CFBundleIdentifier='org.example.homeview-timer-batch-gate',CFBundlePackageType='APPL')))
files=[model if p.name=='AppModel.swift' else p for p in sorted(w.glob('Sources/**/*.swift')) if p.name!='HomeViewApp.swift' and 'Widgets' not in p.parts]
probe=w/'Tests/NativeProbes/SimultaneousTimerExpiry.swift';inputs=files+[probe,products/'FeedKit.o',products/'XMLKit.o',Path(__file__).resolve()]
rows=[dict(file=str(p),sha256=sha(p)) for p in inputs];write(out/'inputs-before.json',rows)
cmd=['xcrun','swiftc','-parse-as-library','-swift-version','6','-D','DEBUG','-target','arm64-apple-macos15.0','-I',str(products)]+list(map(str,files+[probe,products/'FeedKit.o',products/'XMLKit.o']))+['-o',str(binary)]
write(out/'compile-command.json',cmd)
with (out/'compile.log').open('w') as log:r=subprocess.run(cmd,cwd=w,stdout=log,stderr=subprocess.STDOUT,timeout=300)
write(out/'compile-result.json',dict(exit_code=r.returncode));assert r.returncode==0
execution=[dict(file=str(p),sha256=sha(p)) for p in sorted(app.rglob('*')) if p.is_file()];write(out/'execution-before.json',execution)
results=[]
for case in ['simultaneous','staggered','write_failure']:
 owned=str(uuid.uuid4()).upper()
 for phase in ['seed','reconcile','verify']:
  cmd=[str(binary),'--uitesting','--persistence-test',owned,'--case',case,'--phase',phase]
  write(out/(case+'-'+phase+'-command.json'),cmd)
  r=subprocess.run(cmd,capture_output=True,text=True,timeout=30)
  (out/(case+'-'+phase+'.stdout')).write_text(r.stdout);(out/(case+'-'+phase+'.stderr')).write_text(r.stderr)
  assert r.returncode==0,(case,phase,r.returncode)
  result=json.loads(r.stdout.strip().splitlines()[-1]);results.append(result);write(out/'results.json',results)
  print(case,phase,result['verdict'],result['failed'],flush=True)
  assert result['verdict']=='PASS'
  if phase=='seed':time.sleep(2)
for r in rows+execution:assert sha(Path(r['file']))==r['sha256']
for r in source:assert sha(w/r['path'])==r['sha256']
write(out/'inputs-after.json',rows);write(out/'execution-after.json',execution);write(out/'source-after.json',source)
write(out/'verdict.json',dict(verdict='PASS',processes=len(results),assertions=sum(r['assertions'] for r in results),failed=0,product_methods_replaced=False,app_model_accessor_only=True,binary_sha256=sha(binary)))
