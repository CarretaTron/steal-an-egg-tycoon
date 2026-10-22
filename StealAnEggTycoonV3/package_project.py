"""Build the portable place from sources, the authored scene and the inert V2 backup."""
from pathlib import Path
import base64
import hashlib
import json
import shutil
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / 'Backups/AntesContinuacao/StealAnEggTycoonV3.rbxlx'
OUT = ROOT / 'Resultados'
SCENE = ROOT / 'Map/scene.json'

COMPONENTS = {
    'Vector3': ['X', 'Y', 'Z'], 'Vector2': ['X', 'Y'],
    'Color3': ['R', 'G', 'B'],
    'CFrame': ['X', 'Y', 'Z', 'R00', 'R01', 'R02', 'R10', 'R11', 'R12', 'R20', 'R21', 'R22'],
    'UDim2': ['XS', 'XO', 'YS', 'YO'], 'UDim': ['S', 'O'],
}
CONTENT_PROPERTIES = {
    'ColorMap', 'NormalMap', 'MetalnessMap', 'RoughnessMap',
    'TextureID', 'TextureId', 'MeshId', 'Texture', 'SoundId', 'AnimationId',
}


def name(node):
    return node.findtext('Properties/string[@name="Name"]')


def prop(node, tag, key, value):
    properties = node.find('Properties')
    if properties is None:
        properties = ET.SubElement(node, 'Properties')
    previous = properties.find(f'*[@name="{key}"]')
    if previous is not None:
        properties.remove(previous)
    field = ET.SubElement(properties, tag, {'name': key})
    field.text = str(value)
    return field


def item(parent, cls, nm, ref):
    node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': ref})
    ET.SubElement(node, 'Properties')
    prop(node, 'string', 'Name', nm)
    return node


def attributes_binary(attributes):
    data = struct.pack('<I', len(attributes))
    for key, entry in attributes.items():
        encoded = key.encode('utf-8')
        data += struct.pack('<I', len(encoded)) + encoded
        typ, value = entry['Type'], entry['Value']
        if typ == 'string':
            encoded = value.encode('utf-8')
            data += bytes([2]) + struct.pack('<I', len(encoded)) + encoded
        elif typ == 'boolean':
            data += bytes([3, 1 if value else 0])
        elif typ == 'number':
            data += bytes([6]) + struct.pack('<d', value)
        else:
            raise ValueError('Unsupported attribute type: ' + typ)
    return base64.b64encode(data).decode('ascii')


def typed_property(node, key, entry, refs):
    if entry is None or key in ('Name', 'WorldPivot'):
        return
    typ, value = entry['Type'], entry['Value']
    if typ in ('Content', 'ContentId') or (typ == 'string' and key in CONTENT_PROPERTIES):
        field = prop(node, 'Content', key, '')
        ET.SubElement(field, 'url' if value else 'null').text = value or None
        return
    if typ in COMPONENTS:
        tag = 'CoordinateFrame' if typ == 'CFrame' else typ
        field = prop(node, tag, key, '')
        keys = COMPONENTS[typ]
        if len(value) != len(keys):
            raise ValueError(f'Invalid component count for {key}: {len(value)}')
        for component, number in zip(keys, value):
            ET.SubElement(field, component).text = str(number)
        return
    tags = {'string': 'ProtectedString' if key == 'Source' else 'string',
            'boolean': 'bool', 'number': 'double', 'token': 'token', 'Ref': 'Ref'}
    if typ not in tags:
        raise ValueError(f'Unsupported property type {typ} for {key}')
    if typ == 'boolean':
        value = str(value).lower()
    elif typ == 'Ref':
        value = refs.get(value, 'null')
    prop(node, tags[typ], key, value)


def emit_rows(rows, parent, prefix=''):
    ids = [row['Id'] for row in rows]
    if len(ids) != len(set(ids)):
        raise ValueError('Duplicate instance IDs in scene/backup')
    refs = {ident: prefix + ident for ident in ids}
    nodes = {}
    # Require parent-first export order rather than silently losing ancestry.
    for row in rows:
        parent_id = row.get('Parent')
        if parent_id is not None and parent_id not in nodes:
            raise ValueError(f'Missing or out-of-order parent: {parent_id}')
        target_parent = nodes[parent_id] if parent_id is not None else parent
        node = item(target_parent, row['Class'], row['Properties']['Name']['Value'], refs[row['Id']])
        nodes[row['Id']] = node
        for key, entry in row['Properties'].items():
            typed_property(node, key, entry, refs)
        attributes = row.get('Attributes') or {}
        if attributes:
            prop(node, 'BinaryString', 'AttributesSerialize', attributes_binary(attributes))
        tags = row.get('Tags') or []
        if tags:
            encoded = ('\0'.join(tags) + '\0').encode('utf-8')
            prop(node, 'BinaryString', 'Tags', base64.b64encode(encoded).decode('ascii'))
    return nodes


