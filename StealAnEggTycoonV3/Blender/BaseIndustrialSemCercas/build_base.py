"""Original Blender base closely following the user's gray/studded screenshots.

Run this source in Blender through the MCP. BASE_OUT and BASE_SCENE may be supplied
by the caller. A NEW scene is created; existing scenes and their objects remain.
The FBX contains only the six reusable visual meshes. The floor, sign face,
lasers and lights in the preview collection are references for native Studio parts.
All authored dimensions are Roblox studs, converted to Blender (X, -Z, Y).
The wooden fence is omitted; the roof remains visible when players enter.
"""
import bpy
import bmesh
import json
import math
import os
from collections import defaultdict
from mathutils import Matrix, Vector


OUT = os.path.abspath(globals().get('BASE_OUT') or
                      'D:/Roblox aura/StealAnEggTycoonV3/Blender/BaseIndustrialSemCercas')
SCENE_NAME = globals().get('BASE_SCENE', 'BaseIndustrialSemCercas')
assert bpy.data.scenes.get(SCENE_NAME) is None, 'Scene already exists: ' + SCENE_NAME
os.makedirs(OUT, exist_ok=True)
os.makedirs(os.path.join(OUT, 'Exportacoes'), exist_ok=True)

scene = bpy.data.scenes.new(SCENE_NAME)
bpy.context.window.scene = scene
scene.unit_settings.system = 'NONE'
scene.unit_settings.scale_length = 1.0
scene['Generator'] = 'build_base.py'
scene['Description'] = 'Original gray studded base inspired by the three user screenshots'
scene['Axes'] = 'Blender [X,-RobloxZ,RobloxY]; geometry.json is Roblox [X,Y,Z]'
visuals = bpy.data.collections.new(SCENE_NAME + '_Exportar')
preview = bpy.data.collections.new(SCENE_NAME + '_Previa_Nao_Exportar')
scene.collection.children.link(visuals)
scene.collection.children.link(preview)

PALETTE = {
    'Estrutura': (40, 43, 54),
    'Colunas': (83, 85, 99),
    'Roof': (95, 96, 110),
    'MoldurasBrancas': (239, 235, 239),
    'StudsCinza': (106, 107, 120),
    'MolduraPlaca': (156, 83, 61),
    'Placa': (139, 72, 55),
    'Laser': (255, 33, 51),
    'Luz': (255, 242, 235),
    'Piso': (92, 95, 109),
}
materials = {}


def linear(value):
    value /= 255
    return value / 12.92 if value <= .04045 else ((value + .055) / 1.055) ** 2.4


def material(key, emission=False):
    cache_key = (key, emission)
    if cache_key in materials:
        return materials[cache_key]
    color = PALETTE[key]
    rgba = tuple(linear(c) for c in color) + (1,)
    mat = bpy.data.materials.new('BI_' + key + ('_Emissivo' if emission else ''))
    mat.use_nodes = True
    mat.diffuse_color = rgba
    node = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value = rgba
    node.inputs['Roughness'].default_value = .73
    if emission:
        if 'Emission Color' in node.inputs:
            node.inputs['Emission Color'].default_value = rgba
        if 'Emission Strength' in node.inputs:
            node.inputs['Emission Strength'].default_value = 3
    mat['ExportColorSRGB'] = [c / 255 for c in color]
    mat['ExportGlow'] = emission
    materials[cache_key] = mat
    return mat


def blender_vector(roblox):
    x, y, z = roblox
    return Vector((x, -z, y))


class MeshGroup:
    """Join independent authored solids into one material/one imported MeshPart."""
    def __init__(self, role):
        self.role = role
        self.bm = bmesh.new()
        self.bevel_edges = defaultdict(list)
        self.boxes = 0

    def box(self, center, size, bevel=0, orientation=None):
        vertices = bmesh.ops.create_cube(self.bm, size=1)['verts']
        sx, sy, sz = size
        transform = Matrix.Diagonal((sx, sz, sy, 1))
        if orientation is not None:
            transform = orientation @ transform
        transform.translation = blender_vector(center)
        bmesh.ops.transform(self.bm, matrix=transform, verts=vertices)
        if bevel:
            edges = {edge for vertex in vertices for edge in vertex.link_edges}
            self.bevel_edges[bevel].extend(edges)
        self.boxes += 1

    def finish(self, collection=visuals):
        # Only the selected structural edges are beveled. Tiny studs remain square.
        for width, edges in self.bevel_edges.items():
            bmesh.ops.bevel(self.bm, geom=edges, offset=width, segments=1,
                            profile=.5, clamp_overlap=True)
        bmesh.ops.recalc_face_normals(self.bm, faces=list(self.bm.faces))
        mesh = bpy.data.meshes.new('BI_' + self.role + '_Geometry')
        self.bm.to_mesh(mesh)
        self.bm.free()
        mesh.update()
        mesh.calc_loop_triangles()
        obj = bpy.data.objects.new('BI_' + self.role, mesh)
        collection.objects.link(obj)
        obj.data.materials.append(material(self.role))
        obj['ExportRole'] = self.role
        obj['SourceBoxes'] = self.boxes
        obj['Optional'] = False
        return obj


