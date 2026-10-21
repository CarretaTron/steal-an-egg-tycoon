"""Original Egg Tycoon models. Run in Blender's Python console or through Blender MCP."""
import bpy, math, json, os
from mathutils import Vector, Matrix

# MCP may pass ET_OUT explicitly; normal script execution exports beside this source.
# Console execution without __file__ uses the currently open .blend's directory.
OUT = os.path.abspath(globals().get('ET_OUT') or (
    os.path.dirname(os.path.abspath(__file__)) if '__file__' in globals()
    else bpy.path.abspath('//') if bpy.data.filepath else os.getcwd()))
os.makedirs(OUT, exist_ok=True)
STAGE = globals().get('ET_STAGE', 'all')
if not os.path.exists(os.path.join(OUT, 'OriginalScene.blend')):
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'OriginalScene.blend'))
old = bpy.data.collections.get('EggTycoonV3')
if old:
    for ob in list(old.all_objects): bpy.data.objects.remove(ob, do_unlink=True)
    for child in list(old.children): bpy.data.collections.remove(child)
    bpy.data.collections.remove(old)
root = bpy.data.collections.new('EggTycoonV3'); bpy.context.scene.collection.children.link(root)
for ob in bpy.context.scene.objects:
    if ob.name in ('Cube', 'Camera', 'Light'): ob.hide_set(True)
materials = {}; prototypes = {}; models = {}; origins = {}
palette = [(1,.76,.12),(.27,.64,.30),(.55,.80,.14),(.73,.43,.19),(.13,.52,.78),(.96,.26,.08),(.52,.15,.84)]
white=(.96,.94,.82); black=(.025,.035,.07); gold=(1,.55,.06); cyan=(.15,.88,1)
def material(color, glow=False):
    key=tuple(round(v,3) for v in color)+(glow,)
    if key not in materials:
        m=bpy.data.materials.new('ET_'+'_'.join(str(round(v*255)) for v in color)+('_Glow' if glow else ''))
        m.diffuse_color=(*color,1); m.use_nodes=True
        n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        n.inputs['Base Color'].default_value=(*color,1); n.inputs['Roughness'].default_value=.62
        if glow:
            if 'Emission Color' in n.inputs: n.inputs['Emission Color'].default_value=(*color,1)
            if 'Emission Strength' in n.inputs: n.inputs['Emission Strength'].default_value=.8
        materials[key]=m
    return materials[key]
def proto(shape):
    if shape in prototypes: return prototypes[shape]
    if shape=='sphere': bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1)
    elif shape=='ico': bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1)
    elif shape=='cube': bpy.ops.mesh.primitive_cube_add(size=2)
    elif shape=='cone': bpy.ops.mesh.primitive_cone_add(vertices=10,radius1=1,radius2=0,depth=2)
    elif shape=='cylinder': bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=1,depth=2)
    elif shape=='wing':
        me=bpy.data.meshes.new('ET_Wing')
        me.from_pydata([(0,0,0),(2.8,-.15,1.8),(3.8,-.3,.1),(2.2,.1,-.2),(1,.2,-.8),(0,.25,0)],[],[(0,1,2),(0,2,3),(0,3,4),(5,2,1),(5,3,2),(5,4,3),(0,5,1),(0,4,5)])
        prototypes[shape]=me; return me
    ob=bpy.context.object; me=ob.data; me.name='ET_'+shape
    bpy.data.objects.remove(ob,do_unlink=True); prototypes[shape]=me; return me
def begin(name, origin):
    co=bpy.data.collections.new(name); root.children.link(co); models[name]=co; origins[name]=Vector(origin); return name
