"""Original colossal forest owl, angular toy geometry and physical square studs."""
import bpy, bmesh, math, json, random
from pathlib import Path
from mathutils import Vector, Matrix

OUT=Path(globals().get('OWL_OUT') or Path(__file__).resolve().parent)
OUT.mkdir(parents=True,exist_ok=True)
previous=bpy.data.scenes.get('CorujaGuardia')
if previous and globals().get('OWL_REBUILD'):
    for o in list(previous.objects):bpy.data.objects.remove(o,do_unlink=True)
    cols=list(previous.collection.children);bpy.data.scenes.remove(previous)
    for co in cols:bpy.data.collections.remove(co)
elif previous:raise RuntimeError('Preserve the current owl before setting OWL_REBUILD=True.')
scene=bpy.data.scenes.new('CorujaGuardia')
bpy.context.window.scene=scene
root=bpy.data.collections.new('CorujaGuardia_Modelo');scene.collection.children.link(root)
stage=bpy.data.collections.new('CorujaGuardia_Apresentacao');scene.collection.children.link(stage)
palette={'pine':(.012,.052,.025),'forest':(.035,.135,.049),'leaf':(.13,.245,.067),
 'moss':(.23,.345,.092),'sage':(.43,.385,.21),'ivory':(.76,.66,.38),
 'gold':(1,.61,.08),'goldshade':(.70,.31,.025),'ink':(.012,.038,.04),
 'amber':(1,.57,.035),'light':(1,.97,.74),'claw':(.91,.88,.73)}
materials={}
for key,c in palette.items():
    m=bpy.data.materials.new('Owl_'+key);m.diffuse_color=(*c,1);m.use_nodes=True
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    n.inputs['Base Color'].default_value=(*c,1);n.inputs['Roughness'].default_value=.48
    if key=='amber':
        n.inputs['Emission Color'].default_value=(*c,1);n.inputs['Emission Strength'].default_value=.75
    materials[key]=m
groups={};pivots={}
def put(o,group,color):
    for co in list(o.users_collection):co.objects.unlink(o)
    root.objects.link(o);o.data.materials.append(materials[color]);groups.setdefault((group,color),[]).append(o)
    return o
def box(group,color,loc,size,rot=(0,0,0),bevel=.06):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if max(size)<.42:bevel=0
    if bevel:
        b=o.modifiers.new('Tiny manufactured edge','BEVEL');b.width=bevel;b.segments=1
        bpy.ops.object.modifier_apply(modifier=b.name)
    o.rotation_euler=rot
    return put(o,group,color)
def mesh(group,color,verts,faces):
    m=bpy.data.meshes.new('OwlPlate');m.from_pydata(verts,[],faces);m.update()
    o=bpy.data.objects.new('OwlPart',m);root.objects.link(o);m.materials.append(materials[color]);groups.setdefault((group,color),[]).append(o)
    return o
def prism(group,color,outline,y,depth):
    area=sum(outline[i][0]*outline[(i+1)%len(outline)][1]-outline[(i+1)%len(outline)][0]*outline[i][1] for i in range(len(outline)))
    if area>0:outline=list(reversed(outline))
    verts=[(x,y+depth/2,z) for x,z in outline]+[(x,y-depth/2,z) for x,z in outline]
    n=len(outline);faces=[tuple(range(n)),tuple(range(2*n-1,n-1,-1))]
    faces.extend((i,i+n,(i+1)%n+n,(i+1)%n) for i in range(n))
    return mesh(group,color,verts,faces)
def leaf(group,color,a,b,width,thick=.40,stud=False):
    a=Vector(a);b=Vector(b);d=b-a
    perp=Vector((-d.z,0,d.x)).normalized()*width/2
    outline=[a-perp*.65,a+perp*.65,a+d*.31+perp,a+d*.76+perp*.68,b,
             a+d*.76-perp*.68,a+d*.31-perp]
    verts=[tuple(p+Vector((0,thick/2,0))) for p in outline]+[tuple(p-Vector((0,thick/2,0))) for p in outline]
    ridge=a+d*.43+Vector((0,thick*.82,0));verts.append(tuple(ridge));n=len(outline)
    faces=[(14,i,(i+1)%n) for i in range(n)]+[tuple(range(13,6,-1))]
    faces.extend((i,i+7,(i+1)%n+7,(i+1)%n) for i in range(n))
    mesh(group,color,verts,faces)
    if stud:
        for t in (.18,.42,.65):
            for s in (-1,1):
                p=a+d*t+perp*(s*.38)+Vector((0,thick*.69+.055,0))
                box(group,color,p,(.30,.11,.30),bevel=.012)
    return (a,b)