groups = {key: MeshGroup(key) for key in (
    'Estrutura', 'Colunas', 'Roof', 'MoldurasBrancas', 'StudsCinza',
    'MolduraPlaca')}


def box(role, center, size, bevel=0):
    groups[role].box(center, size, bevel)


def stud(role, center, face):
    # Square raised studs match the blocky visual language of the reference.
    sizes = {'front': (1.12, 1.12, .22), 'side': (.22, 1.12, 1.12),
             'top': (1.12, .22, 1.12)}
    box(role, center, sizes[face])


# Thick corner supports and an overhanging rim, like the screenshot silhouette.
for x in (-76, 76):
    for z in (-76, 76):
        box('Colunas', (x, 14, z), (8, 28, 8), .16)
box('Colunas', (0, 27.3, -80), (164, 2.6, 5.2), .16)
for x in (-80, 80):
    box('Colunas', (x, 27.3, 0), (5.2, 2.6, 160), .16)
box('Colunas', (0, 27.3, 80), (164, 2.6, 5.2), .16)

# Three continuous window walls with genuinely empty central window openings.
for side in (-1, 1):
    x = side * 80
    box('Colunas', (x, 2, 0), (3.2, 4, 152), .1)
    box('Estrutura', (x, 5, 0), (2.4, 2, 144), .08)
    box('Estrutura', (x, 25, 0), (2.4, 4, 144), .08)
    for z in (-71, 71):
        box('Estrutura', (x, 14.5, z), (2.4, 17, 4), .08)
    # The white border is on the outside face and is not glass or a decal.
    for y in (6, 23):
        box('MoldurasBrancas', (side * 81.35, y, 0), (1.1, 1.8, 140), .08)
    for z in (-69.1, 69.1):
        box('MoldurasBrancas', (side * 81.35, 14.5, z), (1.1, 18.8, 1.8), .08)
    for y in (6, 23):
        for z in range(-66, 67, 4):
            stud('MoldurasBrancas', (side * 82.01, y, z), 'side')
    for z in (-69.1, 69.1):
        for y in (9, 13, 17, 21):
            stud('MoldurasBrancas', (side * 82.01, y, z), 'side')

box('Colunas', (0, 2, 80), (152, 4, 3.2), .1)
box('Estrutura', (0, 5, 80), (144, 2, 2.4), .08)
box('Estrutura', (0, 25, 80), (144, 4, 2.4), .08)
for x in (-71, 71):
    box('Estrutura', (x, 14.5, 80), (4, 17, 2.4), .08)
for y in (6, 23):
    box('MoldurasBrancas', (0, y, 81.35), (140, 1.8, 1.1), .08)
for x in (-69.1, 69.1):
    box('MoldurasBrancas', (x, 14.5, 81.35), (1.8, 18.8, 1.1), .08)
for y in (6, 23):
    for x in range(-66, 67, 4):
        stud('MoldurasBrancas', (x, y, 82.01), 'front')
for x in (-69.1, 69.1):
    for y in (9, 13, 17, 21):
        stud('MoldurasBrancas', (x, y, 82.01), 'front')

# A low front sill leaves the existing central sixteen-stud route clear.
for side in (-1, 1):
    box('Colunas', (side * 42, 1.8, -80), (68, 3.6, 4), .12)

# Structural studs are grouped into one cheap reusable visual mesh.
for x in (-76, 76):
    for z in (-76, 76):
        for h in range(2, 27, 4):
            for dx in (-2, 2):
                stud('StudsCinza', (x + dx, h, z + (-4.12 if z < 0 else 4.12)), 'front')
                stud('StudsCinza', (x + (-4.12 if x < 0 else 4.12), h, z + dx), 'side')
