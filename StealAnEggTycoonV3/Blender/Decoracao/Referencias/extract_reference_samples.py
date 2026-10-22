"""Read-only reference extraction from local Roblox binary files; never runs scripts.

This deliberately limited decoder extracts only visual primitive properties. External
MeshIds are recorded as references and are not downloaded. It is not a place importer.
"""
from pathlib import Path
import ctypes
import ctypes.util
import json
import math
import struct
from collections import defaultdict


def u32(data, pos):
    return struct.unpack_from('<I', data, pos)[0], pos + 4


def string(data, pos):
    size, pos = u32(data, pos)
    return data[pos:pos + size].decode('utf8', errors='replace'), pos + size


def uints(data, pos, count):
    values = [sum(data[pos + i + j * count] << (24 - 8 * j) for j in range(4)) for i in range(count)]
    return values, pos + 4 * count


def refs(data, pos, count):
    values, pos = uints(data, pos, count)
    total, out = 0, []
    for value in values:
        total += (value >> 1) ^ -(value & 1)
        out.append(total)
    return out, pos


def floats(data, pos, count):
    values, pos = uints(data, pos, count)
    return [struct.unpack('<f', struct.pack('<I', (value >> 1) | ((value & 1) << 31)))[0] for value in values], pos


def vectors(data, pos, count, dimensions=3):
    axes = []
    for _ in range(dimensions):
        axis, pos = floats(data, pos, count)
        axes.append(axis)
    return [list(values) for values in zip(*axes)], pos


def cframes(data, pos, count):
    rotations = []
    normals = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (-1, 0, 0), (0, -1, 0), (0, 0, -1)]
    for _ in range(count):
        rotation_id = data[pos]
        pos += 1
        if rotation_id:
            right = normals[(rotation_id - 1) // 6]
            up = normals[(rotation_id - 1) % 6]
            back = (right[1]*up[2]-right[2]*up[1], right[2]*up[0]-right[0]*up[2], right[0]*up[1]-right[1]*up[0])
            rotation = [right[0], up[0], back[0], right[1], up[1], back[1], right[2], up[2], back[2]]
        else:
            rotation = list(struct.unpack_from('<9f', data, pos))
            pos += 36
        rotations.append(rotation)
    positions, pos = vectors(data, pos, count)
    return [position + rotation for position, rotation in zip(positions, rotations)], pos


class ReferenceFile:
    def __init__(self, file):
        self.file = Path(file)
        self.nodes = {}
        self.children = defaultdict(list)
        zstd = ctypes.CDLL(ctypes.util.find_library('zstd'))
        zstd.ZSTD_decompress.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_size_t]
        zstd.ZSTD_decompress.restype = ctypes.c_size_t
        data = self.file.read_bytes()
        if data[:8] != b'<roblox!':
            raise ValueError('Expected Roblox binary header')
        pos, types = 32, {}
        allowed = {'Name', 'CFrame', 'PivotOffset', 'size', 'Color3uint8', 'Color3', 'shape', 'Material',
                   'Transparency', 'Reflectance', 'MeshId', 'TextureID', 'TextureId', 'MeshType', 'Scale', 'Offset'}
        while pos + 16 <= len(data):
            signature = data[pos:pos + 4]
            compressed, uncompressed, _ = struct.unpack_from('<III', data, pos + 4)
            pos += 16
            blob = data[pos:pos + (compressed or uncompressed)]
            pos += compressed or uncompressed
            if compressed:
                output = ctypes.create_string_buffer(uncompressed)
                result = zstd.ZSTD_decompress(output, uncompressed, blob, len(blob))
                if result != uncompressed:
                    raise ValueError(f'Unsupported compressed chunk {signature!r}')
                blob = output.raw
            if signature == b'INST':
                type_id, cursor = u32(blob, 0)
                classname, cursor = string(blob, cursor)
                cursor += 1
                count, cursor = u32(blob, cursor)
                instance_ids, cursor = refs(blob, cursor, count)
                types[type_id] = instance_ids
                self.nodes.update({ref: {'Class': classname, 'Properties': {}} for ref in instance_ids})
            elif signature == b'PROP':
                type_id, cursor = u32(blob, 0)
                name, cursor = string(blob, cursor)
                datatype = blob[cursor]
                cursor += 1
                if name not in allowed:
                    continue
                instance_ids = types[type_id]
                count = len(instance_ids)
                if datatype == 1:
                    values = []
                    for _ in range(count):
                        value, cursor = string(blob, cursor)
                        values.append(value)
                elif datatype == 4:
                    values, cursor = floats(blob, cursor, count)
                elif datatype in (12, 14):
                    values, cursor = vectors(blob, cursor, count)
                elif datatype == 13:
                    values, cursor = vectors(blob, cursor, count, 2)
                elif datatype == 16:
                    values, cursor = cframes(blob, cursor, count)
                elif datatype == 18:
                    values, cursor = uints(blob, cursor, count)
                elif datatype == 26:
                    values = [[blob[cursor + i], blob[cursor + count + i], blob[cursor + 2 * count + i]] for i in range(count)]
                else:
                    continue
                for ref, value in zip(instance_ids, values):
                    self.nodes[ref]['Properties'][name] = value
            elif signature == b'PRNT':
                count, cursor = u32(blob, 1)
                instance_ids, cursor = refs(blob, cursor, count)
                parent_ids, cursor = refs(blob, cursor, count)
                for ref, parent in zip(instance_ids, parent_ids):
                    self.nodes[ref]['Parent'] = parent
                    self.children[parent].append(ref)
            elif signature[:3] == b'END':
                break

    def path(self, ref):
        path, seen = [], set()
        while ref in self.nodes and ref not in seen:
            seen.add(ref)
            node = self.nodes[ref]
            path.append(node['Properties'].get('Name', node['Class']))
            ref = node.get('Parent', -1)
        return '/'.join(reversed(path))

    def descendants(self, ref):
        out, queue = [], [ref]
        while queue:
            current = queue.pop()
            out.append(current)
            queue.extend(self.children.get(current, []))
        return out

    def sample(self, ref, label):
        rows = []
        for node_id in self.descendants(ref):
            node = self.nodes[node_id]
            if node['Class'] not in ('Part', 'WedgePart', 'CornerWedgePart', 'MeshPart', 'UnionOperation', 'SpecialMesh'):
                continue
            rows.append({'Id': node_id, 'Parent': node.get('Parent'), 'Class': node['Class'], 'Properties': node['Properties']})
        return {'Label': label, 'SourceFile': self.file.name, 'SourcePath': self.path(ref), 'Parts': rows,
                'Notes': 'Visual reference only; source scripts, UI, game logic and player data omitted. MeshId references are not geometry.'}