def disc(group,color,loc,r,depth,vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc,rotation=(math.pi/2,0,0))
    return put(bpy.context.object,group,color)
def grid(group,color,xrange,zrange,y,step=1.08,size=.31):
    for x in xrange:
        for z in zrange:box(group,color,(x,y,z),(size,.095,size),bevel=.008)

# Broad, crouched owl beast: all measurements are adult Roblox studs.
def bulk(group,color,center,rings,sides=12):
    verts=[]
    for z,rx,ry,cy in rings:
        for j in range(sides):
            a=2*math.pi*j/sides
            verts.append((center[0]+rx*math.cos(a),center[1]+cy+ry*math.sin(a),center[2]+z))
    faces=[tuple(range(sides-1,-1,-1)),tuple(range((len(rings)-1)*sides,len(rings)*sides))]
    for k in range(len(rings)-1):
        for j in range(sides):faces.append((k*sides+j,k*sides+(j+1)%sides,(k+1)*sides+(j+1)%sides,(k+1)*sides+j))
    return mesh(group,color,verts,faces)

def folded_feather(group,color,a,b,width,thick,side,studded=True):
    a=Vector(a);b=Vector(b);d=b-a;n=Vector((side,0,0))
    across=d.cross(n).normalized()*width/2
    pts=[a-across*.6,a+across*.6,a+d*.3+across,a+d*.76+across*.65,b,
         a+d*.76-across*.65,a+d*.3-across]
    verts=[tuple(p+n*thick/2) for p in pts]+[tuple(p-n*thick/2) for p in pts]
    verts.append(tuple(a+d*.42+n*thick*.9))
    faces=[(14,j,(j+1)%7) for j in range(7)]+[tuple(range(13,6,-1))]
    faces.extend((j,j+7,(j+1)%7+7,(j+1)%7) for j in range(7))
    mesh(group,color,verts,faces)
    if studded:
        for t in (.18,.42,.65):
            for sign in (-1,1):
                p=a+d*t+across*(sign*.38)+n*(thick*.72+.055)
                box(group,color,p,(.12,.36,.36),bevel=0)

bulk('Body','pine',(0,0,0),[(6,3.8,3.4,-1.7),(8,6.7,5.8,-1.7),(12,7.8,6.8,-1.7),
     (17,7.5,6.6,-1.6),(20.1,5.8,5.0,-1.4),(21.5,2.8,2.8,-1.1)])
head=[(-5.6,16.6),(-7.4,18.6),(-7.4,24.0),(-4.9,26.2),(0,27.0),
      (4.9,26.2),(7.4,24.0),(7.4,18.6),(5.6,16.6),(0,14.9)]
prism('Head','forest',head,3.4,9.6)
for side in (-1,1):
    for y in (0,1.2,2.4,3.6,4.8,6.0,7.2):
        for z in (19.2,20.4,21.6,22.8):
            box('HeadStuds','forest',(side*7.43,y,z),(.10,.36,.36),bevel=0)
# Dense crown studs over a solid skull, rather than decorative jewellery.
grid('HeadStuds','forest',[-5.2,-3.9,-2.6,-1.3,0,1.3,2.6,3.9,5.2],[24.6,25.5],8.23,size=.36)
face=[(-6.5,23.6),(-4.8,25),(-2.8,24.7),(0,23.15),(2.8,24.7),(4.8,25),
      (6.5,23.6),(6.0,20),(3.5,17.8),(0,16),(-3.5,17.8),(-6,20)]
