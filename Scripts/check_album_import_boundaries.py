#!/usr/bin/env python3
"""Run actual AppModel album imports with a controlled synthetic provider on macOS.

The only AppModel substitutions select the provider and expose its owned test store.
No platform guards are changed and no real PhotoKit provider is constructed.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import subprocess
import uuid

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--products', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--legacy-app-model', type=Path)
a = p.parse_args()
root = Path(__file__).resolve().parents[1]
out = a.output.resolve()
products = a.products.resolve()
assert a.output.is_absolute() and not out.exists() and not out.is_relative_to(root)
assert out.parts[:3] == ('/', 'Volumes', 'Extern') and Path('/Volumes/Extern').is_mount()
assert all((products / n).is_file() for n in ['FeedKit.o', 'XMLKit.o'])
out.mkdir(parents=True, exist_ok=False)
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
write = lambda p, v: p.write_text(json.dumps(v, indent=2) + '\n')
paths = sorted(p for folder in ['Sources', 'Tests', 'Resources', 'Scripts', 'HomeViewReplica.xcodeproj']
               for p in (root / folder).rglob('*')
               if p.is_file() and not {'xcuserdata', '__pycache__'}.intersection(p.parts))
paths += [root / 'Package.swift', root / 'Package.resolved']
inputs = [dict(path=str(p.relative_to(root)), sha256=sha(p)) for p in paths]
write(out / 'source-before.json', inputs)
original = a.legacy_app_model.resolve() if a.legacy_app_model else root / 'Sources/App/AppModel.swift'
text = original.read_text()
needle = 'let albumProvider = makeAlbumPhotoProvider()'
assert text.count(needle) == 1
text = text.replace(needle, 'let albumProvider = AlbumImportProbeProvider.shared')
text += '\nextension AppModel { var albumProbeStoreURL: URL { store }; var albumProbeGallery: [Data] { gallery } }\n'
model = out / 'AppModelProviderSelected.swift'
model.write_text(text)
probe = root / 'Tests/NativeProbes/AlbumImportBoundaryProbe.swift'
binary = out / 'AlbumImportProbe.app/Contents/MacOS/AlbumImportProbe'
binary.parent.mkdir(parents=True)
(binary.parents[1] / 'Info.plist').write_bytes(plistlib.dumps(dict(
    CFBundleExecutable=binary.name, CFBundleIdentifier='org.example.homeview-album-import-probe', CFBundlePackageType='APPL')))
files = [model if p.name == 'AppModel.swift' else p for p in sorted(root.glob('Sources/**/*.swift'))
         if p.name != 'HomeViewApp.swift' and 'Widgets' not in p.parts]
files += [probe, products / 'FeedKit.o', products / 'XMLKit.o']
compiled = [dict(path=str(p), sha256=sha(p)) for p in sorted(set(files + [original]))]
write(out / 'compile-inputs-before.json', compiled)
cmd = ['xcrun', 'swiftc', '-parse-as-library', '-swift-version', '6', '-D', 'DEBUG', '-whole-module-optimization',
       '-target', 'arm64-apple-macos15.0', '-I', str(products)] + list(map(str, files)) + ['-o', str(binary)]
write(out / 'compile-command.json', cmd)
(out / 'compiler-tmp').mkdir()
with (out / 'compile.log').open('w') as log:
    r = subprocess.run(cmd, cwd=root, stdout=log, stderr=subprocess.STDOUT, timeout=300,
                       env=os.environ | {'TMPDIR': str(out / 'compiler-tmp')})
write(out / 'compile-result.json', dict(exit_code=r.returncode, real_photo_library=False))
assert r.returncode == 0, out / 'compile.log'
binary_sha = sha(binary)
results = []
for case in ['positive', 'disconnect', 'disconnect_error', 'manual_selection', 'newer_import', 'revoked_success', 'revoked_error']:
    cmd = [str(binary), '--uitesting', '--persistence-test', str(uuid.uuid4()).upper(), '--case', case]
    r = subprocess.run(cmd, cwd=root, capture_output=True, text=True, timeout=15)
    (out / (case + '.stdout')).write_text(r.stdout)
    (out / (case + '.stderr')).write_text(r.stderr)
    assert r.returncode == 0, (case, r.stderr[-1000:])
    result = json.loads(r.stdout.strip().splitlines()[-1])
    results.append(result)
    write(out / 'results.json', results)
    print(case, result['verdict'], result['failed'], flush=True)
assert sha(binary) == binary_sha
assert all(sha(Path(r['path'])) == r['sha256'] for r in compiled)
assert all(sha(root / r['path']) == r['sha256'] for r in inputs)
write(out / 'source-after.json', inputs)
write(out / 'summary.json', dict(processes=len(results), passed=sum(r['verdict'] == 'PASS' for r in results),
      failed=sum(r['verdict'] == 'FAIL' for r in results), binary_sha256=binary_sha,
      source_manifest_sha256=sha(out / 'source-before.json'), real_photo_library=False))