for x in range(-78, 79, 4):
    stud('StudsCinza', (x, 27.3, -82.72), 'front')
    stud('StudsCinza', (x, 27.3, 82.72), 'front')
    stud('StudsCinza', (x, 2, 81.72), 'front')
    if abs(x) > 9:
        stud('StudsCinza', (x, 1.8, -82.12), 'front')
for z in range(-74, 75, 4):
    for side in (-1, 1):
        stud('StudsCinza', (side * 82.72, 27.3, z), 'side')
        stud('StudsCinza', (side * 81.72, 2, z), 'side')

# ONE Roof mesh includes its slab and every ceiling/top stud. The client keeps
# this roof visible when the owner enters or uses construction mode.
box('Roof', (0, 28.4, 0), (162, 1.8, 162), .16)
for x in range(-76, 77, 8):
    for z in range(-76, 77, 8):
        stud('Roof', (x, 29.42, z), 'top')
        stud('Roof', (x, 27.38, z), 'top')

# Brown beveled sign frame; the live OwnerSign face/text remain native and editable.
for y in (24.5, 33.5):
    box('MolduraPlaca', (0, y, -83.5), (61.5, 1.35, 1.5), .18)
for x in (-30, 30):
    box('MolduraPlaca', (x, 29, -83.5), (1.5, 9, 1.5), .18)
for x in range(-28, 29, 4):
    for y in (24.5, 33.5):
        stud('MolduraPlaca', (x, y, -84.36), 'front')
for x in (-30, 30):
    for y in (27, 31):
        stud('MolduraPlaca', (x, y, -84.36), 'front')

export_objects = [group.finish() for group in groups.values()]


def preview_box(name, color_key, center, size, emission=False):
    group = MeshGroup(color_key)
    group.box(center, size)
    obj = group.finish(preview)
    obj.name = 'PREVIA_' + name
    obj.data.materials.clear()
    obj.data.materials.append(material(color_key, emission))
    obj['DoNotExport'] = True
    return obj


preview_box('Piso', 'Piso', (0, -.3, 0), (160, .6, 160))
preview_box('OwnerSign', 'Placa', (0, 29, -83.35), (59, 7.8, .8))
for x in range(-68, 69, 4):
    preview_box('Laser', 'Laser', (x, 13.5, -80), (.48, 25, .48), True)
# The floor is at zero; the exterior red steps reach it without raising the floor.
preview_box('DegrauInferior', 'Laser', (0, -1.55, -87), (20, .9, 6))
preview_box('DegrauSuperior', 'Laser', (0, -.65, -83), (18, .9, 4))
lamp_centers = []
for x in (-48, 48):
    for z in (-48, 0, 48):
        center = (x, 26.8, z)
        preview_box('Luminaria', 'Estrutura', center, (7, .9, 7))
        preview_box('Difusor', 'Luz', (x, 26.23, z), (5.5, .3, 5.5), True)
        lamp_centers.append(list(center))

text_data = bpy.data.curves.new('BI_PreviewOwnerText', type='FONT')
text_data.body = 'Base de Jogador'
text_data.align_x = 'CENTER'
text_data.align_y = 'CENTER'
text_data.size = 4
text = bpy.data.objects.new('PREVIA_Texto_Nao_Exportar', text_data)
preview.objects.link(text)
text.location = blender_vector((0, 29, -84))
text.rotation_euler = (math.pi / 2, 0, math.pi)
text.data.materials.append(material('MoldurasBrancas'))

parts = []
for obj in export_objects:
    mesh = obj.data
    vertices = [[round(v.co.x, 6), round(v.co.z, 6), round(-v.co.y, 6)] for v in mesh.vertices]
    triangles = [[i + 1 for i in triangle.vertices] for triangle in mesh.loop_triangles]
    low = [min(v[i] for v in vertices) for i in range(3)]
    high = [max(v[i] for v in vertices) for i in range(3)]
    role = obj['ExportRole']
    parts.append({'Name': obj.name, 'Role': role, 'Vertices': vertices, 'Triangles': triangles,
                  'Bounds': {'Min': low, 'Max': high},
                  'Color': [c / 255 for c in PALETTE[role]], 'Glow': False,
                  'Collision': False, 'Optional': bool(obj['Optional'])})

