"""Original industrial generator, authored in Roblox studs for the Blender MCP.

Run only in Blender. GENERATOR_OUT and GENERATOR_SCENE may override the defaults.
A new scene is required; previous scenes and models remain untouched. Exported
geometry contains seven material groups. The live health display is a native
Studio Part/SurfaceGui described by NativePartPlan.Panel, not baked mesh text.
"""
import bpy
import bmesh
import json
import math
import os
from collections import defaultdict
from mathutils import Matrix, Vector

OUT = os.path.abspath(globals().get('GENERATOR_OUT') or
                      'D:/Roblox aura/StealAnEggTycoonV3/Blender/GeradorIndustrial')
SCENE_NAME = globals().get('GENERATOR_SCENE', 'GeradorIndustrial')
assert bpy.data.scenes.get(SCENE_NAME) is None, 'Scene already exists: ' + SCENE_NAME
os.makedirs(os.path.join(OUT, 'Exportacoes'), exist_ok=True)
scene = bpy.data.scenes.new(SCENE_NAME)
bpy.context.window.scene = scene
scene.unit_settings.system = 'NONE'
scene.unit_settings.scale_length = 1.0
scene['Generator'] = 'build_generator.py'
scene['Axes'] = 'Blender [X,-RobloxZ,RobloxY]; JSON uses Roblox Y-up'
scene['Description'] = 'Original green industrial generator with a recessed health console'
visuals = bpy.data.collections.new(SCENE_NAME + '_Exportar')
preview = bpy.data.collections.new(SCENE_NAME + '_Previa_Nao_Exportar')
scene.collection.children.link(visuals)
scene.collection.children.link(preview)

PALETTE = {
    'CarcacaVerde': (138, 184, 64),
    'ChassiCinza': (83, 85, 99),
    'GrelhasEscuras': (32, 37, 46),
    'Ferragens': (167, 174, 185),
    'MoldurasClaras': (239, 235, 239),
    'RelevosVerdes': (171, 205, 88),
    'DetalhesAmarelos': (255, 195, 61),
    'Tela': (12, 25, 33),
    'Texto': (175, 255, 184),
}
materials = {}
AXES = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))


def linear(v):
    v /= 255
    return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4


def material(role):
    if role in materials:
        return materials[role]
    color = tuple(linear(v) for v in PALETTE[role]) + (1,)
    mat = bpy.data.materials.new('GI_' + role)
    mat.use_nodes = True
    mat.diffuse_color = color
    node = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value = color
    node.inputs['Roughness'].default_value = .62 if role == 'Ferragens' else .76
    node.inputs['Metallic'].default_value = .42 if role == 'Ferragens' else .05
    mat['ExportColorSRGB'] = [v / 255 for v in PALETTE[role]]
    materials[role] = mat
    return mat


def xyz(v):
    return AXES @ Vector(v)


class MeshGroup:
    def __init__(self, role):
        self.role = role
        self.bm = bmesh.new()
        self.bevel = defaultdict(list)
        self.solids = 0

    def box(self, center, size, bevel=0, rotation=None):
        vertices = bmesh.ops.create_cube(self.bm, size=1)['verts']
        rotation = rotation or Matrix.Identity(3)
        transform = (AXES @ rotation @ Matrix.Diagonal(Vector(size))).to_4x4()
        transform.translation = xyz(center)
        bmesh.ops.transform(self.bm, matrix=transform, verts=vertices)
        if bevel:
            self.bevel[bevel].extend({e for v in vertices for e in v.link_edges})
        self.solids += 1

    def cylinder(self, center, radius, depth, axis='Z', sides=10):
        result = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False,
                                     segments=sides, radius1=radius, radius2=radius,
                                     depth=depth)
        # bmesh cone axis is Blender Z. Rotate it onto the desired Roblox axis.
        desired = xyz({'X': (1, 0, 0), 'Y': (0, 1, 0), 'Z': (0, 0, 1)}[axis])
        rotation = Vector((0, 0, 1)).rotation_difference(desired).to_matrix().to_4x4()
        rotation.translation = xyz(center)
        bmesh.ops.transform(self.bm, matrix=rotation, verts=result['verts'])
        self.solids += 1

    def finish(self, collection=visuals, name=None):
        for width, edges in self.bevel.items():
            bmesh.ops.bevel(self.bm, geom=edges, offset=width, segments=1,
                            profile=.5, clamp_overlap=True)
        bmesh.ops.recalc_face_normals(self.bm, faces=list(self.bm.faces))
        mesh = bpy.data.meshes.new('GI_' + self.role + '_Geometry')
        self.bm.to_mesh(mesh)
        self.bm.free()
        mesh.update()
        mesh.calc_loop_triangles()
        obj = bpy.data.objects.new(name or ('GI_' + self.role), mesh)
        collection.objects.link(obj)
        obj.data.materials.append(material(self.role))
        obj['ExportRole'] = self.role
        obj['SourceName'] = 'GI_' + self.role
        obj['SourceSolids'] = self.solids
        return obj


