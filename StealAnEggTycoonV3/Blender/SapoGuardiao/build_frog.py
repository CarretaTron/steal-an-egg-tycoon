"""Original colossal swamp toad: low predator stance, webbed paws and layered skin."""
import bpy, bmesh, math, json, random
from pathlib import Path
from mathutils import Vector, Matrix

OUT=Path(globals().get('FROG_OUT') or Path(__file__).resolve().parent)
OUT.mkdir(parents=True,exist_ok=True)
previous=bpy.data.scenes.get('SapoGuardiao')
if previous and globals().get('FROG_REBUILD'):
    for o in list(previous.objects):bpy.data.objects.remove(o,do_unlink=True)
    cols=list(previous.collection.children);bpy.data.scenes.remove(previous)
    for co in cols:bpy.data.collections.remove(co)
elif previous:raise RuntimeError('Preserve the open frog before setting FROG_REBUILD=True.')
scene=bpy.data.scenes.new('SapoGuardiao');bpy.context.window.scene=scene
root=bpy.data.collections.new('SapoGuardiao_Modelo');scene.collection.children.link(root)
stage=bpy.data.collections.new('SapoGuardiao_Apresentacao');scene.collection.children.link(stage)
palette={'skin':(.055,.19,.065),'deep':(.018,.075,.039),'moss':(.27,.40,.095),
 'olive':(.21,.255,.075),'belly':(.40,.365,.16),'wart':(.105,.265,.073),
 'ink':(.008,.016,.014),'mouth':(.035,.004,.033),'gum':(.13,.015,.055),
 'tongue':(.28,.035,.18),'bone':(.83,.76,.47),'purple':(.19,.025,.31),
 'toxin':(.50,.86,.045),'amber':(1,.49,.018),'light':(.96,.92,.52)}
mats={}
for key,c in palette.items():
    m=bpy.data.materials.new('Frog_'+key);m.diffuse_color=(*c,1);m.use_nodes=True
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    n.inputs['Base Color'].default_value=(*c,1)
    n.inputs['Roughness'].default_value=.28 if key in ('skin','deep','purple','mouth','tongue') else .48
    if key in ('amber','toxin'):
        n.inputs['Emission Color'].default_value=(*c,1);n.inputs['Emission Strength'].default_value=.48
    mats[key]=m
groups={};pivots={}
def put(o,group,color):
    for co in list(o.users_collection):co.objects.unlink(o)
    root.objects.link(o);o.data.materials.append(mats[color]);groups.setdefault((group,color),[]).append(o);return o
def box(group,color,loc,size,rot=(0,0,0),bevel=.0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        b=o.modifiers.new('Angular soft edge','BEVEL');b.width=bevel;b.segments=1;bpy.ops.object.modifier_apply(modifier=b.name)
    o.rotation_euler=rot;return put(o,group,color)
def mesh(group,color,verts,faces):
    me=bpy.data.meshes.new('FrogSurface');me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new('FrogPart',me);root.objects.link(o);me.materials.append(mats[color]);groups.setdefault((group,color),[]).append(o);return o
def ellipsoid(group,color,loc,size,rot=(0,0,0),segments=16,rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=loc)
    o=bpy.context.object;o.scale=Vector(size)*.5;o.rotation_euler=rot
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True);return put(o,group,color)
def ico(group,color,loc,size):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=loc);o=bpy.context.object;o.scale=Vector(size)*.5
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return put(o,group,color)
def prism(group,color,outline,y,depth):
    area=sum(outline[i][0]*outline[(i+1)%len(outline)][1]-outline[(i+1)%len(outline)][0]*outline[i][1] for i in range(len(outline)))
    if area>0:outline=list(reversed(outline))
    n=len(outline);vs=[(x,y+depth/2,z) for x,z in outline]+[(x,y-depth/2,z) for x,z in outline]
    fs=[tuple(range(n)),tuple(range(2*n-1,n-1,-1))]+[(i,i+n,(i+1)%n+n,(i+1)%n) for i in range(n)]
    return mesh(group,color,vs,fs)
