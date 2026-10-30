#!/usr/bin/env python3
"""Build installed SDKs and verify iOS Shortcut artifacts; never sign/distribute."""
import datetime
from decimal import Decimal, InvalidOperation
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import uuid

CONFIGS = [
    ('iOS', 'HomeViewReplica', 'iphonesimulator', 'generic/platform=iOS Simulator', '1,2'),
    ('macOS', 'HomeViewReplica', 'macosx', 'platform=macOS', ''),
    ('tvOS', 'HomeViewReplica', 'appletvsimulator', 'generic/platform=tvOS Simulator', '3'),
    ('visionOS', 'HomeViewReplica', 'xrsimulator', 'generic/platform=visionOS Simulator', '7'),
    ('watchOS', 'HomeViewWatch', 'watchsimulator', 'generic/platform=watchOS Simulator', '4'),
]

DEFAULT_MIN_FREE_BYTES = 16 * 1024 ** 3


def configured_min_free_bytes():
    """An explicit positive reserve; a typo must not silently disable it."""
    try:
        gib = Decimal(os.environ.get('HOMEVIEW_MIN_FREE_GIB', '16'))
    except InvalidOperation as exc:
        raise ValueError('HOMEVIEW_MIN_FREE_GIB must be finite and positive') from exc
    if not gib.is_finite() or gib <= 0 or gib * 1024 ** 3 < 1:
        raise ValueError('HOMEVIEW_MIN_FREE_GIB must be finite and positive')
    return int(gib * 1024 ** 3)


def storage_preflight(build, minimum=DEFAULT_MIN_FREE_BYTES):
    """Read the destination filesystem, including before DerivedData exists.

    This is a headroom check, not a reservation, quota or retention policy.
    Resolving the target first avoids measuring the wrong volume for symlinks.
    """
    result = {'minimum_free_bytes': minimum, 'checked_at':
              datetime.datetime.now(datetime.timezone.utc).isoformat()}
    try:
        target = build.resolve()
        # macOS mount names must not become ordinary folders on the boot disk
        # when an explicitly selected external volume is disconnected.
        if len(target.parts) >= 3 and target.parts[1] == 'Volumes':
            volume = Path(*target.parts[:3])
            if not volume.is_mount():
                result.update(destination=str(target), sufficient=False, error='VolumeNotMounted')
                return result
        existing = target
        while not existing.exists():
            existing = existing.parent
        if not existing.is_dir():
            raise NotADirectoryError(str(existing))
        capacity = shutil.disk_usage(existing)
        result.update(destination=str(target), checked_directory=str(existing),
                      device=existing.stat().st_dev, free_bytes=capacity.free,
                      total_bytes=capacity.total, sufficient=capacity.free >= minimum)
    except (OSError, RuntimeError) as exc:
        result.update(sufficient=False, error=type(exc).__name__)
    return result


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


def build_platform(root, build, config, minimum_free_bytes=DEFAULT_MIN_FREE_BYTES):
    label, scheme, sdk, destination, family = config
    cmd = ['xcodebuild', '-project', str(root / 'HomeViewReplica.xcodeproj'),
           '-scheme', scheme, '-sdk', sdk, '-destination', destination,
           '-derivedDataPath', str(build), 'CODE_SIGNING_ALLOWED=NO',
           'TARGETED_DEVICE_FAMILY=' + family, 'ONLY_ACTIVE_ARCH=YES', 'ARCHS=arm64']
    attempts = []
    receipt_dir = build / 'HomeViewBuildReceipts' / uuid.uuid4().hex
    # An identical incremental rebuild did not repair the observed missing SSU
    # outputs. Use one standard clean/build only after a successful incomplete iOS
    # build; never retry compiler errors or disable AppIntents extraction/training.
    for recovery in (False, True):
        log = receipt_dir / (label.lower() + ('-metadata-recovery-build.log' if recovery else '-final-build.log'))
        command = cmd + (['clean', 'build'] if recovery else ['build'])
        start = datetime.datetime.now(datetime.timezone.utc).isoformat()
        storage_before = storage_preflight(build, minimum_free_bytes)
        if not storage_before['sufficient']:
            attempts.append({'exit_code': 75, 'started': start, 'ended': start,
                             'log': None, 'command': command, 'executed': False,
                             'clean_metadata_recovery': recovery,
                             'failure_code': 'BUILD_STORAGE_UNAVAILABLE' if 'error' in storage_before
                             else 'BUILD_STORAGE_LOW', 'storage_before': storage_before})
            break
        build.mkdir(parents=True, exist_ok=True)
        if not recovery:
            receipt_dir.mkdir(parents=True, exist_ok=False)
        with log.open('w') as output:
            result = subprocess.run(command, cwd=root, stdout=output, stderr=subprocess.STDOUT)
        attempt = {'exit_code': result.returncode, 'started': start,
                   'ended': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   'log': str(log), 'command': command, 'clean_metadata_recovery': recovery,
                   'executed': True, 'storage_before': storage_before,
                   'storage_after': storage_preflight(build, minimum_free_bytes)}
        if label == 'iOS' and result.returncode == 0:
            attempt['shortcut_artifacts'] = ios_shortcut_artifacts(build)
        attempts.append(attempt)
        if (result.returncode != 0 or label != 'iOS'
                or attempt['shortcut_artifacts']['valid'] or recovery):
            break
    last = attempts[-1]
    complete = last['exit_code'] == 0 and (label != 'iOS' or last.get('shortcut_artifacts', {}).get('valid'))
    return {'platform': label, 'sdk': sdk, 'exit_code': last['exit_code'] if last['exit_code'] else (0 if complete else 1),
            'started': attempts[0]['started'], 'ended': last['ended'],
            'log': last['log'], 'command': last['command'], 'attempts': attempts,
            'ios_shortcut_artifacts_valid': last.get('shortcut_artifacts', {}).get('valid'),
            'storage_headroom_ok': last.get('storage_after', last['storage_before'])['sufficient'],
            'failure_code': last.get('failure_code')}


def main():
    root = Path(__file__).resolve().parents[1]
    build = Path(os.environ.get('HOMEVIEW_BUILD_DIR', str(Path.home() / 'Library/Developer/HomeViewPublicBuild')))
    try:
        minimum = configured_min_free_bytes()
    except ValueError as exc:
        print(str(exc), flush=True)
        return 64
    (root / 'Evidence').mkdir(exist_ok=True)
    rows = []
    for config in CONFIGS:
        row = build_platform(root, build, config, minimum)
        rows.append(row)
        (root / 'Evidence/builds.json').write_text(json.dumps(rows, indent=2))
        suffix = ' (one metadata clean/build recovery)' if any(
            a['clean_metadata_recovery'] and a['executed'] for a in row['attempts']) else ''
        print(row['platform'], 'PASS' if row['exit_code'] == 0 else 'FAIL', suffix, flush=True)
        if not row['storage_headroom_ok']:
            print('Builds stopped: destination storage headroom unavailable; nothing deleted.', flush=True)
            break
    return 0 if len(rows) == len(CONFIGS) and all(
        row['exit_code'] == 0 and row['storage_headroom_ok'] for row in rows) else 1


if __name__ == '__main__':
    raise SystemExit(main())