ROLES = ('CarcacaVerde', 'ChassiCinza', 'GrelhasEscuras', 'Ferragens',
         'MoldurasClaras', 'RelevosVerdes', 'DetalhesAmarelos')
groups = {role: MeshGroup(role) for role in ROLES}


def box(role, center, size, bevel=0, rotation=None):
    groups[role].box(center, size, bevel, rotation)


def stud(role, center, side='front'):
    sizes = {'front': (.24, .24, .075), 'side': (.075, .24, .24),
             'top': (.24, .075, .24)}
    box(role, center, sizes[side], .018)


# A low skid with open fork slots, four vibration feet and a raised belly tank.
for x in (-4.85, 4.85):
    for z in (-2.2, 2.2):
        box('GrelhasEscuras', (x, .23, z), (1.65, .46, 1.35), .09)
        box('Ferragens', (x, .49, z), (1.3, .12, 1.1), .025)
box('ChassiCinza', (0, .98, 0), (12, .88, 6), .14)
box('GrelhasEscuras', (0, .99, -3.015), (11.6, .49, .1), .03)
for x in (-2.7, 2.7):
    box('GrelhasEscuras', (x, .52, -1.7), (1.2, .43, 2.6), .035)
for x in (-5.1, -4.2, -3.3, -1.5, -.6, .6, 1.5, 3.3, 4.2, 5.1):
    stud('Ferragens', (x, 1.05, -3.09))
box('RelevosVerdes', (0, 1.48, -.05), (11.7, .18, 5.7), .045)

# Rounded acoustic enclosure. The separate doors and edge rails create real gaps.
box('CarcacaVerde', (0, 3.8, .38), (11.35, 4.62, 4.6), .15)
for side in (-1, 1):
    box('CarcacaVerde', (side * 5.58, 3.83, .04), (.55, 4.72, 5.45), .14)
    box('RelevosVerdes', (side * 5.55, 6.16, .42), (.58, .28, 4.7), .065)
box('CarcacaVerde', (0, 6.18, 1.42), (11.42, .38, 2.58), .11)
box('ChassiCinza', (0, 6.37, 2.6), (10.8, .12, .18), .025)

# Main side faces: recessed intake plates with separate raised cooling louvers.
box('GrelhasEscuras', (-5.91, 3.76, .08), (.12, 3.55, 4.45), .04)
for z in (-1.86, -1.4, -.94, -.48, -.02, .44, .9, 1.36, 1.82):
    box('RelevosVerdes', (-6.005, 3.76, z), (.13, 3.26, .17), .035)
for y in (1.92, 5.61):
    box('CarcacaVerde', (-5.965, y, .08), (.17, .18, 4.58), .035)
for z in (-2.24, 2.4):
    box('CarcacaVerde', (-5.965, 3.76, z), (.17, 3.85, .18), .035)

for z in (-1.18, 1.38):
    box('GrelhasEscuras', (5.89, 3.8, z), (.12, 3.44, 1.9), .05)
    for y in (2.36, 2.74, 3.12, 3.5, 3.88, 4.26, 4.64, 5.02, 5.4):
        box('RelevosVerdes', (5.995, y, z), (.12, .14, 1.68), .028)

