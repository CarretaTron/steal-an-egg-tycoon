"""Geometry fidelity and preservation checks for the original Blender chicken."""
import json, math, hashlib
from pathlib import Path

base=Path(__file__).resolve().parents[1]
old=json.loads((base/'Backups/AntesGalinhaFofa/geometry.json').read_text(encoding='utf-8'))
data=json.loads((base/'Blender/geometry.json').read_text(encoding='utf-8'))
patch=json.loads((base/'Blender/GalinhaFofa/chicken_geometry.json').read_text(encoding='utf-8'))
count=0
def check(condition, message):
    global count
    assert condition,message
    count+=1

for key,value in old['Models'].items():
    if key not in ('Species_1','Guardian_1'):check(data['Models'][key]==value,'Other model changed: '+key)
for key,value in old['Meshes'].items():check(data['Meshes'][key]==value,'Original mesh changed: '+key)
for key,mesh in patch['Meshes'].items():
    check(data['Meshes'][key]==mesh,'Geometry bridge mismatch: '+key)
    check(all(math.isfinite(x) for p in mesh['Vertices'] for x in p),'Nonfinite vertex: '+key)
    check(all(x>0 for x in mesh['Size']),'Flat/negative mesh: '+key)
    check(len(mesh['Triangles'])==len(mesh['TriangleNormals']),'Missing split normals: '+key)
    for tri in mesh['Triangles']:
        check(len(set(tri))==3 and all(1<=i<=len(mesh['Vertices']) for i in tri),'Invalid triangle: '+key)
        a,b,c=[mesh['Vertices'][i-1] for i in tri]
        u=[b[k]-a[k] for k in range(3)];v=[c[k]-a[k] for k in range(3)]
        cross=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
        check(sum(x*x for x in cross)>1e-15,'Zero-area triangle: '+key)
    for ns in mesh['TriangleNormals']:check(all(1<=i<=len(mesh['Normals']) for i in ns),'Invalid normals: '+key)
    for n in mesh['Normals']:check(abs(sum(x*x for x in n)-1)<1e-4,'Nonunit normal: '+key)

baby=data['Models']['Species_1'];adult=data['Models']['Guardian_1']
check(len(baby)==20 and len(adult)==20,'Unexpected anatomical part count')
check({r['Name'] for r in baby}>={'Body','Head','WingL','WingR','FootL','FootR','Tail','Comb','Eyes'},'Animation/facial parts missing')
for b,a in zip(baby,adult):
    check(a['Mesh']==b['Mesh'] and a['Color']==b['Color'],'Adult appearance mismatch')
    check(a['Scale']==[2,2,2] and a['CF'][:3]==[2*x for x in b['CF'][:3]],'Adult scale mismatch')
for name,rows in patch['Models'].items():check(rows==data['Models'][name],'Model bridge mismatch')
for path in (base/'Shared').glob('*.luau'):check(len(path.read_text(encoding='utf-8'))<190000,'Studio source too long: '+path.name)
check(sum(len(m['Triangles']) for m in patch['Meshes'].values())<=8500,'Triangle budget exceeded')
check((base/'Blender/GalinhaFofa/GalinhaFofa.blend').stat().st_size>100000,'Missing Blender scene')
for name in ('Species_1','Guardian_1'):
    check((base/'Blender'/f'{name}.fbx').read_bytes()==(base/'Blender/GalinhaFofa'/f'{name}.fbx').read_bytes(),'FBX mismatch: '+name)
report={'passed':True,'checks':count,'triangles':sum(len(m['Triangles']) for m in patch['Meshes'].values()),
        'vertices':sum(len(m['Vertices']) for m in patch['Meshes'].values()),'rigidPartsPerCreature':20,
        'otherModelsPreserved':len(old['Models'])-2,'originalMeshesPreserved':len(old['Meshes']),
        'environment':'Python; geometry data only; no Play, physics, clients or FPS'}
(base/'Resultados/GalinhaFofa/validacao-geometria.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