def main():
    OUT.mkdir(exist_ok=True)
    tree = ET.parse(SOURCE)
    root = tree.getroot()
    # Services/settings come from the original place; scene instances come from
    # the latest Edit export, including objects outside the generated world.
    scene_rows = None
    if SCENE.exists():
        scene_rows = json.loads(SCENE.read_text(encoding='utf-8-sig'))
        workspace = next(i for i in root.findall('Item') if i.get('class') == 'Workspace')
        staged = ET.Element('Scene')
        emit_rows(scene_rows, staged, prefix='MAP_')
        for old in list(workspace.findall('Item')):
            if old.get('class') not in ('Camera', 'Terrain'):
                workspace.remove(old)
        workspace.extend(staged.findall('Item'))

    server_service = next(i for i in root.findall('Item') if i.get('class') == 'ServerScriptService')
    server_folder = next(i for i in server_service.findall('Item') if i.get('class') == 'Folder')
    prop(server_folder, 'string', 'Name', 'EggTycoonV3')
    starter = next(i for i in root.findall('Item') if i.get('class') == 'StarterPlayer')
    client_folder = next(i for i in starter.findall('Item') if i.get('class') == 'StarterPlayerScripts')
    replicated = next(i for i in root.findall('Item') if i.get('class') == 'ReplicatedStorage')
    shared_folder = next(i for i in replicated.iter('Item') if name(i) == 'Shared')
    manifest = []
    for folder in ('Shared', 'Server', 'Client'):
        destination = OUT / 'Fontes' / folder
        destination.mkdir(parents=True, exist_ok=True)
        for path in sorted((ROOT / folder).glob('*.luau')):
            suffix = ('.server.luau' if path.name.endswith('.server.luau') else
                      '.client.luau' if path.name.endswith('.client.luau') else '.luau')
            short = path.name.removesuffix(suffix)
            wanted = 'EggTycoonV3_' + short if folder == 'Client' else short
            aliases = {wanted, 'EggTycoonV3' + short} if folder == 'Client' else {wanted}
            parent = client_folder if folder == 'Client' else shared_folder if folder == 'Shared' else server_folder
            matches = [i for i in parent.findall('Item') if name(i) in aliases and
                       i.get('class') in ('Script', 'LocalScript', 'ModuleScript')]
            if matches:
                target = matches[0]
            else:
                cls = 'LocalScript' if suffix == '.client.luau' else 'Script' if suffix == '.server.luau' else 'ModuleScript'
                target = item(parent, cls, wanted, 'NEW_' + folder + '_' + short)
            prop(target, 'string', 'Name', wanted)
            prop(target, 'ProtectedString', 'Source', path.read_text(encoding='utf-8-sig'))
            if short.startswith('Studio') and target.get('class') != 'ModuleScript':
                prop(target, 'bool', 'Disabled', 'true')
            shutil.copyfile(path, destination / path.name)
            manifest.append({'path': path.relative_to(ROOT).as_posix(),
                             'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})

    storage = next((i for i in root.findall('Item') if i.get('class') == 'ServerStorage'), None)
    if storage is None:
        storage = item(root, 'ServerStorage', 'ServerStorage', 'V3_ServerStorage')
    for old in list(storage.findall('Item')):
        if name(old) == 'EggTycoonV2_Backup':
            storage.remove(old)
    backup = json.loads((ROOT / 'Backups/V2-backup.json').read_text(encoding='utf-8'))
    nodes = emit_rows(backup, storage)
    for row in backup:
        if row['Class'] in ('Script', 'LocalScript'):
            prop(nodes[row['Id']], 'bool', 'Disabled', 'true')
    raw = item(nodes[backup[0]['Id']], 'StringValue', 'BackupMetadataJSON', 'V2_Metadata')
    prop(raw, 'string', 'Value', json.dumps(backup, separators=(',', ':'), ensure_ascii=False))

    path = OUT / 'StealAnEggTycoonV3.rbxlx'
    tree.write(path, encoding='utf-8', xml_declaration=True)
    shutil.copyfile(path, ROOT / path.name)
    (OUT / 'manifesto-fontes.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8')
    for filename in ('LEIA-ME.md', 'HUD.md'):
        if (ROOT / filename).exists():
            shutil.copyfile(ROOT / filename, OUT / filename)
    if scene_rows is not None:
        shutil.copytree(ROOT / 'Map', OUT / 'Map', dirs_exist_ok=True)
    print(json.dumps({'project': str(path), 'sources': len(manifest), 'backupInstances': len(backup),
                      'authoredSceneInstances': len(scene_rows) if scene_rows is not None else 0,
                      'bytes': path.stat().st_size}))


if __name__ == '__main__':
    main()