prism('FaceDisk','sage',face,8.42,.62)
for s,side in [(-1,'L'),(1,'R')]:
    # Horn-like ear tufts sweep back; the head leans forward over the talons.
    for j,(x,z,w) in enumerate([(8.4,31.7,3.1),(6.5,30.0,2.7),(9.2,28.7,2.45)]):
        leaf('EarTufts'+side,'pine' if j==0 else 'forest',(s*5.0,.7-j*.7,23.3),
             (s*x,-2.0-j*.8,z),w,1.2,True)
    leaf('EarSpine'+side,'moss',(s*5.2,1.35,24.1),(s*8.1,-1.1,30.8),.65,.25)
    # Large sunken sockets with small, piercing illuminated irises.
    disc('EyeSockets','ink',(s*3.25,8.91,21.55),2.75,.45)
    disc('EyeRims','pine',(s*3.25,9.19,21.55),2.05,.20)
    prism('Eyes','amber',[(s*1.7,21.75),(s*4.95,22.30),(s*4.70,20.85),(s*2.0,21.18)],9.36,.17)
    box('Pupils','ink',(s*3.20,9.52,21.55),(.35,.20,1.15),bevel=0)
    # Thick brows overlap the eye circles and narrow the gaze into a slanted slit.
    poly=[(s*.12,22.5),(s*5.8,25.1),(s*7.1,23.85),(s*5.55,22.65),(s*2.2,20.95)]
    prism('Brow','pine',poly,9.68,.95)
    leaf('BrowRidge','forest',(s*.52,10.23,22.25),(s*6.45,9.7,24.3),.44,.27)
    for j in range(3):
        leaf('FacialRuff','pine' if j<2 else 'leaf',(s*(5.9-j*.55),7.4,22.4-j*1.65),
             (s*(8.2-j*.68),5.8,19.7-j*1.8),2.3,.8,True)
    leaf('JawFeathers','sage',(s*3.45,8.81,19.2),(s*1.18,8.95,16.1),1.8,.4)
    grid('FaceStuds','sage',[s*5.0],[20,22.9],8.77,size=.29)
# A deep hooked raptor beak with a dark, downturned tip.
mesh('Beak','goldshade',[(-1.23,9.0,20.1),(1.23,9.0,20.1),(1.0,11.6,19.0),(-1.0,11.6,19.0),
      (.55,12.55,17.7),(-.55,12.55,17.7),(0,11.9,15.65),(0,9.2,17.0)],
     [(0,1,2,3),(3,2,4,5),(5,4,6),(0,3,5,6,7),(1,7,6,4,2),(0,7,1)])
mesh('BeakRidge','ivory',[(-.34,9.1,20.15),(.34,9.1,20.15),(.28,11.7,19.08),(-.28,11.7,19.08),
      (0,12.64,17.55)],[(0,1,2,3),(3,2,4),(0,3,4),(1,4,2)])
for s in (-1,1):box('Nostrils','ink',(s*.70,11.48,19.18),(.25,.12,.18),bevel=0)
# The neck and chest are a dense ruff of short, overlapping feathers.
for row,columns in enumerate([[-2,-1,0,1,2],[-1.5,-.5,.5,1.5],[-2,-1,0,1,2],[-1.5,-.5,.5,1.5],[-1,0,1]]):
    z=17.4-row*2.1
    for col in columns:
        x=col*(2.1 if row<3 else 1.95)
        y=5.90-abs(x)*.055
        color='sage' if abs(col)<.6 else 'leaf' if row%2 else 'forest'
        leaf('ChestPlumage',color,(x,y,z),(x+col*.08,y+.27,z-3.25+abs(col)*.20),2.65,.64,True)
for s in (-1,1):
    for j in range(4):
        leaf('NeckRuff','pine' if j%2 else 'forest',(s*(1+j*1.6),4.9,19.1-j*.3),
             (s*(1.25+j*1.9),5.15,15.4-j*.55),2.9,.75,True)
    for j in range(3):
        leaf('FlankPlumage','leaf',(s*6.55,3.5,15.5-j*2.7),(s*7.15,3.0,12.1-j*2.7),2.5,.75,True)