def tube(group,color,points,radius,sides=8):
    points=[Vector(p) for p in points];vs=[]
    for i,p in enumerate(points):
        d=(points[min(i+1,len(points)-1)]-points[max(i-1,0)]).normalized()
        ref=Vector((0,0,1)) if abs(d.z)<.85 else Vector((0,1,0));u=d.cross(ref).normalized();v=d.cross(u).normalized()
        r=radius[i] if isinstance(radius,(list,tuple)) else radius
        for k in range(sides):vs.append(tuple(p+r*(u*math.cos(2*math.pi*k/sides)+v*math.sin(2*math.pi*k/sides))))
    fs=[tuple(range(sides-1,-1,-1)),tuple(range((len(points)-1)*sides,len(points)*sides))]
    for j in range(len(points)-1):
        for k in range(sides):fs.append((j*sides+k,j*sides+(k+1)%sides,(j+1)*sides+(k+1)%sides,(j+1)*sides+k))
    return mesh(group,color,vs,fs)
def tooth(group,color,base,tip,width):
    a=Vector(base);b=Vector(tip);bend=a+(b-a)*.62+Vector((0,.35,0))
    return tube(group,color,[a,bend,b],[width,width*.56,.015],sides=5)
def stud(group,color,pos,normal=(0,0,1),size=.40):
    n=Vector(normal).normalized();rot=n.to_track_quat('Z','Y').to_euler()
    box(group,color,Vector(pos)+n*.07,(size,size,.13),rot=rot)

# Broad barrel-shaped torso and thick throat, supported by four planted limbs.
ellipsoid('Body','skin',(0,-3.1,9.6),(24.0,26.0,17.8),segments=20,rings=10)
ellipsoid('Throat','belly',(0,6.0,3.0),(19.6,10.8,5.8),segments=16,rings=8)
upper=[(-12.0,8.5),(-12.2,13.0),(-9.6,16.8),(-4.2,18.1),(0,18.4),(4.2,18.1),
       (9.6,16.8),(12.2,13.0),(12.0,8.5),(9.5,11.4),(4.4,12.8),(0,13.25),(-4.4,12.8),(-9.5,11.4)]
prism('Head','skin',upper,9.0,9.6)
ellipsoid('Jaw','olive',(0,9.4,3.45),(23.4,12.4,4.5),segments=20,rings=8)
# Open, recessed mouth bowl. The lining is a separate two-sided visual surface.
outline=[(11.5*math.cos(2*math.pi*k/24),8.4+4.65*math.sin(2*math.pi*k/24)) for k in range(24)]
vs=[]
for scale,y in [(1,14.0),(.78,12.3),(.40,11.2)]:
    vs.extend((x*scale,y,8.4+(z-8.4)*scale) for x,z in outline)
vs.append((0,10.6,8.4));fs=[]
for ring in range(2):
    for k in range(24):fs.append((ring*24+k,ring*24+(k+1)%24,(ring+1)*24+(k+1)%24,(ring+1)*24+k))
for k in range(24):fs.append((48+k,48+(k+1)%24,72))
mesh('MouthCavity','mouth',vs,fs)
toplip=[(-11.7,14.25,8.6),(-10.6,14.45,10.7),(-7.4,14.65,12.1),(-3.7,14.8,12.8),(0,14.85,13.1),
        (3.7,14.8,12.8),(7.4,14.65,12.1),(10.6,14.45,10.7),(11.7,14.25,8.6)]
bottomlip=[(-11.7,14.25,8.6),(-10.7,14.7,6.4),(-7.6,15.2,4.6),(-3.8,15.45,3.95),(0,15.55,3.8),
           (3.8,15.45,3.95),(7.6,15.2,4.6),(10.7,14.7,6.4),(11.7,14.25,8.6)]
tube('UpperLip','moss',toplip,.67)
tube('LowerLip','olive',bottomlip,.93)
tube('UpperGum','gum',[(x,y-.25,z-.44) for x,y,z in toplip],.34)
tube('LowerGum','gum',[(x,y-.15,z+.50) for x,y,z in bottomlip],.35)
ellipsoid('Tongue','tongue',(0,13.1,5.05),(6.6,5.0,1.15),segments=12,rings=6)
for j in range(13):
    x=-9.3+j*1.55;z=12.9-abs(x)**1.7*.028
    length=1.1+(j%3)*.30
    tooth('UpperTeeth','bone',(x,14.65,z),(x*.97,14.95,z-length),.30)
for s in (-1,1):
    tooth('UpperFangs','bone',(s*8.9,14.3,11.4),(s*8.0,15.6,7.45),.62)