# Back radiator and tidy perimeter rail, no imported branding.
box('GrelhasEscuras', (0, 3.84, 2.73), (9.45, 3.36, .16), .055)
for i in range(19):
    box('RelevosVerdes', (-4.28 + i * .475, 3.84, 2.86), (.15, 3.08, .14), .025)
for y in (2.06, 5.62):
    box('CarcacaVerde', (0, y, 2.82), (9.8, .2, .17), .03)

# Front service section: narrow vent door, two full access doors, hinges and latches.
box('GrelhasEscuras', (0, 3.47, -2.39), (10.95, 3.8, .16), .055)
box('CarcacaVerde', (-3.72, 3.5, -2.57), (3.23, 3.7, .27), .09)
box('GrelhasEscuras', (-3.72, 3.35, -2.745), (2.55, 2.34, .12), .045)
for y in (2.42, 2.76, 3.1, 3.44, 3.78, 4.12, 4.46):
    box('RelevosVerdes', (-3.72, y, -2.85), (2.33, .14, .14), .025)
for x in (-.2, 3.46):
    box('CarcacaVerde', (x, 3.44, -2.59), (3.39, 3.59, .3), .08)
    for y in (2.05, 4.83):
        box('Ferragens', (x - 1.47, y, -2.81), (.2, .41, .17), .035)
        box('ChassiCinza', (x - 1.47, y, -2.93), (.07, .26, .1), .018)
    # Stand-off pull handles: two anchors and a real bridge.
    for y in (3.25, 3.83):
        box('Ferragens', (x + 1.03, y, -2.84), (.25, .16, .2), .03)
    box('GrelhasEscuras', (x + 1.03, 3.54, -2.99), (.13, .7, .17), .035)
    groups['Ferragens'].cylinder((x + 1.03, 2.97, -2.82), .095, .1, sides=8)
    for bx in (-1.48, 1.48):
        for by in (1.88, 5.0):
            groups['Ferragens'].cylinder((x + bx, by, -2.79), .062, .07, sides=8)

# Square fasteners deliberately echo the square studs of the surrounding bases.
for x in (-5.15, -4.3, -3.45, -2.6, -1.5, -.65, .2, 1.05, 1.9, 2.75, 3.6, 4.45, 5.3):
    stud('RelevosVerdes', (x, 5.57, -2.38))
for z in (-2.17, -1.3, -.43, .44, 1.31, 2.18):
    stud('Ferragens', (-5.98, 1.68, z), 'side')
    stud('Ferragens', (5.98, 1.68, z), 'side')

# Two compact lift eyes and an exhaust stub stay below the seven-stud silhouette.
for x in (-4.55, 4.55):
    box('ChassiCinza', (x, 6.54, 1.26), (.61, .62, .3), .06)
    box('GrelhasEscuras', (x, 6.55, 1.08), (.24, .25, .06), .025)
groups['GrelhasEscuras'].cylinder((-4.58, 6.63, 2.0), .23, .54, 'Y', sides=12)
groups['Ferragens'].cylinder((-4.58, 6.93, 2.0), .3, .1, 'Y', sides=12)
box('MoldurasClaras', (3.95, 6.4, 1.83), (1.12, .12, .48), .03)

# Integrated angled console, with a generous clean rectangle for the real GUI.
PANEL_CENTER = Vector((0, 6.2, -1.85))
PANEL_SIZE = (7.6, 2.4, .14)
PANEL_ROTATION_X = 55
PANEL_ROT = Matrix.Rotation(math.radians(PANEL_ROTATION_X), 3, 'X')


def console_box(role, local_center, size, bevel=0):
    center = PANEL_CENTER + PANEL_ROT @ Vector(local_center)
    box(role, center, size, bevel, PANEL_ROT)


console_box('ChassiCinza', (0, 0, .24), (8.65, 3.18, .34), .12)
# White physical border and dark gasket; center is intentionally not filled.
for x in (-3.99, 3.99):
    console_box('MoldurasClaras', (x, 0, .005), (.25, 2.73, .18), .045)
for y in (-1.37, 1.37):
    console_box('MoldurasClaras', (0, y, .005), (8.23, .25, .18), .045)
