"""Verify source copies, embedded Luau instances and the authored portable map."""
from pathlib import Path
import base64
import hashlib
import json
import math
import xml.etree.ElementTree as E


SCRIPT_CLASSES = ('Script', 'LocalScript', 'ModuleScript')
SOURCE_CONTAINERS = {
    'Shared': (('ReplicatedStorage', 'ReplicatedStorage'),
               ('EggTycoonV3', 'Folder'), ('Shared', 'Folder')),
    'Server': (('ServerScriptService', 'ServerScriptService'),
               ('EggTycoonV3', 'Folder')),
    'Client': (('StarterPlayer', 'StarterPlayer'),
               ('StarterPlayerScripts', 'StarterPlayerScripts')),
}


def nm(node):
    return node.findtext('Properties/string[@name="Name"]') or ''


def source_files(source_root):
    return sorted(path for folder in SOURCE_CONTAINERS
                  for path in (source_root / folder).glob('*.luau'))


def required_child(parent, name, cls, ancestry=''):
    matches = [node for node in parent.findall('Item') if nm(node) == name]
    path = ancestry + '/' + name if ancestry else name
    assert len(matches) == 1, f'Expected one portable instance at {path}, found {len(matches)}'
    node = matches[0]
    assert node.get('class') == cls, f'Wrong portable class at {path}: expected {cls}, got {node.get("class")}'
    return node


def verify_embedded_sources(portable_root, source_root):
    """Check canonical V3 paths against real sources; a V2 copy cannot satisfy them.

    Kept independent of manifests/report writes so a copied portable can be
    mutation-tested without rebuilding or changing the actual delivery.
    """
    source_root = Path(source_root)
    containers = {}
    for folder, steps in SOURCE_CONTAINERS.items():
        parent, ancestry = portable_root, ''
        for name, cls in steps:
            parent = required_child(parent, name, cls, ancestry)
            ancestry = ancestry + '/' + name if ancestry else name
        containers[folder] = (parent, ancestry)

    matched, disabled_tests = set(), 0
    for path in source_files(source_root):
        folder = path.relative_to(source_root).parts[0]
        parent, ancestry = containers[folder]
        suffix = ('.server.luau' if path.name.endswith('.server.luau') else
                  '.client.luau' if path.name.endswith('.client.luau') else '.luau')
        short = path.name.removesuffix(suffix)
        wanted = 'EggTycoonV3_' + short if folder == 'Client' else short
        cls = 'Script' if suffix == '.server.luau' else 'LocalScript' if suffix == '.client.luau' else 'ModuleScript'
        node = required_child(parent, wanted, cls, ancestry)
        fields = node.findall('Properties/ProtectedString[@name="Source"]')
        instance_path = ancestry + '/' + wanted
        assert len(fields) == 1, f'Missing or duplicated portable Source at {instance_path}'
        original = path.read_text(encoding='utf-8-sig')
        assert (fields[0].text or '') == original, f'Embedded source mismatch: {path.relative_to(source_root).as_posix()} at {instance_path}'
        if cls != 'ModuleScript' and short.startswith('Studio'):
            assert node.findtext('Properties/bool[@name="Disabled"]') == 'true', f'Portable test script is enabled: {instance_path}'
            assert node.findtext('Properties/bool[@name="Enabled"]') != 'true', f'Portable test script has Enabled=true: {instance_path}'
            disabled_tests += 1
        matched.add(node)

    storage = required_child(portable_root, 'ServerStorage', 'ServerStorage')
    backup = required_child(storage, 'EggTycoonV2_Backup', 'Folder', 'ServerStorage')
    backup_scripts = {node for node in backup.iter('Item') if node.get('class') in SCRIPT_CLASSES}
    for node in backup_scripts:
        if node.get('class') != 'ModuleScript':
            assert node.findtext('Properties/bool[@name="Disabled"]') == 'true', f'V2 backup executable is enabled: {nm(node)}'
            assert node.findtext('Properties/bool[@name="Enabled"]') != 'true', f'V2 backup executable has Enabled=true: {nm(node)}'
    all_scripts = {node for node in portable_root.iter('Item') if node.get('class') in SCRIPT_CLASSES}
    unexpected = all_scripts - matched - backup_scripts
    assert not unexpected, 'Unexpected Luau instances outside canonical V3 paths/V2 backup: ' + ', '.join(sorted(nm(node) for node in unexpected))
    assert len(matched) == len(source_files(source_root)), 'Not all real sources have unique portable instances'
    return {'embeddedSourceInstancesVerified': len(matched),
            'embeddedSourceHierarchyMatches': True, 'allEmbeddedSourcesMatch': True,
            'disabledTestScripts': disabled_tests, 'v2BackupExecutablesDisabled': True}


def main(project_root=None):
    root = Path(project_root) if project_root is not None else Path(__file__).resolve().parent
    out = root / 'Resultados'
    manifest = json.loads((out / 'manifesto-fontes.json').read_text(encoding='utf-8'))
    manifest_paths = [entry['path'].replace('\\', '/') for entry in manifest]
    actual_paths = {path.relative_to(root).as_posix() for path in source_files(root)}
    assert len(manifest_paths) == len(set(manifest_paths)), 'Manifest contains duplicate sources'
    assert set(manifest_paths) == actual_paths, 'Manifest does not list exactly the real Shared/Server/Client sources'
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
    scripts = [i for i in items if i.get('class') in SCRIPT_CLASSES]
    embedded_report = verify_embedded_sources(tree.getroot(), root)

    tests = [i for i in scripts if 'Studio' in nm(i) and i.get('class') != 'ModuleScript']
    assert all(i.findtext('Properties/bool[@name="Disabled"]') == 'true' for i in tests)
    assert any(nm(i) == 'EggTycoonV2_Backup' for i in items)
    assert len(list((out / 'Blender').glob('*.fbx'))) == 19
    assert (out / 'Blender/EggTycoonV3.blend').stat().st_size > 100000
    report = {'sources': len(manifest), 'deliveredSourceCopies': len(list((out / 'Fontes').rglob('*.luau'))),
              'fbx': 19, 'disabledTestScripts': len(tests), 'portableParses': True,
              'allSourceCopiesMatch': True, 'v2BackupIncluded': True}
    report.update(embedded_report)

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
        expected_roads = sum(row['Properties']['Name']['Value'] == 'RingRoad' for row in rows)
        assert roads == expected_roads, f'Expected {expected_roads} authored RingRoad segments, got {roads}'
        assert any(nm(i) == 'walls' for i in workspace.findall('Item')), 'Manual outer walls are missing'
        report.update({'authoredMapIncluded': True, 'authoredSceneInstances': len(rows),
                       'authoredPartsVerified': verified_parts, 'ringRoadSegmentsVerified': roads,
                       'plots': 8, 'nests': 14, 'guardians': 14, 'manualOuterWallsIncluded': True,
                       'renewableSessionArtPlaceholders': placeholders})

    (out / 'Testes').mkdir(exist_ok=True)
    (out / 'Testes/validacao-pacote.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