for j in range(11):
    x=-8.0+j*1.6;z=4.15+abs(x)**1.6*.048
    tooth('LowerTeeth','bone',(x,15.08,z),(x*.97,15.22,z+1.1+(j%2)*.42),.29)
# Raised amphibian eye bulges with heavy horned lids and bright hunting eyes.
for s,side in [(-1,'L'),(1,'R')]:
    ellipsoid('EyeMounds','skin',(s*7.2,8.15,17.0),(7.2,7.1,8.1),segments=12,rings=8)
    prism('EyeSockets','deep',[(s*4.65,18.8),(s*8.9,20.15),(s*9.5,17.1),(s*5.35,16.3)],11.65,.38)
    prism('Eyes','amber',[(s*5.12,18.55),(s*8.65,19.45),(s*8.77,17.35),(s*5.70,16.95)],11.96,.16)
    box('Pupils','ink',(s*7.0,12.12,18.06),(.44,.13,1.84))
    # A thick wedge makes the brow part of the skull, rather than a drawn eyebrow.
    prism('Brow','deep',[(s*4.30,19.25),(s*8.20,22.55),(s*10.1,20.3),(s*8.9,19.4),(s*5.75,18.4)],11.95,.95)
    tooth('EyeHorn','moss',(s*7.9,8.7,19.9),(s*9.6,6.9,23.0),1.32)
    ellipsoid('NostrilRidge','moss',(s*2.65,13.3,15.9),(3.7,3.1,1.7),segments=12,rings=6)
    box('Nostrils','ink',(s*2.65,14.77,16.10),(.66,.16,.36),rot=(0,s*.08,s*.12))
    for x,z in [(s*5.0,15.5),(s*7.3,14.8),(s*9.25,13.9)]:stud('Head','skin',(x,13.84,z),(0,1,0),.42)
for x in (-9.5,-8,-6.5,-5,-3.5,-2,-.5,1,2.5,4,5.5,7,8.5):
    for z in (14.2,15.35,16.5):stud('Head','skin',(x,13.85,z),(0,1,0),.38)
# Thick front forearms end in four spread, webbed digits with flat toe pads.
for s,side in [(-1,'L'),(1,'R')]:
    g='FrontLeg'+side;pivots[g]=(s*9.0,6.3,10.2)
    ellipsoid(g,'skin',(s*11.4,7.7,7.6),(7.0,8.0,11.4),rot=(0,-s*.27,s*.08),segments=12,rings=8)
    ellipsoid(g,'skin',(s*14.0,10.8,4.25),(6.0,9.0,6.7),rot=(-.18,0,s*.12),segments=12,rings=8)
    ellipsoid(g+'Palm','deep',(s*14.25,14.55,1.35),(6.8,7.1,2.4),segments=12,rings=6)
    basepts=[];tips=[]
    for j in range(4):
        x=s*14.25+(j-1.5)*1.64;y=19.65-abs(j-1.5)*.80
        a=(s*14.25+(j-1.5)*.82,15.4,1.22);b=(x,y,.68)
        tube(g+'Digits','skin',[a,((a[0]+b[0])/2,(a[1]+b[1])/2,1.02),b],[.70,.61,.46])
        ellipsoid(g+'Pads','moss',(x,y,.52),(1.8,1.55,.67),segments=8,rings=6)
        basepts.append(a);tips.append(b)
    for j in range(3):mesh(g+'Web','olive',[basepts[j],tips[j],tips[j+1],basepts[j+1]],[(0,1,2,3)])
    for j in range(3):
        ico(g+'Warts','wart',(s*15.85,10.4-j*.85,5.6+j*.6),(1.1,1.1,.92))
        stud(g,'skin',(s*16.6,10.4-j*.9,4.8+j*.7),(s,.2,.3),.45)
