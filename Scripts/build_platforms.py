#!/usr/bin/env python3
"""Build against installed SDKs. Does not download runtimes or sign/distribute apps."""
import json, subprocess, datetime, os
from pathlib import Path
root=Path(__file__).resolve().parents[1]
build=Path(os.environ.get('HOMEVIEW_BUILD_DIR', str(Path.home()/'Library/Developer/HomeViewPublicBuild')))
build.mkdir(parents=True, exist_ok=True)
(root/'Evidence').mkdir(exist_ok=True)
configs=[('iOS','HomeViewReplica','iphonesimulator','generic/platform=iOS Simulator','1,2'),('macOS','HomeViewReplica','macosx','platform=macOS',''),('tvOS','HomeViewReplica','appletvsimulator','generic/platform=tvOS Simulator','3'),('visionOS','HomeViewReplica','xrsimulator','generic/platform=visionOS Simulator','7'),('watchOS','HomeViewWatch','watchsimulator','generic/platform=watchOS Simulator','4')]
rows=[]
for label,scheme,sdk,destination,family in configs:
    log=build/(label.lower()+'-final-build.log')
    cmd=['xcodebuild','-project',str(root/'HomeViewReplica.xcodeproj'),'-scheme',scheme,'-sdk',sdk,'-destination',destination,'-derivedDataPath',str(build),'CODE_SIGNING_ALLOWED=NO','TARGETED_DEVICE_FAMILY='+family,'ONLY_ACTIVE_ARCH=YES','ARCHS=arm64','build']
    start=datetime.datetime.now(datetime.timezone.utc).isoformat()
    with log.open('w') as f: p=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT)
    row={'platform':label,'sdk':sdk,'exit_code':p.returncode,'started':start,'ended':datetime.datetime.now(datetime.timezone.utc).isoformat(),'log':str(log),'command':cmd}
    rows.append(row)
    (root/'Evidence/builds.json').write_text(json.dumps(rows,indent=2))
    print(label, 'PASS' if p.returncode==0 else 'FAIL',flush=True)
raise SystemExit(0 if all(x['exit_code']==0 for x in rows) else 1)
