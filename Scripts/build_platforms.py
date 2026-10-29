#!/usr/bin/env python3
"""Build installed SDKs and verify iOS Shortcut artifacts; never sign/distribute."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess

CONFIGS = [
    ('iOS', 'HomeViewReplica', 'iphonesimulator', 'generic/platform=iOS Simulator', '1,2'),
    ('macOS', 'HomeViewReplica', 'macosx', 'platform=macOS', ''),
    ('tvOS', 'HomeViewReplica', 'appletvsimulator', 'generic/platform=tvOS Simulator', '3'),
    ('visionOS', 'HomeViewReplica', 'xrsimulator', 'generic/platform=visionOS Simulator', '7'),
    ('watchOS', 'HomeViewWatch', 'watchsimulator', 'generic/platform=watchOS Simulator', '4'),
]


def ios_shortcut_artifacts(build):
    """Check this app's generated metadata, not OS discovery or invocation."""
    base = build / 'Build/Products/Debug-iphonesimulator/HomeViewReplica.app/Metadata.appintents'
    required = ['extract.actionsdata', 'version.json', 'root.ssu.yaml', 'nlu/nlu.lzfse']
    versions = sorted(base.glob('nlu/*.version'))
    errors = [name + ': missing or empty' for name in required
              if not (base / name).is_file() or (base / name).stat().st_size == 0]
    if not versions or not any(p.is_file() and p.stat().st_size > 0 for p in versions):
        errors.append('nlu/*.version: missing or empty')
    try:
        actions = json.loads((base / 'extract.actionsdata').read_text())
        if 'OpenHomeViewAssistantIntent' not in actions.get('actions', {}):
            errors.append('extract.actionsdata: assistant intent absent')
    except (OSError, ValueError, TypeError, AttributeError):
        errors.append('extract.actionsdata: unreadable metadata')
    try:
        if not json.loads((base / 'version.json').read_text()).get('version'):
            errors.append('version.json: metadata version absent')
    except (OSError, ValueError, TypeError, AttributeError):
        errors.append('version.json: unreadable metadata')
    try:
        root = (base / 'root.ssu.yaml').read_text()
        if 'OpenHomeViewAssistantIntent' not in root or 'org.example.HomeViewReplica' not in root:
            errors.append('root.ssu.yaml: app/assistant training entry absent')
    except (OSError, ValueError):
        errors.append('root.ssu.yaml: unreadable metadata')
    files = [{'path': str(p.relative_to(base)), 'bytes': p.stat().st_size,
              'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
             for p in sorted(base.rglob('*')) if p.is_file()]
    return {'valid': not errors, 'errors': errors, 'files': files}


def build_platform(root, build, config):
    label, scheme, sdk, destination, family = config
    cmd = ['xcodebuild', '-project', str(root / 'HomeViewReplica.xcodeproj'),
           '-scheme', scheme, '-sdk', sdk, '-destination', destination,
           '-derivedDataPath', str(build), 'CODE_SIGNING_ALLOWED=NO',
           'TARGETED_DEVICE_FAMILY=' + family, 'ONLY_ACTIVE_ARCH=YES', 'ARCHS=arm64']
    attempts = []
    # An identical incremental rebuild did not repair the observed missing SSU
    # outputs. Use one standard clean/build only after a successful incomplete iOS
    # build; never retry compiler errors or disable AppIntents extraction/training.
    for recovery in (False, True):
        log = build / (label.lower() + ('-metadata-recovery-build.log' if recovery else '-final-build.log'))
        command = cmd + (['clean', 'build'] if recovery else ['build'])
        start = datetime.datetime.now(datetime.timezone.utc).isoformat()
        with log.open('w') as output:
            result = subprocess.run(command, cwd=root, stdout=output, stderr=subprocess.STDOUT)
        attempt = {'exit_code': result.returncode, 'started': start,
                   'ended': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   'log': str(log), 'command': command, 'clean_metadata_recovery': recovery}
        if label == 'iOS' and result.returncode == 0:
            attempt['shortcut_artifacts'] = ios_shortcut_artifacts(build)
        attempts.append(attempt)
        if (result.returncode != 0 or label != 'iOS'
                or attempt['shortcut_artifacts']['valid'] or recovery):
            break
    last = attempts[-1]
    complete = last['exit_code'] == 0 and (label != 'iOS' or last['shortcut_artifacts']['valid'])
    return {'platform': label, 'sdk': sdk, 'exit_code': last['exit_code'] if last['exit_code'] else (0 if complete else 1),
            'started': attempts[0]['started'], 'ended': last['ended'],
            'log': last['log'], 'command': last['command'], 'attempts': attempts,
            'ios_shortcut_artifacts_valid': last.get('shortcut_artifacts', {}).get('valid')}


def main():
    root = Path(__file__).resolve().parents[1]
    build = Path(os.environ.get('HOMEVIEW_BUILD_DIR', str(Path.home() / 'Library/Developer/HomeViewPublicBuild')))
    build.mkdir(parents=True, exist_ok=True)
    (root / 'Evidence').mkdir(exist_ok=True)
    rows = []
    for config in CONFIGS:
        row = build_platform(root, build, config)
        rows.append(row)
        (root / 'Evidence/builds.json').write_text(json.dumps(rows, indent=2))
        suffix = ' (one metadata clean/build recovery)' if len(row['attempts']) == 2 else ''
        print(row['platform'], 'PASS' if row['exit_code'] == 0 else 'FAIL', suffix, flush=True)
    return 0 if all(row['exit_code'] == 0 for row in rows) else 1


if __name__ == '__main__':
    raise SystemExit(main())