# Huge folded hind legs provide the coiled jumping silhouette of a toad.
for s,side in [(-1,'L'),(1,'R')]:
    g='HindLeg'+side;pivots[g]=(s*8.2,-6.4,9.5)
    ellipsoid(g,'skin',(s*11.6,-7.5,7.7),(12.2,14.0,13.1),rot=(0,s*.11,s*.14),segments=16,rings=8)
    ellipsoid(g+'Shin','deep',(s*12.9,-11.3,3.2),(8.5,13.6,5.3),rot=(0,0,-s*.18),segments=12,rings=6)
    ellipsoid(g+'Foot','skin',(s*14.7,-10.4,1.45),(7.8,11.5,2.8),rot=(0,0,-s*.35),segments=12,rings=6)
    basepts=[];tips=[]
    for j in range(5):
        a=(s*(14.7+j*.35),-8.4+j*.65,1.22)
        b=(s*(19.1+math.sin(j*.58)*1.25),-10.4+j*2.45,.51)
        tube(g+'Digits','skin',[a,((a[0]+b[0])/2,(a[1]+b[1])/2,.95),b],[.67,.56,.38])
        ellipsoid(g+'Pads','moss',b,(1.65,1.65,.68),segments=8,rings=6)
        basepts.append(a);tips.append(b)
    for j in range(4):mesh(g+'Web','olive',[basepts[j],tips[j],tips[j+1],basepts[j+1]],[(0,1,2,3)])
    for j in range(4):
        ico(g+'Warts','wart',(s*(13.8+(j%2)*.7),-4.6-j*1.8,11.9-j*.3),(1.5,1.6,1.25))
        stud(g,'skin',(s*15.7,-5.6-j*1.6,9.2),(s,0,.2),.45)
# Layered dorsal ridges, geometric skin studs, warts and restrained mutation glands.
rng=random.Random(33)
for x in (-7.8,-5.2,-2.6,0,2.6,5.2,7.8):
    for y in (-12,-9.4,-6.8,-4.2,-1.6,1.0):
        q=1-(x/12)**2-((y+3.1)/13)**2
        if q>.08:
            z=9.6+8.9*math.sqrt(q)
            n=Vector((x/144,(y+3.1)/169,(z-9.6)/(8.9**2))).normalized()
            stud('Body','skin',(x,y,z),n,.43)
            if rng.random()<.68:ico('DorsalWarts','wart',(x+.55,y-.55,z+.17),(1.2,1.1,.78))
for s in (-1,1):
    tube('DorsalRidge','moss',[(s*3.3,-13,13.1),(s*4.2,-9.5,16.0),(s*4.35,-5.2,18.0),(s*4.05,-.5,17.4),(s*4.8,3,16.1)],[.55,.66,.78,.72,.52])
    for j in range(3):
        pos=(s*(9.7-j*.30),-3.0-j*2.4,14.0+j*.15)
        ico('MutationGlands','purple',pos,(2.7-j*.35,2.3-j*.25,1.9-j*.20))
        ico('ToxinPearls','toxin',Vector(pos)+Vector((0,0,.65)),(.72,.70,.60))
    for j in range(4):
        ico('CheekWarts','wart',(s*(10.2+.32*(j%2)),10.0-j*.7,13.6+j*.5),(1.4,1.2,1.1))

# Join by rigid anatomy and color; fix winding before generating static Roblox content.
parts=[]
for (name,color),objects in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    if len(objects)>1:bpy.ops.object.join()
    o=bpy.context.object;o.name='Frog_'+name+'_'+color
    if name=='MouthCavity' or name.endswith('Web'):
        mod=o.modifiers.new('Solid membrane','SOLIDIFY');mod.thickness=.10;mod.offset=0
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    prefix=next((p for p in pivots if name.startswith(p)),None)
    scene.cursor.location=pivots[prefix] if prefix else (0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    o['ETName']='Body' if name=='Body' else name+'_'+color;o['ETColor']=list(palette[color]);o['ETGlow']=color in ('amber','toxin')
    if prefix:o['AnimJoint']=list(pivots[prefix])
    parts.append(o)
bpy.context.view_layer.update()
ground=min((o.matrix_world@v.co).z for o in parts for v in o.data.vertices)
for o in parts:
    o.location.z-=ground
    if 'AnimJoint' in o:
        p=list(o['AnimJoint']);p[2]-=ground;o['AnimJoint']=p
scene.cursor.location=(0,0,0)

# Dark studio presentation highlights the wet skin and massive low silhouette.
world=bpy.data.worlds.new('Swamp studio');world.use_nodes=True;scene.world=world
bg=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs['Color'].default_value=(.10,.15,.13,1);bg.inputs['Strength'].default_value=.4
def stage_obj(o):
    for co in list(o.users_collection):co.objects.unlink(o)
    stage.objects.link(o);return o
def lamp(name,loc,power,size,color):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.size=size;d.color=color
    o=bpy.data.objects.new(name,d);stage.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,1,9))-o.location).to_track_quat('-Z','Y').to_euler()