def part(model,name,shape,loc,scale,color,rot=(0,0,0),glow=False):
    ob=bpy.data.objects.new(name,proto(shape)); models[model].objects.link(ob)
    ob.location=Vector(loc)+origins[model]; ob.scale=scale; ob.rotation_euler=rot
    ob.data=ob.data.copy() if False else ob.data
    # Object-linked materials preserve a shared primitive mesh while permitting individual colors.
    if len(ob.data.materials)==0: ob.data.materials.append(material(white))
    ob.material_slots[0].link='OBJECT'; ob.material_slots[0].material=material(color,glow)
    ob['ETColor']=list(color); ob['ETGlow']=glow
    return ob
def eyes(m,x,y,z,r=.27,iris=black):
    for sign in (-1,1):
        part(m,'EyeL' if sign<0 else 'EyeR','sphere',(sign*x,y,z),(r,r*.52,r*1.1),white)
        part(m,'PupilL' if sign<0 else 'PupilR','sphere',(sign*x,y+r*.48,z),(.12,.065,.17),iris)
        part(m,'EyeShine','ico',(sign*x-.045,y+r*.55,z+.06),(.042,.035,.045),(1,1,1))
def cone(m,n,loc,scale,col,rot=(0,0,0),glow=False):return part(m,n,'cone',loc,scale,col,rot,glow)
def make_creature(i):
    c=palette[i-1]; m=begin('Species_'+str(i),((i-1)*11,0,0))
    if i==1:
        part(m,'Body','sphere',(0,0,2),(1.45,1.15,1.6),c)
        part(m,'Head','sphere',(0,.35,3.9),(1.08,1.04,1.03),c); eyes(m,.43,1.25,4.05)
        cone(m,'Beak',(0,1.55,3.65),(.5,.34,.6),gold,(-math.pi/2,0,0))
        for s in (-1,1):
            part(m,'WingL' if s<0 else 'WingR','sphere',(s*1.35,-.1,2.25),(.36,.9,.65),(1,.84,.24),(.12,s*.2,s*.3))
            part(m,'Foot','sphere',(s*.67,.42,.30),(.55,.75,.23),gold)
        for j in range(3): cone(m,'Crest',(j*.26-.26,.1,4.88),(.20,.22,.48),c,(0,(j-1)*.25,0))
    elif i==2:
        part(m,'Body','sphere',(0,0,2.2),(1.5,1.1,1.9),c)
        part(m,'Head','sphere',(0,.18,4),(1.4,1.03,1.1),c)
        for s in (-1,1):
            part(m,'FaceMask','sphere',(s*.57,1.02,4.03),(.65,.25,.73),(.88,.92,.56))
            part(m,'WingL' if s<0 else 'WingR','sphere',(s*1.42,-.1,2.35),(.39,.85,1.15),(.16,.42,.23),(0,s*.15,s*.18))
            cone(m,'EarLeaf',(s*.96,.05,5.08),(.38,.22,.85),(.42,.76,.20),(0,s*.34,0))
            part(m,'Foot','sphere',(s*.6,.3,.28),(.46,.58,.23),gold)
        eyes(m,.57,1.30,4.12,.40,(.27,.15,.02)); cone(m,'Beak',(0,1.55,3.65),(.28,.25,.42),gold,(-math.pi/2,0,0))
        for j in range(3):part(m,'TailLeaf','sphere',((j-1)*.48,-1.1,1.1),(.3,1.1,.16),(.38,.68,.19),(.4,0,(j-1)*.25))
    elif i==3:
        part(m,'Body','sphere',(0,0,1.55),(1.8,1.4,1.15),c)
        part(m,'Head','sphere',(0,.65,2.35),(1.65,1.25,.8),c)
        part(m,'Belly','sphere',(0,1.17,1.6),(1.15,.25,.67),(.86,.93,.45))
        for s in (-1,1):
            part(m,'EyeBulb','sphere',(s*.91,.8,3.10),(.58,.59,.6),c)
            part(m,'HindLegL' if s<0 else 'HindLegR','sphere',(s*1.65,-.6,.75),(.8,.8,.65),(.31,.59,.10))
            part(m,'FrontLeg','sphere',(s*1.1,1,.6),(.28,.35,.55),c)
            for k in range(3):part(m,'Toe','sphere',(s*(1.28+k*.21),1.3,.22),(.16,.49,.12),c,(0,0,s*(k-1)*.3))
        eyes(m,.91,1.32,3.14,.38)
        part(m,'Smile','cube',(0,1.80,2.12),(.7,.025,.055),black)
        for x,y,z in [(-.8,-.5,2.5),(.6,-.8,2.4),(0,-1.1,2.1)]:part(m,'MutationSpot','ico',(x,y,z),(.3,.3,.18),(.61,.20,.77))
    elif i==4:
        part(m,'Body','sphere',(0,0,2.2),(1.15,1.65,1.18),c,(-.15,0,0))
        part(m,'Neck','sphere',(0,1.05,3),( .7,.7,1.05),c,(-.3,0,0))
        part(m,'Head','sphere',(0,1.66,3.8),(.95,1.15,.7),c)
        part(m,'Snout','cube',(0,2.25,3.55),(.75,.75,.35),(.89,.67,.38))
        for s in (-1,1):
            part(m,'Eye','sphere',(s*.79,2,4.02),(.12,.29,.24),white)
            part(m,'Pupil','sphere',(s*.88,2.1,4.04),(.055,.15,.16),black)
            part(m,'LegL' if s<0 else 'LegR','sphere',(s*.85,-.25,1.05),(.48,.65,1.05),c,(0,s*.1,0))
            part(m,'Foot','cube',(s*.87,.25,.23),(.43,.78,.22),(.56,.32,.16))
            part(m,'Arm','sphere',(s*1.02,1.2,2.6),(.22,.58,.25),c)
            for j in range(2):cone(m,'Tooth',(s*.5,2.6,3.32-j*.03),(.09,.09,.18),white,(math.pi,0,0))
        for j in range(4):
            part(m,'Tail','sphere',(0,-1.1-j*.65,2.25-j*.14),(.65-j*.13,.67,.47-j*.08),c,(-.1,0,0))
            cone(m,'FossilSpine',(0,.1-j*.7,3.4-j*.1),(.2,.25,.4),white)
    elif i==5:
        part(m,'Body','sphere',(0,0,2.05),(1.35,1.1,1.9),(.06,.24,.37))
        part(m,'Belly','sphere',(0,.89,1.9),(1.0,.35,1.35),white)
        part(m,'Head','sphere',(0,.1,3.93),(1.02,.93,.98),(.08,.36,.55)); eyes(m,.4,.96,4.03,.27)
        cone(m,'Beak',(0,1.3,3.60),(.45,.28,.55),(.13,.75,.95),(-math.pi/2,0,0))
        for s in (-1,1):
            part(m,'FlipperL' if s<0 else 'FlipperR','sphere',(s*1.35,0,2.25),(.28,.65,1.12),c,(0,s*.32,s*.15))
            part(m,'Foot','sphere',(s*.6,.38,.25),(.49,.73,.22),(.11,.61,.85))
            cone(m,'IceCrown',(s*.48,0,4.94),(.23,.23,.7),cyan,(0,s*.22,0),True)
        for j in range(3):cone(m,'BackCrystal',((j-1)*.5,-.8,2.7),(.3,.3,.75),cyan,(.5,0,0),True)
    elif i==6:
        part(m,'Body','sphere',(0,0,2.2),(1.3,1.1,1.7),c)
        part(m,'Belly','sphere',(0,.93,2),( .85,.3,1.3),(.99,.70,.27))
        part(m,'Head','sphere',(0,.5,4.05),(1.05,1.1,.9),c)
        part(m,'Snout','sphere',(0,1.35,3.8),(.82,.85,.5),(.79,.18,.06)); eyes(m,.47,1.13,4.35,.29)
        for s in (-1,1):
            part(m,'WingL' if s>0 else 'WingR','wing',(s*.95,-.1,3.05),(s,1,1),(.60,.08,.10))
            part(m,'WingBone','cylinder',(s*2.1,-.18,3.85),(.10,.10,1.6),gold,(0,s*.8,0))
            cone(m,'Horn',(s*.67,.1,4.98),(.22,.22,.72),white,(0,s*.25,0))
            part(m,'LegL' if s<0 else 'LegR','sphere',(s*.8,.05,.77),(.45,.7,.7),c)
            part(m,'Foot','sphere',(s*.85,.63,.22),(.47,.7,.22),(.68,.13,.05))
        for j in range(4):part(m,'Tail','sphere',(0,-1.05-j*.55,1.35-j*.1),(.55-j*.10,.6,.42-j*.06),c)
        cone(m,'TailFlame',(0,-3.4,1.2),(.5,.5,.9),gold,(.8,0,0),True)
    else:
        part(m,'Body','sphere',(0,0,2.1),(1.12,1.05,1.65),c)
        part(m,'Head','sphere',(0,.4,4.04),(.9,.9,.98),(.72,.32,.96)); eyes(m,.37,1.12,4.18,.26)
        cone(m,'Beak',(0,1.51,3.83),(.36,.25,.51),gold,(-math.pi/2,0,0))
        for s in (-1,1):
            for j in range(4):
                part(m,'WingL' if s<0 else 'WingR','sphere',(s*(1.05+j*.65),-.1-j*.1,2.75-j*.25),(.8,.32,.32),(c if j%2==0 else (.85,.17,.68)),(0,s*.35,0))
            part(m,'Foot','sphere',(s*.54,.22,.23),(.39,.6,.22),gold)
        for j in range(5):
            cone(m,'Crown',((j-2)*.26,.25,5.0+(.32 if j==2 else 0)),(.14,.14,.65),cyan if j%2 else (.91,.34,.78),(0,(j-2)*.24,0),True)
            part(m,'TailFeather','sphere',((j-2)*.35,-1.3,1.15),(.25,1.4,.18),cyan if j%2 else c,(.4,0,(j-2)*.2))
    return m