for x in (-3.86, 3.86):
    console_box('GrelhasEscuras', (x, 0, .015), (.12, 2.5, .12), .025)
for y in (-1.25, 1.25):
    console_box('GrelhasEscuras', (0, y, .015), (7.84, .12, .12), .025)
for x in (-4.16, 4.16):
    for y in (-1.31, 1.31):
        console_box('Ferragens', (x, y, -.025), (.15, .15, .09), .025)
# Small physical caution markings flank the console instead of a floating label.
for side in (-1, 1):
    for i in range(3):
        console_box('DetalhesAmarelos', (side * 4.45, -.5 + i * .48, .16),
                    (.32, .18, .13), .015)

export_objects = [groups[role].finish() for role in ROLES]

# The screen is ONLY a visual reference; Roblox supplies its physical Part and GUI.
screen = MeshGroup('Tela')
screen.box(PANEL_CENTER, PANEL_SIZE, .03, PANEL_ROT)
screen_obj = screen.finish(preview, 'PREVIA_Tela_Nao_Exportar')
screen_obj['DoNotExport'] = True


def preview_text(body, local_center, size, color_role='Texto'):
    curve = bpy.data.curves.new('GI_PreviewText', type='FONT')
    curve.body = body
    curve.align_x = 'CENTER'
    curve.align_y = 'CENTER'
    curve.size = size
    obj = bpy.data.objects.new('PREVIA_Texto_Nao_Exportar', curve)
    preview.objects.link(obj)
    # Text local XY plane points out along local +Z. Screen front is local -Z.
    # Flip around local Y, then use the same console basis.
    basis = AXES @ PANEL_ROT @ Matrix.Rotation(math.pi, 3, 'Y')
    obj.rotation_euler = basis.to_euler()
    obj.location = xyz(PANEL_CENTER + PANEL_ROT @ Vector(local_center))
    obj.data.materials.append(material(color_role))
    obj['DoNotExport'] = True
    return obj


preview_text('GERADOR', (0, .72, -.09), .35, 'MoldurasClaras')
preview_text('200 / 200', (0, .04, -.09), .7)
preview_text('PROTEGENDO A BASE', (0, -.77, -.09), .24)

parts = []
for obj in export_objects:
    mesh = obj.data
    vertices = [[round(v.co.x, 6), round(v.co.z, 6), round(-v.co.y, 6)] for v in mesh.vertices]
    triangles = [[i + 1 for i in tri.vertices] for tri in mesh.loop_triangles]
    low = [min(v[i] for v in vertices) for i in range(3)]
    high = [max(v[i] for v in vertices) for i in range(3)]
    role = obj['ExportRole']
    parts.append({'Name': obj.name, 'SourceName': obj['SourceName'], 'Role': role,
                  'Vertices': vertices, 'Triangles': triangles,
                  'Bounds': {'Min': low, 'Max': high},
                  'Color': [c / 255 for c in PALETTE[role]], 'ColorRGB': list(PALETTE[role]),
                  'Collision': False, 'Glow': False})

panel_cf = list(PANEL_CENTER) + [round(PANEL_ROT[i][j], 9) for i in range(3) for j in range(3)]
payload = {
    'Revision': 'GeradorIndustrial_v1', 'Generator': 'build_generator.py',
    'Units': 'studs', 'Axes': 'Roblox Y-up; front=-Z', 'Pivot': [0, 0, 0],
    'Models': [{'Id': 'GeradorIndustrial', 'Name': 'Gerador Industrial', 'Parts': parts}],
    'NativePartPlan': {
        'Panel': {'Name': 'GeneratorPanel', 'Center': list(PANEL_CENTER),
                  'Size': list(PANEL_SIZE), 'RotationXDegrees': PANEL_ROTATION_X,
                  'CFrame': panel_cf, 'Face': 'Front', 'ColorRGB': list(PALETTE['Tela']),
                  'CanvasSize': [1024, 320], 'PixelsPerStud': 120,
                  'AlwaysOnTop': False, 'MaxDistance': 70},
        'Hitbox': {'Name': 'Battery', 'Center': [0, 3.5, 0], 'Size': [12, 7, 6],
                   'Note': 'Preserve the existing Battery identity. Artwork pivot is 3.5 studs below Battery.CFrame.'},
        'NativeOnly': ['Health text, health bar, rebuilding countdown and status indicators'],
    },
    'PreviewExcluded': 'Screen reference and all preview text are NOT exported in FBX.',
}
with open(os.path.join(OUT, 'geometry.json'), 'w', encoding='utf-8') as stream:
    json.dump(payload, stream, ensure_ascii=False, separators=(',', ':'))