lamp('Swamp key',(-26,30,39),14000,22,(1,.85,.61))
lamp('Cool broad fill',(30,18,27),12000,20,(.65,.88,1))
lamp('Toxic rim',(-3,-28,31),18000,15,(.78,1,.46))
bpy.ops.mesh.primitive_plane_add(size=400,location=(0,0,-.055));floor=stage_obj(bpy.context.object);floor.name='SwampBackdrop'
fm=bpy.data.materials.new('Swamp background');fm.use_nodes=True
next(n for n in fm.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'].default_value=(.045,.075,.055,1);floor.data.materials.append(fm)
camdata=bpy.data.cameras.new('Frog portrait');valid={i.identifier for i in camdata.bl_rna.properties['type'].enum_items};assert 'ORTHO' in valid;camdata.type='ORTHO';camdata.ortho_scale=57
cam=bpy.data.objects.new('Frog portrait',camdata);stage.objects.link(cam);cam.location=(43,70,32);cam.rotation_euler=(Vector((0,1,10))-cam.location).to_track_quat('-Z','Y').to_euler();scene.camera=cam
scene.render.resolution_x=1400;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'SapoGuardiao.png')

B=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
def rnd(v):return [round(float(x),5) for x in v]
meshes={};model=[]
for o in parts:
    me=o.data;me.calc_loop_triangles();pts=[B@v.co for v in me.vertices]
    lo=Vector([min(p[k] for p in pts) for k in range(3)]);hi=Vector([max(p[k] for p in pts) for k in range(3)]);center=(lo+hi)*.5
    verts=[rnd(p-center) for p in pts];tri=[]
    for t in me.loop_triangles:
        a,b,c=[Vector(verts[i]) for i in t.vertices]
        if (b-a).cross(c-a).length_squared>1e-12:tri.append([int(i)+1 for i in t.vertices])
    key='Frog_'+o['ETName'];meshes[key]={'Vertices':verts,'Triangles':tri,'Size':rnd(hi-lo),'Center':rnd(center)}
    row={'Name':o['ETName'],'Mesh':key,'CF':rnd(list(B@o.location+center)+[1,0,0,0,1,0,0,0,1]),'Scale':[1,1,1],
         'Color':[round(12.92*c if c<=.0031308 else 1.055*c**(1/2.4)-.055,5) for c in o['ETColor']],'Glow':bool(o['ETGlow'])}
    if 'AnimJoint' in o:row['Joint']=rnd(B@Vector(o['AnimJoint']));row['MotionScale']=.35
    model.append(row)
revision='sapo-colossal-2026-10-23';patch={'Meshes':meshes,'Models':{'Guardian_3':model},'Revision':revision}
(OUT/'frog_geometry.json').write_text(json.dumps(patch,separators=(',',':')),encoding='utf-8')
lib=OUT.parent/'geometry.json';data=json.loads(lib.read_text(encoding='utf-8'));data['Meshes']={k:v for k,v in data['Meshes'].items() if not k.startswith('Frog_')}
data['Meshes'].update(meshes);data['Models'].update(patch['Models']);data['Revision']=revision
data.setdefault('ModelRevisions',{})['Guardian_3']=revision;data.setdefault('ModelLabelHeights',{})['Guardian_3']=25.5
lib.write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
bridge={'__name__':'frog_export_bridge'};bp=OUT.parent/'GalinhaFofa/export_bridge.py'
exec(compile(bp.read_text(encoding='utf-8'),str(bp),'exec'),bridge);bridge['write_bridge'](lib)
stats={'parts':len(parts),'triangles':sum(len(m['Triangles']) for m in meshes.values()),'vertices':sum(len(m['Vertices']) for m in meshes.values()),'model':'Guardian_3'}
(OUT/'model_info.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/'Guardian_3.fbx'),use_selection=True,apply_unit_scale=True,axis_forward='-Z',axis_up='Y',add_leaf_bones=False,bake_anim=False)
(OUT.parent/'Guardian_3.fbx').write_bytes((OUT/'Guardian_3.fbx').read_bytes())
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_location=(0,1,10);area.spaces.active.region_3d.view_distance=65
        area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion();area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'SapoGuardiao.blend'))
print(json.dumps(stats))