# The wings are tightly folded on the flanks. Nothing reads as an outstretched arm.
for s,side in [(-1,'L'),(1,'R')]:
    prefix='Wing'+side;pivots[prefix]=(s*5.8,-.1,18.3)
    bulk(prefix+'_Mass','pine',(s*6.3,-.2,0),[(5.3,1.0,2.0,-3.0),(8.0,2.6,4.4,-2.1),
         (12.4,3.25,5.6,-1.0),(16.8,3.0,4.9,.0),(19.2,1.7,3.0,.3)])
    for j in range(5):
        a=(s*(8.55-j*.13),3.0-j*1.72,17.7-j*.25)
        b=(s*(8.15-j*.19),-3.5-j*.60,4.8+j*.25)
        folded_feather(prefix+'_Flight','forest' if j%2 else 'leaf',a,b,2.35,.75,s)
    for row in range(2):
        for j in range(4):
            a=(s*9.20,2.7-j*1.9,18.0-row*3.1)
            b=(s*9.55,1.4-j*1.9,13.5-row*3.15)
            folded_feather(prefix+'_Coverts','forest' if (j+row)%2 else 'moss',a,b,2.85,.80,s)
    for j in range(3):
        folded_feather(prefix+'_Shoulder','pine' if j%2 else 'forest',(s*8.55,2.4-j*2.5,19.4),
                       (s*10.05,1.0-j*2.5,15.7),3.0,.85,s)
# Heavy legs and broad feet; the six long ivory claws create the predator silhouette.
for s,side in [(-1,'L'),(1,'R')]:
    prefix='Foot'+side;pivots[prefix]=(s*4.1,.6,5.4)
    box(prefix+'_Leg','pine',(s*4.1,.35,4.9),(4.3,5.0,6.9),bevel=.60)
    box(prefix+'_Pad','forest',(s*4.1,3.0,1.65),(5.9,7.8,2.85),bevel=.50)
    for j in range(3):
        x=s*4.1+(j-1)*1.8
        box(prefix+'_Toes','forest',(x,6.75,1.12),(1.48,4.1,1.65),bevel=.18)
        mesh(prefix+'_Claws','claw',[(x-.64,8.05,1.95),(x+.64,8.05,1.95),(x+.46,10.25,1.31),
             (x-.46,10.25,1.31),(x,11.45,.0),(x,8.4,.35)],
             [(0,1,2,3),(0,3,4,5),(1,5,4,2),(3,2,4),(0,5,1)])
    for j in range(3):
        leaf(prefix+'_FeatherArmor','leaf' if j==1 else 'forest',(s*4.1+(j-1)*1.2,3.8,8.0),
             (s*4.1+(j-1)*1.5,4.5,3.8),2.0,.65,True)
    grid(prefix+'_Studs','forest',[s*4.1-1.8,s*4.1,s*4.1+1.8],[1.6],6.99,size=.40)
pivots['Tail']=(0,-5.0,9.0)
for j in range(5):
    x=(j-2)*1.6
    leaf('Tail','forest' if j%2 else 'pine',(x*.6,-5.7,11.0),(x*1.6,-10.9,2.9+abs(j-2)*.55),2.8,.72,True)


# Join by rigid anatomy and colour. Prefixes keep linked feather layers on one joint.
parts=[]
for (name,color),objects in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    if len(objects)>1:bpy.ops.object.join()
    o=bpy.context.object;o.name='Owl_'+name+'_'+color
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(o.data);bm.free();o.data.update()
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    prefix=next((p for p in pivots if name.startswith(p)),None)
    scene.cursor.location=pivots[prefix] if prefix else (0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    o['ETName']=name+'_'+color if name!='Body' else 'Body'
    o['ETColor']=list(palette[color]);o['ETGlow']=color=='amber'
    if prefix:o['AnimJoint']=list(pivots[prefix])
    parts.append(o)
scene.cursor.location=(0,0,0)

# Presentation scene and a five-stud scale marker.
world=bpy.data.worlds.new('Owl dusk studio');world.use_nodes=True;scene.world=world
bg=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs['Color'].default_value=(.10,.16,.19,1);bg.inputs['Strength'].default_value=.40
def stage_obj(o):
    for co in list(o.users_collection):co.objects.unlink(o)
    stage.objects.link(o);return o
def lamp(name,loc,energy,size,color):
    d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.size=size;d.color=color
    o=bpy.data.objects.new(name,d);stage.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,13))-o.location).to_track_quat('-Z','Y').to_euler()