compact = {**payload, 'Models': [{**payload['Models'][0], 'Parts': [
    {k: v for k, v in p.items() if k not in ('Vertices', 'Triangles')} for p in parts]}]}
with open(os.path.join(OUT, 'installation-spec.json'), 'w', encoding='utf-8') as stream:
    json.dump(compact, stream, ensure_ascii=False, separators=(',', ':'))

for obj in bpy.context.selected_objects:
    obj.select_set(False)
for obj in export_objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = export_objects[0]
fbx_path = os.path.join(OUT, 'Exportacoes', 'GeradorIndustrial.fbx')
fbx_parameters = bpy.ops.export_scene.fbx.get_rna_type().properties
assert '-Z' in {v.identifier for v in fbx_parameters['axis_forward'].enum_items}
assert 'Y' in {v.identifier for v in fbx_parameters['axis_up'].enum_items}
bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, object_types={'MESH'},
                         axis_forward='-Z', axis_up='Y', apply_unit_scale=False,
                         bake_anim=False, add_leaf_bones=False, use_mesh_modifiers=True)
for obj in export_objects:
    obj.select_set(False)

camera_data = bpy.data.cameras.new('GI_Camera')
camera = bpy.data.objects.new('GI_Camera', camera_data)
scene.collection.objects.link(camera)
camera.location = xyz((18, 13, -19))
target = xyz((0, 3.4, 0))
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera_data.lens = 48
camera_data.clip_end = 300
scene.camera = camera
for name, location, energy, size in (
        ('GI_Key', (1, 16, -10), 1800, 11),
        ('GI_Fill', (-12, 10, -2), 1200, 10),
        ('GI_Rim', (5, 12, 10), 2000, 9)):
    light_data = bpy.data.lights.new(name, type='AREA')
    light_data.energy = energy
    light_data.shape = 'DISK'
    light_data.size = size
    light = bpy.data.objects.new(name, light_data)
    scene.collection.objects.link(light)
    light.location = xyz(location)
    light.rotation_euler = (target - light.location).to_track_quat('-Z', 'Y').to_euler()
world = bpy.data.worlds.new('GI_World')
world.use_nodes = True
background = next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND')
background.inputs['Color'].default_value = (.12, .16, .2, 1)
background.inputs['Strength'].default_value = .45
scene.world = world
try:
    scene.render.engine = 'BLENDER_EEVEE'
except TypeError:
    scene.render.engine = 'BLENDER_WORKBENCH'
scene.render.resolution_x = 1600
scene.render.resolution_y = 1100
scene.render.resolution_percentage = 100
formats = {v.identifier for v in bpy.types.ImageFormatSettings.bl_rna.properties['file_format'].enum_items}
assert 'PNG' in formats
scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = os.path.join(OUT, 'gerador-blender.png')
view_transforms = {v.identifier for v in bpy.types.ColorManagedViewSettings.bl_rna.properties['view_transform'].enum_items}
if 'Standard' in view_transforms:
    scene.view_settings.view_transform = 'Standard'
scene.view_settings.exposure = .5
scene.view_settings.gamma = 1
blend_path = os.path.join(OUT, 'GeradorIndustrial.blend')
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(json.dumps({'Scene': SCENE_NAME, 'Blend': blend_path, 'FBX': fbx_path,
                  'Parts': len(parts), 'Vertices': sum(len(p['Vertices']) for p in parts),
                  'Triangles': sum(len(p['Triangles']) for p in parts),
                  'Panel': payload['NativePartPlan']['Panel'], 'Rendered': False}, ensure_ascii=False))
