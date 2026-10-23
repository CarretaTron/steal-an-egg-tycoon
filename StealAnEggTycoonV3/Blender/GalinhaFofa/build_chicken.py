"""Original plush/block chicken. Run in Blender via MCP; exports rigid animated parts.

White body, scarlet comb, tiny tucked wings, peach cheeks and golden feet.
The bridge replaces only Species_1/Guardian_1 in the seven-species library.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector, Matrix

OUT = Path(globals().get('CHICKEN_OUT') or Path(__file__).resolve().parent)
OUT.mkdir(parents=True, exist_ok=True)
base = OUT.parent

def enum_set(obj, key, wanted):
    valid = {i.identifier for i in obj.bl_rna.properties[key].enum_items}
    assert wanted in valid, (key, wanted, valid)
    setattr(obj, key, wanted)

old = bpy.data.scenes.get('GalinhaFofa')
if old:
    if not globals().get('CHICKEN_REBUILD'):
        raise RuntimeError('GalinhaFofa already exists. Set CHICKEN_REBUILD after preserving the file.')
    for obj in list(old.objects): bpy.data.objects.remove(obj, do_unlink=True)
    collections=list(old.collection.children)
    bpy.data.scenes.remove(old)
    for co in collections: bpy.data.collections.remove(co)
scene = bpy.data.scenes.new('GalinhaFofa')
bpy.context.window.scene = scene
scene.world = bpy.data.worlds.new('Galinha_StudioWorld')
scene.world.use_nodes = True
next(n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND').inputs['Color'].default_value = (.30,.38,.49,1)
next(n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND').inputs['Strength'].default_value = .32
model = bpy.data.collections.new('Galinha_Original')
scene.collection.children.link(model)
stage = bpy.data.collections.new('Apresentacao')
scene.collection.children.link(stage)
palette = {'white':(.96,.965,1), 'cream':(1,.91,.72), 'feather':(.82,.86,.96),
           'red':(.88,.055,.09), 'redlight':(1,.12,.16), 'beak':(1,.64,.12),
           'beaklow':(.95,.45,.065), 'foot':(1,.58,.10), 'black':(.012,.023,.048),
           'shine':(1,1,1), 'blush':(1,.51,.43), 'nostril':(.49,.22,.045)}
mats = {}
for name, color in palette.items():
    mat = bpy.data.materials.new('Galinha_'+name); mat.use_nodes = True
    mat.diffuse_color = (*color,1)
    node = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value = (*color,1)
    node.inputs['Roughness'].default_value = .24 if name == 'black' else .5
    mats[name] = mat

groups = {}
def move_to(obj, collection):
    for co in list(obj.users_collection): co.objects.unlink(obj)
    collection.objects.link(obj)

def piece(group, color, pos, size, shape='box', bevel=.18, rot=(0,0,0)):
    if shape == 'sphere':
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1, location=pos)
        obj=bpy.context.object; obj.scale=Vector(size)*.5
    else:
        bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
        obj=bpy.context.object; obj.scale=size
    move_to(obj,model)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if shape == 'box' and bevel:
        mod=obj.modifiers.new('Soft toy corners','BEVEL'); mod.width=bevel
        mod.segments=3 if group.startswith('Foot') else 1 if max(size)<.57 else 3
        enum_set(mod,'offset_type','OFFSET')
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.rotation_euler=rot
    obj.data.materials.append(mats[color])
    for polygon in obj.data.polygons: polygon.use_smooth=True
    if shape == 'box':
        mod=obj.modifiers.new('Broad clean faces','WEIGHTED_NORMAL'); mod.keep_sharp=True; mod.weight=50
        bpy.ops.object.modifier_apply(modifier=mod.name)
    groups.setdefault((group,color),[]).append(obj)
    return obj

# Coordinates: Blender +Y is the face; Z is up. Feet touch the origin plane.
piece('Body','white',(0,-.08,1.82),(3.10,2.72,2.90),bevel=.62)
piece('Head','white',(0,.26,3.48),(2.84,2.44,2.40),bevel=.59)
piece('Bib','cream',(0,1.245,1.84),(1.91,.18,1.67),shape='sphere')
# Tall eyes and broad forehead are the main cute proportions.
for s in (-1,1):
    piece('Eyes','black',(s*.69,1.471,3.57),(.49,.17,.66),bevel=.17,rot=(0,s*.035,s*.035))
    piece('EyeHighlights','shine',(s*.69-.075,1.568,3.76),(.15,.055,.19),shape='sphere')
    piece('EyeHighlights','shine',(s*.69+.095,1.565,3.43),(.065,.04,.075),shape='sphere')
    piece('Cheeks','blush',(s*1.04,1.425,3.14),(.38,.11,.21),shape='sphere')
    piece('Brows','feather',(s*.70,1.423,4.05),(.55,.105,.13),bevel=.055,rot=(0,s*.05,s*.06))
piece('Beak','beak',(0,1.70,3.23),(.83,.86,.51),bevel=.19,rot=(-.07,0,0))
piece('BeakLower','beaklow',(0,1.73,2.99),(.65,.62,.17),bevel=.075)
for s in (-1,1): piece('Nostrils','nostril',(s*.22,2.102,3.32),(.075,.028,.05),shape='sphere')
# Three plush lobes, with a gentle rise toward the crown.
piece('Comb','red',(0,.34,4.54),(.36,1.80,.36),bevel=.16)
for y,z,sy,sz in [(1.02,4.51,.50,.67),(.43,4.70,.68,.92),(-.27,4.67,.67,.83)]:
    piece('Comb','red',(0,y,z),(.39,sy,sz),bevel=.18)
piece('CombGlow','redlight',(-.10,.47,4.99),(.17,.41,.18),bevel=.075)
for s in (-1,1): piece('Wattle','red',(s*.15,1.46,2.77),(.30,.30,.54),shape='sphere',rot=(0,s*.18,s*.15))
# Each complete wing is joined to one mesh, pivoted at the shoulder for animation.
for s,side in [(-1,'L'),(1,'R')]:
    wing='Wing'+side
    piece(wing,'white',(s*1.47,-.11,2.12),(.49,1.77,1.70),bevel=.23,rot=(0,-s*.13,0))
    for j in range(3):
        piece(wing,'white',(s*1.53,.42-j*.43,1.62-j*.025),(.45,.62,.77),bevel=.20,rot=(0,-s*.12,-s*.10))
    # Raised square feather accents echo studs without copying the reference mesh.
    for y,z in [(.33,2.41),(-.34,2.55),(-.69,2.00)]:
        piece(wing,'white',(s*1.736,y,z),(.105,.35,.34),bevel=.045)
    foot='Foot'+side
    piece(foot,'foot',(s*.72,.06,.41),(.30,.38,.64),bevel=.12)
    piece(foot,'foot',(s*.72,.36,.17),(.80,1.02,.30),bevel=.13)
    for j in range(3): piece(foot,'foot',(s*.72+(j-1)*.24,.91,.15),(.20,.55,.25),bevel=.095,rot=(0,0,(j-1)*-.13))
# Small fan tail, separate and animated as a single rigid part.
for x,y,z,rx,ry in [(-.48,-1.43,2.26,-.40,-.28),(0,-1.65,2.47,-.52,0),(.48,-1.43,2.26,-.40,.28)]:
    piece('Tail','white',(x,y,z),(.64,1.0,1.02),bevel=.28,rot=(rx,ry,0))
for s in (-1,1):
    for x,z in [(s*.98,2.31),(s*1.08,1.22),(s*.57,.88)]:
        piece('FeatherTiles','feather',(x,1.226,z),(.33,.085,.29),bevel=.042)
# Two subtle forehead feather pads, leaving the eyes unobstructed.
for s in (-1,1): piece('Forehead','white',(s*.57,1.42,4.31),(.44,.10,.28),bevel=.065)

parts=[]
pivots={'WingL':(-1.32,-.12,2.67),'WingR':(1.32,-.12,2.67),
        'FootL':(-.72,.06,.62),'FootR':(.72,.06,.62),'Tail':(0,-1.15,2.1),'Body':(0,0,0)}
for (name,color),objects in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    if len(objects)>1: bpy.ops.object.join()
    obj=bpy.context.object; obj.name=name
    if name in pivots: scene.cursor.location=pivots[name]
    else: scene.cursor.location=obj.location
    enum_set(scene.tool_settings,'transform_pivot_point','MEDIAN_POINT')
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    obj['ETColor']=list(palette[color]);obj['ETGlow']=False; obj['RigPart']=name
    parts.append(obj)
scene.cursor.location=(0,0,0)

# Friendly turntable setup, kept out of FBX/geometry exports.
def light(name, pos, energy, size, color):
    data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.shape='DISK';data.size=size;data.color=color
    obj=bpy.data.objects.new(name,data);stage.objects.link(obj);obj.location=pos
    obj.rotation_euler=(Vector((0,0,2.4))-obj.location).to_track_quat('-Z','Y').to_euler()
light('Key softbox',(-4,6,8),700,5,(1,.91,.82))
light('Fill softbox',(5,4,5),450,4,(.74,.84,1))
light('Rim softbox',(2,-5,7),900,4,(1,.84,.64))
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.025))
floor=bpy.context.object;floor.name='PresentationGround';move_to(floor,stage)
mat=bpy.data.materials.new('Mint backdrop');mat.use_nodes=True
next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'].default_value=(.14,.26,.25,1)
floor.data.materials.append(mat)
camdata=bpy.data.cameras.new('Galinha portrait');enum_set(camdata,'type','ORTHO');camdata.ortho_scale=7.3
cam=bpy.data.objects.new('Galinha portrait',camdata);stage.objects.link(cam);cam.location=(8,12,7)
cam.rotation_euler=(Vector((0,.0,2.5))-cam.location).to_track_quat('-Z','Y').to_euler();scene.camera=cam
scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'GalinhaFofa.png')
try: enum_set(scene.view_settings,'view_transform','AgX')
except AssertionError: pass
scene.render.film_transparent=False

# Export accurate smooth split normals as well as the canonical geometry.
B=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
def rounded(v): return [round(float(x),6) for x in v]
meshdefs={};arr=[]
for obj in parts:
    me=obj.data;me.calc_loop_triangles()
    pts=[B@v.co for v in me.vertices]
    lo=Vector([min(p[k] for p in pts) for k in range(3)]);hi=Vector([max(p[k] for p in pts) for k in range(3)])
    center=(lo+hi)*.5
    ns=[]; normalmap={};tris=[];tn=[]
    for tri in me.loop_triangles:
        a,b,c=[Vector(rounded(pts[v]-center)) for v in tri.vertices]
        if (b-a).cross(c-a).length_squared<=1e-15: continue
        tris.append([int(v)+1 for v in tri.vertices]);ids=[]
        for loop in tri.loops:
            normal=tuple(rounded((B@me.corner_normals[loop].vector).normalized()))
            if normal not in normalmap:normalmap[normal]=len(ns)+1;ns.append(list(normal))
            ids.append(normalmap[normal])
        tn.append(ids)
    key='Chicken_'+obj.name
    meshdefs[key]={'Vertices':[rounded(p-center) for p in pts],'Triangles':tris,
                   'Normals':ns,'TriangleNormals':tn,'Size':rounded(hi-lo),'Center':rounded(center)}
    rot=obj.rotation_euler.to_matrix();pos=obj.location+rot@(B.transposed()@center)
    rp=B@rot@B.transposed();p=B@pos
    arr.append({'Name':obj.name,'Mesh':key,'CF':rounded(list(p)+[rp[i][j] for i in range(3) for j in range(3)]),
                'Scale':[1,1,1],'Color':list(obj['ETColor']),'Glow':False})

patch={'Meshes':meshdefs,'Models':{'Species_1':arr},'Revision':'galinha-fofa-2026-10-23'}
adult=json.loads(json.dumps(arr))
for row in adult:
    row['CF'][:3]=[x*2 for x in row['CF'][:3]];row['Scale']=[2,2,2]
patch['Models']['Guardian_1']=adult
(OUT/'chicken_geometry.json').write_text(json.dumps(patch,separators=(',',':')),encoding='utf-8')
original=json.loads((base/'geometry.json').read_text(encoding='utf-8'))
original['Meshes'].update(meshdefs);original['Models'].update(patch['Models']);original['Revision']=patch['Revision']
original.setdefault('ModelRevisions',{}).update({'Species_1':patch['Revision'],'Guardian_1':patch['Revision']})
(base/'geometry.json').write_text(json.dumps(original,separators=(',',':')),encoding='utf-8')
bridge={'__name__':'chicken_export_bridge'}
exec(compile((OUT/'export_bridge.py').read_text(encoding='utf-8'),str(OUT/'export_bridge.py'),'exec'),bridge)
bridge['write_bridge'](base/'geometry.json')
for name,scale in [('Species_1',1),('Guardian_1',2)]:
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts: obj.select_set(True);obj.location*=scale;obj.scale*=scale
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,apply_unit_scale=True,
                             axis_forward='-Z',axis_up='Y',add_leaf_bones=False,bake_anim=False)
    for obj in parts: obj.location/=scale;obj.scale/=scale
    (base/(name+'.fbx')).write_bytes((OUT/(name+'.fbx')).read_bytes())
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active=next(o for o in parts if o.name=='Body')
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_distance=10
        area.spaces.active.region_3d.view_location=(0,0,2.5)
        area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
        area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'GalinhaFofa.blend'))
stats={'parts':len(parts),'meshes':len(meshdefs),'vertices':sum(len(m['Vertices']) for m in meshdefs.values()),
       'triangles':sum(len(m['Triangles']) for m in meshdefs.values()),'source':'build_chicken.py',
       'species':1,'revision':patch['Revision']}
(OUT/'model_info.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
print(json.dumps(stats))
