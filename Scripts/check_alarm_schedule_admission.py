#!/usr/bin/env python3
"""Actual AppModel schedule branch, symbolic provider; never links AlarmKit.

Only its platform conditional and a private-store accessor differ. The service
double uses the matching adapter API and the production admission gate when
present. This is not OS authorization, delivery or acoustic evidence.
"""
from pathlib import Path
import argparse, hashlib, json, os, plistlib, subprocess, uuid

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--products', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--legacy-app-model', type=Path, help='Frozen original AppModel for explicit baseline only')
a = p.parse_args()
root = Path(__file__).resolve().parents[1]
out = a.output.resolve()
assert a.output.is_absolute() and not out.exists() and not out.is_relative_to(root)
products = a.products.resolve()
assert all((products / n).is_file() for n in ['FeedKit.o', 'XMLKit.o'])
assert out.parts[:3] == ('/', 'Volumes', 'Extern') and Path('/Volumes/Extern').is_mount()
out.mkdir(parents=True, exist_ok=False)
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
write = lambda path, value: path.write_text(json.dumps(value, indent=2)+'\n')
paths = sorted(path for folder in ['Sources', 'Tests', 'Resources', 'Scripts', 'HomeViewReplica.xcodeproj']
               for path in (root/folder).rglob('*')
               if path.is_file() and not {'xcuserdata', '__pycache__'}.intersection(path.parts))
paths += [root/'Package.swift', root/'Package.resolved']
inputs = [dict(path=str(path.relative_to(root)), sha256=sha(path)) for path in paths]
write(out/'source-before.json', inputs)
model_source = a.legacy_app_model.resolve() if a.legacy_app_model else root/'Sources/App/AppModel.swift'
text = model_source.read_text()
guard = '#if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)'
count = text.count(guard)
assert count >= 10
text = text.replace(guard, '#if true')
text += '\nextension AppModel { var admissionStoreURL:URL { store } }\n'
model = out/'AppModelBranchSelected.swift'
model.write_text(text)
new = not a.legacy_app_model and (root/'Sources/Core/AlarmScheduleAdmission.swift').exists()
methods = '''
  func scheduleTimer(id:UUID,seconds:TimeInterval,title:String) async throws {
    try await authorize();await create(id)
  }
  func scheduleAlarm(id:UUID,hour:Int,minute:Int,recurrence:AlarmRecurrence) async throws {
    try await authorize();await create(id)
  }
'''
if new:
    methods = '''
  func scheduleTimer(id:UUID,deadline:Date,title:String,isCurrent:@escaping @MainActor ()->Bool) async throws -> Bool {
    try await AlarmScheduleAdmission.perform(deadline:deadline,isCurrent:isCurrent,
      authorize:{try await self.authorize()},schedule:{_ in await self.create(id)})
  }
  func scheduleAlarm(id:UUID,hour:Int,minute:Int,recurrence:AlarmRecurrence,isCurrent:@escaping @MainActor ()->Bool) async throws -> Bool {
    try await AlarmScheduleAdmission.perform(isCurrent:isCurrent,
      authorize:{try await self.authorize()},schedule:{_ in await self.create(id)})
  }
'''
probe = out/'AlarmScheduleAdmissionProbe.swift'
probe.write_text((root/'Tests/NativeProbes/AlarmScheduleAdmissionProbe.swift').read_text().replace(
    '// SCHEDULING_METHODS: the runner supplies the matching old/new adapter API.', methods))
binary = out/'AlarmScheduleAdmissionProbe.app/Contents/MacOS/AlarmScheduleAdmissionProbe'
binary.parent.mkdir(parents=True)
(binary.parents[1]/'Info.plist').write_bytes(plistlib.dumps(dict(
    CFBundleExecutable=binary.name, CFBundleIdentifier='org.example.homeview-alarm-admission', CFBundlePackageType='APPL')))
files = [model if path.name == 'AppModel.swift' else path for path in sorted(root.glob('Sources/**/*.swift'))
         if path.name != 'HomeViewApp.swift' and 'Widgets' not in path.parts]
cmd = ['xcrun', 'swiftc', '-parse-as-library', '-swift-version', '6', '-D', 'DEBUG', '-whole-module-optimization',
       '-target', 'arm64-apple-macos15.0', '-I', str(products)]
cmd += list(map(str, files+[probe, products/'FeedKit.o', products/'XMLKit.o']))+['-o', str(binary)]
write(out/'compile-command.json', cmd)
compile_paths = files+[probe, products/'FeedKit.o', products/'XMLKit.o', model_source]
compile_inputs = [dict(path=str(path),sha256=sha(path)) for path in sorted(set(compile_paths))]
write(out/'compile-inputs-before.json',compile_inputs)
(out/'compiler-tmp').mkdir()
with (out/'compile.log').open('w') as log:
    r = subprocess.run(cmd, cwd=root, stdout=log, stderr=subprocess.STDOUT, timeout=300, env=os.environ | {'TMPDIR':str(out/'compiler-tmp')})
write(out/'compile-result.json', dict(exit_code=r.returncode, conditional_replacements=count,
                                     production_admission_gate=new, actual_os_operations=False))
assert r.returncode == 0, out/'compile.log'
binary_before = sha(binary)
results = []
for case in ['timer_expired', 'timer_pause', 'timer_delete', 'alarm_disable', 'alarm_delete',
             'alarm_replace', 'timer_positive', 'alarm_positive', 'timer_after_effect', 'alarm_after_effect']:
    cmd = [str(binary), '--uitesting', '--system-alarms', '--persistence-test', str(uuid.uuid4()).upper(), '--case', case]
    r = subprocess.run(cmd, cwd=root, capture_output=True, text=True, timeout=15)
    (out/(case+'.stdout')).write_text(r.stdout)
    (out/(case+'.stderr')).write_text(r.stderr)
    assert r.returncode == 0, (case, r.stderr)
    result = json.loads(r.stdout.strip().splitlines()[-1])
    results.append(result)
    write(out/'results.json', results)
    print(case, result['verdict'], result['failed'], flush=True)
assert sha(binary) == binary_before
assert all(sha(Path(row['path'])) == row['sha256'] for row in compile_inputs)
write(out/'compile-inputs-after.json',compile_inputs)
assert all(sha(root/row['path']) == row['sha256'] for row in inputs)
write(out/'source-after.json', inputs)
write(out/'summary.json', dict(processes=len(results), passed=sum(r['verdict']=='PASS' for r in results),
      failed=sum(r['verdict']=='FAIL' for r in results), binary_sha256=binary_before,
      source_manifest_sha256=sha(out/'source-before.json'), actual_os_operations=False,
      legacy_app_model_sha256=sha(model_source) if a.legacy_app_model else None))