lamp('Warm giant softbox',(-20,25,40),9000,18,(1,.85,.65))
lamp('Cool fill',(24,14,24),7000,15,(.66,.87,1))
lamp('Golden rim',(5,-19,33),12000,12,(.88,1,.56))
bpy.ops.mesh.primitive_plane_add(size=400,location=(0,0,-.035));floor=stage_obj(bpy.context.object);floor.name='Owl_Backdrop'
fm=bpy.data.materials.new('Owl studio ground');fm.use_nodes=True
next(n for n in fm.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'].default_value=(.052,.10,.095,1);floor.data.materials.append(fm)
camdata=bpy.data.cameras.new('Owl portrait');camdata.type='ORTHO';camdata.ortho_scale=46
cam=bpy.data.objects.new('Owl portrait',camdata);stage.objects.link(cam);cam.location=(36,76,23)
cam.rotation_euler=(Vector((0,0,16))-cam.location).to_track_quat('-Z','Y').to_euler();scene.camera=cam
scene.render.resolution_x=1200;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'CorujaGuardia.png')

# Static geometry bridge. Blender +Y faces forward; Roblox -Z faces forward.
B=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
def rnd(v):return [round(float(x),5) for x in v]
meshdefs={};model=[]
for o in parts:
    me=o.data;me.calc_loop_triangles();pts=[B@v.co for v in me.vertices]
    lo=Vector([min(p[k] for p in pts) for k in range(3)]);hi=Vector([max(p[k] for p in pts) for k in range(3)]);center=(lo+hi)*.5
    verts=[rnd(p-center) for p in pts];tri=[]
    for t in me.loop_triangles:
        a,b,c=[Vector(verts[i]) for i in t.vertices]
        if (b-a).cross(c-a).length_squared>1e-12:tri.append([int(i)+1 for i in t.vertices])
    key='Owl_'+o['ETName'];meshdefs[key]={'Vertices':verts,'Triangles':tri,'Size':rnd(hi-lo),'Center':rnd(center)}
    pos=B@o.location+center;row={'Name':o['ETName'],'Mesh':key,'CF':rnd(list(pos)+[1,0,0,0,1,0,0,0,1]),'Scale':[1,1,1],
        'Color':[round(12.92*c if c<=.0031308 else 1.055*c**(1/2.4)-.055,5) for c in o['ETColor']],'Glow':bool(o['ETGlow'])}
    if 'AnimJoint' in o:row['Joint']=rnd(B@Vector(o['AnimJoint']))
    if o['ETName'].startswith('Wing'):row['MotionScale']=.3
    model.append(row)
patch={'Meshes':meshdefs,'Models':{'Guardian_2':model},'Revision':'coruja-predadora-2026-10-23'}
(OUT/'owl_geometry.json').write_text(json.dumps(patch,separators=(',',':')),encoding='utf-8')
lib=OUT.parent/'geometry.json';data=json.loads(lib.read_text(encoding='utf-8'))
data['Meshes']={k:v for k,v in data['Meshes'].items() if not k.startswith('Owl_')}
data['Meshes'].update(meshdefs);data['Models'].update(patch['Models']);data['Revision']=patch['Revision']
data.setdefault('ModelRevisions',{})['Guardian_2']=patch['Revision']
data.setdefault('ModelLabelHeights',{})['Guardian_2']=34.0
lib.write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
bridge={'__name__':'owl_export_bridge'}
bridgefile=OUT.parent/'GalinhaFofa/export_bridge.py'
exec(compile(bridgefile.read_text(encoding='utf-8'),str(bridgefile),'exec'),bridge)
bridge['write_bridge'](lib)
jointnames=['WingL','WingR','FootL','FootR','Tail']
stats={'parts':len(parts),'triangles':sum(len(m['Triangles']) for m in meshdefs.values()),
 'vertices':sum(len(m['Vertices']) for m in meshdefs.values()),'height':31.7,'wingspan':21.5,'models':['Guardian_2']}
(OUT/'model_info.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/'Guardian_2.fbx'),use_selection=True,apply_unit_scale=True,axis_forward='-Z',axis_up='Y',add_leaf_bones=False,bake_anim=False)
(OUT.parent/'Guardian_2.fbx').write_bytes((OUT/'Guardian_2.fbx').read_bytes())
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_location=(0,0,13)
        area.spaces.active.region_3d.view_distance=49
        area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
        area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CorujaGuardia.blend'))
print(json.dumps(stats))