payload = {
    'Revision': 'BaseIndustrial_v1', 'Generator': 'build_base.py',
    'Units': 'studs', 'Axes': 'Roblox Y-up', 'Pivot': [0, 0, 0],
    'Models': [{'Id': 'BaseIndustrial', 'Name': 'Base Industrial', 'Parts': parts}],
    'NativePartPlan': {
        'OwnerSign': {'Center': [0, 29, -83.35], 'Size': [59, 7.8, .8], 'Color': list(PALETTE['Placa'])},
        'Laser': {'Center': [0, 13.5, -80], 'Size': [140, 25, .5], 'Color': list(PALETTE['Laser'])},
        'LaserBeamsX': list(range(-68, 69, 4)),
        'WindowPlanes': [{'Center': [x, 14, z], 'Size': size} for x, z, size in
                         [(-80, 0, [2, 28, 160]), (80, 0, [2, 28, 160]), (0, 80, [160, 28, 2])]],
        'RoofCollider': {'Center': [0, 28.4, 0], 'Size': [162, 1.8, 162]},
        'LampCenters': lamp_centers,
        'CentralRoute': {'HalfWidth': 8, 'FrontZ': -80},
    },
    'PreviewExcluded': 'Floor, lasers, steps, sign face/text and lamps are native Studio references only.',
}
geometry_path = os.path.join(OUT, 'geometry.json')
with open(geometry_path, 'w', encoding='utf-8') as stream:
    json.dump(payload, stream, ensure_ascii=False, separators=(',', ':'))
with open(os.path.join(OUT, 'installation-spec.json'), 'w', encoding='utf-8') as stream:
    compact = {**payload, 'Models': [{**payload['Models'][0], 'Parts': [
        {k: value for k, value in p.items() if k not in ('Vertices', 'Triangles')} for p in parts]}]}
    json.dump(compact, stream, ensure_ascii=False, separators=(',', ':'))

for obj in bpy.context.selected_objects:
    obj.select_set(False)
for obj in export_objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = export_objects[0]
fbx_path = os.path.join(OUT, 'Exportacoes', 'BaseIndustrial.fbx')
fbx_parameters = bpy.ops.export_scene.fbx.get_rna_type().properties
assert '-Z' in {v.identifier for v in fbx_parameters['axis_forward'].enum_items}
assert 'Y' in {v.identifier for v in fbx_parameters['axis_up'].enum_items}
bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, object_types={'MESH'},
                         axis_forward='-Z', axis_up='Y', apply_unit_scale=False,
                         bake_anim=False, add_leaf_bones=False, use_mesh_modifiers=True,
                         path_mode='AUTO')
for obj in export_objects:
    obj.select_set(False)

# All presentation objects belong solely to the new scene.
camera_data = bpy.data.cameras.new('BI_Camera')
camera = bpy.data.objects.new('BI_Camera', camera_data)
scene.collection.objects.link(camera)
camera.location = (205, 245, 125)
target = Vector((0, 0, 12))
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera_data.lens = 44
camera_data.clip_end = 2000
scene.camera = camera
for name, location, energy, size in (
        ('BI_Key', (50, 110, 160), 170000, 130),
        ('BI_Fill', (-130, 20, 95), 100000, 130)):
    light_data = bpy.data.lights.new(name, type='AREA')
    light_data.energy = energy
    light_data.shape = 'DISK'
    light_data.size = size
    light = bpy.data.objects.new(name, light_data)
    scene.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (target - light.location).to_track_quat('-Z', 'Y').to_euler()
world = bpy.data.worlds.new('BI_World')
world.use_nodes = True
background = next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND')
background.inputs['Color'].default_value = (.14, .17, .22, 1)
background.inputs['Strength'].default_value = .45
scene.world = world
try:
    scene.render.engine = 'BLENDER_EEVEE'
except TypeError:
    scene.render.engine = 'BLENDER_WORKBENCH'
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
formats = {v.identifier for v in bpy.types.ImageFormatSettings.bl_rna.properties['file_format'].enum_items}
assert 'PNG' in formats
scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = os.path.join(OUT, 'base-blender.png')
view_transforms = {v.identifier for v in bpy.types.ColorManagedViewSettings.bl_rna.properties['view_transform'].enum_items}
if 'Standard' in view_transforms:
    scene.view_settings.view_transform = 'Standard'
scene.view_settings.exposure = .5
scene.view_settings.gamma = 1
blend_path = os.path.join(OUT, 'BaseIndustrial.blend')
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(json.dumps({'Scene': SCENE_NAME, 'Blend': blend_path, 'FBX': fbx_path,
                  'Geometry': geometry_path, 'Parts': len(parts),
                  'Vertices': sum(len(p['Vertices']) for p in parts),
                  'Triangles': sum(len(p['Triangles']) for p in parts),
                  'RoofIncludesAllCeilingStuds': True,
                  'Rendered': False}, ensure_ascii=False))
