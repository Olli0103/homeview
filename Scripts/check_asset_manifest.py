"""Validate the current declared resource inventory, not historical rights."""
from pathlib import Path
import hashlib,json

root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'Docs/asset-current-manifest.json').read_text())
assert manifest['schema_version']==1
rows=manifest['assets'];names=[r['path'] for r in rows]
assert len(names)==len(set(names)),"Duplicate resource path"
actual={str(p.relative_to(root)) for p in (root/'Resources').rglob('*') if p.is_file()}
assert set(names)==actual,("Resource inventory mismatch",sorted(actual-set(names)),sorted(set(names)-actual))
for row in rows:
 path=Path(row['path'])
 assert not path.is_absolute() and '..' not in path.parts and path.parts[0]=='Resources'
 p=root/path
 assert not p.is_symlink() and p.resolve().is_relative_to((root/'Resources').resolve())
 assert hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],("Changed resource bytes",row['path'])
 for key in ['author_or_generator','license','license_notice','origin']:
  assert isinstance(row[key],str) and row[key].strip(),("Missing provenance field",row['path'],key)
for row in manifest['source_inputs']:
 path=Path(row['path']);assert not path.is_absolute() and '..' not in path.parts
 assert hashlib.sha256((root/path).read_bytes()).hexdigest()==row['sha256'],("Changed provenance source",row['path'])
for p in (root/'Resources/Assets.xcassets').rglob('Contents.json'):
 for row in json.loads(p.read_text()).get('images',[]):
  if 'filename' in row:
   name=Path(row['filename']);assert len(name.parts)==1 and not name.is_absolute()
   assert (p.parent/name).is_file(),("Missing referenced image",str(p),str(name))
icon=json.loads((root/'Resources/Assets.xcassets/AppIcon.appiconset/Contents.json').read_text())
assert {r['filename'] for r in icon['images']}=={'icon-independent-v2.png'}
generator=(root/'Scripts/make_icon.swift').read_text()
assert all(token not in generator for token in ['systemSymbolName:','NSImage(','NSFont','CTFont','CGFont'])
print(f"{len(rows)} current resources and {len(manifest['source_inputs'])} provenance inputs validated; no historical rights verdict")
