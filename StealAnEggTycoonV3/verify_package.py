"""Verify source copies and the authored map in the portable delivery."""
from pathlib import Path
import base64
import hashlib
import json
import math
import xml.etree.ElementTree as E

root = Path(__file__).resolve().parent
out = root / 'Resultados'
manifest = json.loads((out / 'manifesto-fontes.json').read_text(encoding='utf-8'))
for entry in manifest:
    relative = Path(entry['path'].replace('\\', '/'))
    original = root / relative
    delivered = out / 'Fontes' / relative
    assert delivered.exists(), str(delivered)
    assert hashlib.sha256(original.read_bytes()).hexdigest() == entry['sha256'], str(original)
    assert delivered.read_bytes() == original.read_bytes(), f'Source mismatch: {delivered}'
assert (root / 'StealAnEggTycoonV3.rbxlx').read_bytes() == (out / 'StealAnEggTycoonV3.rbxlx').read_bytes()

tree = E.parse(out / 'StealAnEggTycoonV3.rbxlx')
items = list(tree.getroot().iter('Item'))
referents = [i.get('referent') for i in items]
assert len(referents) == len(set(referents)), 'Portable contains duplicate instance referents'
scripts = [i for i in items if i.get('class') in ('Script', 'LocalScript', 'ModuleScript')]


def nm(node):
    return node.findtext('Properties/string[@name="Name"]') or ''


tests = [i for i in scripts if 'Studio' in nm(i) and i.get('class') != 'ModuleScript']
assert all(i.findtext('Properties/bool[@name="Disabled"]') == 'true' for i in tests)
assert any(nm(i) == 'EggTycoonV2_Backup' for i in items)
assert len(list((out / 'Blender').glob('*.fbx'))) == 19
assert (out / 'Blender/EggTycoonV3.blend').stat().st_size > 100000
report = {'sources': len(manifest), 'deliveredSourceCopies': len(list((out / 'Fontes').rglob('*.luau'))),
          'fbx': 19, 'disabledTestScripts': len(tests), 'portableParses': True,
          'allSourceCopiesMatch': True, 'v2BackupIncluded': True}

scene_path = root / 'Map/scene.json'
if scene_path.exists():
    rows = json.loads(scene_path.read_text(encoding='utf-8-sig'))
    rows_by_id = {row['Id']: row for row in rows}
    assert (out / 'Map/scene.json').read_bytes() == scene_path.read_bytes()
    nodes = {i.get('referent'): i for i in items}
    workspace = next(i for i in tree.getroot().findall('Item') if i.get('class') == 'Workspace')
    authored_roots = [r for r in rows if r.get('Parent') is None]
    expected_roots = {'MAP_' + r['Id'] for r in authored_roots}
    actual_roots = {i.get('referent') for i in workspace.findall('Item') if i.get('class') not in ('Camera', 'Terrain')}
    assert actual_roots == expected_roots, 'Workspace contains missing or stale scene roots'
    verified_parts = 0
    roads = 0
    placeholders = 0
    for row in rows:
        ident = 'MAP_' + row['Id']
        assert ident in nodes, f'Missing authored instance: {ident}'
        node = nodes[ident]
        assert node.get('class') == row['Class'], ident
        assert nm(node) == row['Properties']['Name']['Value'], ident
        if row.get('Parent') is not None:
            assert node in list(nodes['MAP_' + row['Parent']]), f'Wrong scene parent: {ident}'
        for key, components in (('Size', ['X', 'Y', 'Z']),
                                ('CFrame', ['X', 'Y', 'Z', 'R00', 'R01', 'R02', 'R10', 'R11', 'R12', 'R20', 'R21', 'R22'])):
            entry = row['Properties'].get(key)
            if entry and entry['Type'] == ('CFrame' if key == 'CFrame' else 'Vector3'):
                tag = 'CoordinateFrame' if key == 'CFrame' else 'Vector3'
                field = node.find(f'Properties/{tag}[@name="{key}"]')
                assert field is not None, f'Missing {key}: {ident}'
                actual = [float(field.findtext(k)) for k in components]
                assert all(math.isclose(a, b, abs_tol=1e-5, rel_tol=1e-7)
                           for a, b in zip(actual, entry['Value'])), f'Authored {key} changed: {ident}'
        primary = row['Properties'].get('PrimaryPart')
        if primary:
            target = 'MAP_' + primary['Value'] if primary['Value'] not in (None, 'null') else 'null'
            assert node.findtext('Properties/Ref[@name="PrimaryPart"]') == target, ident
        if row.get('Tags'):
            encoded = node.findtext('Properties/BinaryString[@name="Tags"]')
            actual_tags = base64.b64decode(encoded).decode('utf-8').rstrip('\0').split('\0')
            assert actual_tags == row['Tags'], ident
        attributes = row.get('Attributes') or {}
        if attributes.get('SessionArtPlaceholder', {}).get('Value'):
            placeholders += 1
            model = rows_by_id[row['Parent']]
            owner = rows_by_id[model['Parent']]
            model_name = model['Properties']['Name']['Value']
            owner_name = owner['Properties']['Name']['Value']
            if model_name == 'Egg':
                container = rows_by_id[owner['Parent']]
                assert container['Properties']['Name']['Value'] == 'Nests', ident
                species = (owner.get('Attributes') or {}).get('Species', {}).get('Value')
            else:
                assert owner_name == 'Guardians', f'Placeholder outside renewable art: {ident}'
                species = (model.get('Attributes') or {}).get('Species', {}).get('Value')
            assert species in range(1, 8), f'Placeholder without a valid species: {ident}'
        if row['Properties'].get('CFrame') and row['Properties'].get('Size'):
            verified_parts += 1
        if nm(node) == 'RingRoad':
            roads += 1
    world = next(i for i in workspace.findall('Item') if nm(i) == 'EggTycoonV3')
    plots = next(i for i in world.findall('Item') if nm(i) == 'Plots')
    nests = next(i for i in world.findall('Item') if nm(i) == 'Nests')
    guards = next(i for i in world.findall('Item') if nm(i) == 'Guardians')
    assert len(plots.findall('Item')) == 8
    assert len(nests.findall('Item')) == 14
    assert len(guards.findall('Item')) == 14
    assert roads == 32, f'Expected 32 authored RingRoad segments, got {roads}'
    assert any(nm(i) == 'walls' for i in workspace.findall('Item')), 'Manual outer walls are missing'
    report.update({'authoredMapIncluded': True, 'authoredSceneInstances': len(rows),
                   'authoredPartsVerified': verified_parts, 'ringRoadSegmentsVerified': roads,
                   'plots': 8, 'nests': 14, 'guardians': 14, 'manualOuterWallsIncluded': True,
                   'renewableSessionArtPlaceholders': placeholders})

(out / 'Testes').mkdir(exist_ok=True)
(out / 'Testes/validacao-pacote.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report))