def adult(i,source):
    m=begin('Guardian_'+str(i),((i-1)*16,-16,0))
    for ob in models[source].objects:
        dup=ob.copy(); models[m].objects.link(dup)
        dup.location=origins[m]+(ob.location-origins[source])*2.0
        dup.scale=ob.scale*2
    for s in (-1,1):cone(m,'GuardianCrest',(s*1.15,-.2,10.1),(.32,.32,1.1),gold,(0,s*.3,0))

for i in range(1,2 if STAGE=='pilot' else 8):
    m=make_creature(i); adult(i,m)
m=begin('Egg',(0,13,0))
part(m,'Body','sphere',(0,0,1.7),(1.15,1.15,1.65),white)
for j in range(7):
    a=j*2.399; z=.75+(j%3)*.8; rr=.9 if z<2.4 else .72
    part(m,'Spot','ico',(math.sin(a)*rr,math.cos(a)*rr,z),(.28,.24,.30),palette[0])
m=begin('MachineShell',(8,13,0))
part(m,'Shell','cube',(0,0,1.8),(2.9,2.9,1.8),(.15,.24,.32))
part(m,'Top','cube',(0,0,3.7),(3.15,3.15,.22),(.95,.65,.16))
part(m,'Window','cube',(0,2.93,2),(2.0,.08,.8),cyan,glow=True)
for s in (-1,1):part(m,'Vent','cube',(s*2.97,0,2),(.08,1.6,.48),(.07,.11,.18))
m=begin('IncubatorCore',(17,13,0))
part(m,'Pedestal','cylinder',(0,0,.6),(3.5,3.5,.6),(.14,.24,.32))
part(m,'Glass','sphere',(0,0,2.7),(2.8,2.8,2.7),(.22,.70,.87))
for s in (-1,1):part(m,'Pylon','cylinder',(s*3.2,0,2.8),(.28,.28,2.6),gold)
m=begin('Blaster',(27,13,0))
part(m,'Body','cube',(0,0,1.1),(.32,.8,.32),(.12,.24,.38))
part(m,'Barrel','cylinder',(0,1,1.15),(.20,.20,.55),cyan,(-math.pi/2,0,0),True)
part(m,'Grip','cube',(0,-.25,.42),(.22,.3,.49),(.15,.17,.23),(.3,0,0))
part(m,'Cell','cylinder',(0,-.65,1.25),(.25,.25,.35),gold,(-math.pi/2,0,0))
m=begin('Baton',(31,13,0))
part(m,'Handle','cylinder',(0,0,.5),(.14,.14,.5),(.12,.16,.23))
part(m,'Rod','cylinder',(0,0,1.65),(.22,.22,.75),cyan,glow=True)
part(m,'Guard','cylinder',(0,0,1),(.42,.42,.10),gold)

