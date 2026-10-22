"""Verify static-mesh XML fields and exercise the real portable row serializer.

This never imports an asset, starts Studio or edits the canonical package. It proves
the fields survive XML emission, not that an engine version renders them correctly.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import importlib.util
import json
import math
import re
import xml.etree.ElementTree as ET


def vector(node, name):
    value = node.find(f'Properties/Vector3[@name="{name}"]')
    assert value is not None, f'Missing Vector3 {name}'
    return [float(value.findtext(axis)) for axis in ('X', 'Y', 'Z')]


def content(node, name):
    value = node.find(f'Properties/Content[@name="{name}"]')
    assert value is not None, f'Missing Content {name}'
    return value.findtext('url') or ''


def verify_static_mesh_xml(rows, root, prefix='MAP_'):
    """Check the new mesh fields in a serialized portable tree against scene rows."""
    nodes = {node.get('referent'): node for node in root.iter('Item')}
    count = 0
    for row in rows:
        if row['Class'] != 'MeshPart':
            continue
        count += 1
        props = row['Properties']
        mesh = props['MeshId']['Value']
        assert re.fullmatch(r'rbxassetid://[1-9]\d*', mesh), 'Nonpermanent mesh reference'
        assert not row.get('Attributes', {}).get('SessionArtPlaceholder', {}).get('Value'), 'Static mesh marked as a placeholder'
        assert props['Anchored']['Value'] is True, 'Unanchored static mesh'
        assert props['CanCollide']['Value'] is False and props['CanTouch']['Value'] is False, 'Physical mesh unsupported by this exporter'
        assert props['InitialSize']['Type'] == 'Vector3', 'Missing original mesh extent'
        initial = props['InitialSize']['Value']
        assert len(initial) == 3 and all(math.isfinite(v) and v > 0 for v in initial), 'Invalid original mesh extent'
        node = nodes[prefix + row['Id']]
        assert node.get('class') == 'MeshPart', 'Static mesh was collapsed to a primitive'
        assert content(node, 'MeshId') == mesh, 'Mesh ID changed in XML'
        assert content(node, 'TextureID') == props['TextureID']['Value'], 'Texture ID changed in XML'
        for name in ('InitialSize', 'Size'):
            actual = vector(node, name)
            expected = props[name]['Value']
            assert len(expected) == 3 and all(math.isclose(a, b, rel_tol=1e-8, abs_tol=1e-6) for a, b in zip(actual, expected)), f'{name} changed in XML'
        cf = node.find('Properties/CoordinateFrame[@name="CFrame"]')
        assert cf is not None, 'Missing CFrame'
        axes = ('X', 'Y', 'Z', 'R00', 'R01', 'R02', 'R10', 'R11', 'R12', 'R20', 'R21', 'R22')
        assert all(math.isclose(float(cf.findtext(k)), v, rel_tol=1e-8, abs_tol=1e-6) for k, v in zip(axes, props['CFrame']['Value'])), 'CFrame changed in XML'
        assert node.findtext('Properties/bool[@name="DoubleSided"]') == str(props['DoubleSided']['Value']).lower(), 'DoubleSided changed'
        for name in ('CollisionFidelity', 'RenderFidelity'):
            assert int(node.findtext(f'Properties/token[@name="{name}"]')) == props[name]['Value'], f'{name} changed'
    return {'staticMeshPartsVerified': count, 'initialMeshExtentsVerified': count}


def fixture():
    p = {
        'Name': {'Type': 'string', 'Value': 'StaticFrame'},
        'MeshId': {'Type': 'string', 'Value': 'rbxassetid://123456789'},
        'TextureID': {'Type': 'string', 'Value': ''},
        'InitialSize': {'Type': 'Vector3', 'Value': [1200., 300., 40.]},
        'Size': {'Type': 'Vector3', 'Value': [12., 3., .4]},
        'CFrame': {'Type': 'CFrame', 'Value': [7., 2., -80., -1., 0., 0., 0., 1., 0., 0., 0., -1.]},
        'DoubleSided': {'Type': 'boolean', 'Value': True},
        'Anchored': {'Type': 'boolean', 'Value': True},
        'CanCollide': {'Type': 'boolean', 'Value': False},
        'CanTouch': {'Type': 'boolean', 'Value': False},
        'CollisionFidelity': {'Type': 'token', 'Value': 0},
        'RenderFidelity': {'Type': 'token', 'Value': 1},
    }
    return [{'Id': 'MESH_1', 'Class': 'MeshPart', 'Parent': None, 'Properties': p, 'Attributes': {}}]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project-root', type=Path, required=True, help='Folder containing package_project.py')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    source = args.project_root / 'package_project.py'
    original_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    spec = importlib.util.spec_from_file_location('package_under_mesh_test', source)
    package = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(package)
    rows = fixture()
    root = ET.Element('roblox')
    package.emit_rows(rows, root, prefix='MAP_')
    root = ET.fromstring(ET.tostring(root, encoding='utf-8'))
    result = verify_static_mesh_xml(rows, root)
    refused = []
    for mutation in ('MissingInitialSize', 'WrongInitialSize', 'WrongMeshId', 'WrongSize', 'WrongClass', 'WrongDoubleSided', 'WrongCollisionFidelity'):
        changed = copy.deepcopy(root)
        item = next(changed.iter('Item'))
        props = item.find('Properties')
        if mutation == 'MissingInitialSize':
            props.remove(props.find('Vector3[@name="InitialSize"]'))
        elif mutation == 'WrongInitialSize':
            props.find('Vector3[@name="InitialSize"]/X').text = '12'
        elif mutation == 'WrongMeshId':
            props.find('Content[@name="MeshId"]/url').text = 'rbxassetid://987654321'
        elif mutation == 'WrongSize':
            props.find('Vector3[@name="Size"]/Y').text = '300'
        elif mutation == 'WrongClass':
            item.set('class', 'Part')
        elif mutation == 'WrongDoubleSided':
            props.find('bool[@name="DoubleSided"]').text = 'false'
        else:
            props.find('token[@name="CollisionFidelity"]').text = '4'
        try:
            verify_static_mesh_xml(rows, changed)
        except (AssertionError, KeyError):
            refused.append(mutation)
        else:
            raise AssertionError('Mutation accepted: ' + mutation)
    assert hashlib.sha256(source.read_bytes()).hexdigest() == original_hash, 'Canonical package script changed'
    result.update({'Passed': True, 'SyntheticMeshes': 1, 'RefusedMutations': refused,
                   'Serializer': str(source), 'CanonicalSerializerUnchanged': True,
                   'Limitations': ['No Roblox load, rendering, asset-permission, replication or collision-geometry validation.',
                                   'InitialSize serialization name additionally observed in the project own native CatalogoDecoracao.rbxm.']})
    if args.report:
        args.report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
