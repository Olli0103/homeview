#!/usr/bin/env python3
"""Check the published reference-to-issue contract, not product parity itself."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
functions = json.loads((root / 'Docs/function-coverage.json').read_text())
packages = json.loads((root / 'Docs/backlog.json').read_text())
keys = {r['key'] for r in packages}
assert len(keys) == len(packages), 'Duplicate backlog key'
assert {r['id'] for r in functions} == {f'F{i:03}' for i in range(1, 106)}
assert len(functions) == 105, 'Duplicate reference function'
for r in functions:
    assert r['backlog_keys'] and set(r['backlog_keys']) <= keys, r['id']
    assert len(r['issue_urls']) == len(r['backlog_keys']), r['id']
    assert r['evidence_assessment']['status'] in ['observed', 'reported', 'unknown'], r['id']
    assert r['evidence_assessment']['reason'], r['id']
    assert r['target'] == 'iPad core', r['id']
    assert r['implementation_status'] in ['partial', 'blocked', 'research'], r['id']
    assert set(r['acceptance']) == {'functional', 'visual', 'device_service'}, r['id']
    assert all(r['acceptance'].values()), r['id']
    assert r['completion_criteria'], r['id']
for r in packages:
    assert r['tasks'] and r['verify'], r['key']
    assert set(r['dependencies']) <= keys, r['key']
print(f'{len(functions)} reference functions and {len(packages)} issue packages validated')