# Geometry bridge: canonical reusable meshes + rigid part transforms, Blender Z-up -> Roblox Y-up.
B=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
meshdefs={}; modeldefs={}
def rounded(v):return [round(float(x),5) for x in v]
for model,collection in models.items():
    arr=[]
    for ob in collection.objects:
        me=ob.data; key=me.name
        if key not in meshdefs:
            me.calc_loop_triangles(); pts=[B@v.co for v in me.vertices]
            lo=Vector([min(p[k] for p in pts) for k in range(3)]); hi=Vector([max(p[k] for p in pts) for k in range(3)])
            center=(lo+hi)*.5
            meshdefs[key]={'Vertices':[rounded(p-center) for p in pts], 'Triangles':[[int(x)+1 for x in t.vertices] for t in me.loop_triangles], 'Size':rounded(hi-lo),'Center':rounded(center)}
        md=meshdefs[key]; localcenter=B.transposed()@Vector(md['Center'])
        rot=ob.rotation_euler.to_matrix(); pos=ob.location-origins[model]+rot@Vector([localcenter[k]*ob.scale[k] for k in range(3)])
        rp=B@rot@B.transposed(); p=B@pos
        vals=list(p)+[rp[i][j] for i in range(3) for j in range(3)]
        scales=[ob.scale.x,ob.scale.z,ob.scale.y]
        if any(v<0 for v in scales):
            signs=[-1 if v<0 else 1 for v in scales]; mirrored=key+'_mirror'+''.join(str(s) for s in signs)
            if mirrored not in meshdefs:
                meshdefs[mirrored]={'Vertices':[[p[k]*signs[k] for k in range(3)] for p in md['Vertices']], 'Triangles':[[t[0],t[2],t[1]] if signs[0]*signs[1]*signs[2]<0 else t for t in md['Triangles']], 'Size':md['Size'],'Center':md['Center']}
            key=mirrored
        arr.append({'Name':ob.name.split('.')[0],'Mesh':key,'CF':rounded(vals),'Scale':rounded([abs(v) for v in scales]), 'Color':rounded(ob['ETColor']),'Glow':bool(ob['ETGlow'])})
    modeldefs[model]=arr
data={'Meshes':meshdefs,'Models':modeldefs,'Revision':STAGE}
with open(os.path.join(OUT,'geometry.json'),'w',encoding='utf-8') as f:json.dump(data,f,separators=(',',':'))
for name,co in models.items():
    bpy.ops.object.select_all(action='DESELECT')
    for ob in co.objects:ob.select_set(True)
    bpy.context.view_layer.objects.active=next(iter(co.objects))
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,name+'.fbx'),use_selection=True,apply_unit_scale=True,axis_forward='-Z',axis_up='Y',add_leaf_bones=False,bake_anim=False)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'EggTycoonV3.blend'))
print(json.dumps({'Stage':STAGE,'Models':list(models),'ReusableMeshes':len(meshdefs),'Objects':sum(len(c.objects) for c in models.values()),'GeometryBytes':os.path.getsize(os.path.join(OUT,'geometry.json'))}))