if __name__ == '__main__':
    project = Path(__file__).resolve().parents[4]
    input_folder = project / 'Mapas open source'
    out_folder = Path(__file__).resolve().parent
    all_samples = []
    inventory = []
    desired = [
        ('Zone1/Decor/Trees/', 'Arvore_campo'),
        ('Zone2/Decor/Trees/', 'Arvore_seca'),
        ('Zone2/Decor/Cactus/Cactus', 'Cacto'),
        ('Zone3/Decor/Trees/', 'Pinheiro_nevado'),
        ('Zone4/Decor/Trees/', 'Arvore_rosa'),
        ('Zone5/Decor/Trees/', 'Arvore_tropical'),
        ('Zone8/Build/Sakura Tree', 'Sakura'),
        ('Zone1/Decor/Rocks/', 'Pedras'),
        ('Zone1/Decor/Grass/Grass', 'Grama'),
    ]
    for file in input_folder.iterdir():
        reference = ReferenceFile(file)
        inventory.append({'File': file.name, 'Bytes': file.stat().st_size, 'Instances': len(reference.nodes), 'Format': 'Roblox binary, Zstd chunks'})
        if file.name == 'MeuMapa.rbxlx':
            for fragment, label in desired:
                for ref, node in reference.nodes.items():
                    if node['Class'] not in ('Model', 'Folder'):
                        continue
                    path = reference.path(ref)
                    if path.startswith('Workspace/Build/ZoneBuilds/') and fragment in path:
                        all_samples.append(reference.sample(ref, label))
                        break
        elif file.name == '2.rbxlx':
            for name, label in [('GlowingFlower', 'Flor_luminosa'), ('Mushroom', 'Cogumelo'), ('Fern1', 'Samambaia'), ('Bush1', 'Arbusto')]:
                for ref, node in reference.nodes.items():
                    path = reference.path(ref)
                    if node['Properties'].get('Name') == name and path.startswith('Workspace/World/Build/') and ('Props/' in path):
                        all_samples.append(reference.sample(ref, label))
                        break
    (out_folder / 'samples.json').write_text(json.dumps({'Inventory': inventory, 'Samples': all_samples}, ensure_ascii=False, indent=2), encoding='utf8')
    print(json.dumps({'inventory': inventory, 'samples': [{key: value for key, value in sample.items() if key != 'Parts'} | {'PartCount': len(sample['Parts'])} for sample in all_samples]}, ensure_ascii=False, indent=2))
