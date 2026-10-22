"""Validate the public reference inventory, without loading private media."""
import json
from pathlib import Path

root=Path(__file__).resolve().parents[2]
catalogue=json.loads((root/'Docs/reference-states.json').read_text())
sources={r['id']:r for r in catalogue['sources']}
states={r['id']:r for r in catalogue['states']}
assert len(sources)==24 and len(states)==51
assert set(states)=={'UI%02d'%i for i in range(1,52)}
assert len(catalogue['featureMap'])==105
assert {r['id'] for r in catalogue['featureMap']}=={'F%03d'%i for i in range(1,106)}
for row in catalogue['states']:
    assert row['sourceID'] in sources and row['referenceSHA256'] and row['sourceSHA256']
    assert row['verifiedOn']=='2026-10-22' and row['capturedOn']=='2026-10-16'
    assert row['sourcePixels'] and row['referencePixels'] and row['geometryLimit']
    assert row['nativeScreenshot'] is False
    if row['kind'].startswith('sampled_'):
        assert row['mediaSeconds'] is not None and row['sequenceID']
    else:
        assert row['mediaSeconds'] is None
for row in catalogue['featureMap']:
    assert row['sourceIDs'] and set(row['sourceIDs'])<=set(sources)
    assert set(row['referenceStates'])<=set(states)
    assert row['uncertainty'] and row['geometryBasis'] and row['parityAccepted'] is False
assert len(catalogue['faceVisualGroups'])==13
assert catalogue['uniqueOriginalFaceCount'] is None
assert sum(r['verifiedSamples'] for r in catalogue['motionSequences'])==101
assert set(catalogue['optionalReplicaFaces'])=={
    'Watch Modular','Infograph Modular','Modular Duo','Modular Compact'}
print('24 sources / 51 references / 105 feature locators / 13 visual groups verified')
