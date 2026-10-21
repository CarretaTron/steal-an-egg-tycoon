from pathlib import Path
import json,hashlib,xml.etree.ElementTree as E
root=Path(__file__).resolve().parent
out=root/'Resultados'
manifest=json.loads((out/'manifesto-fontes.json').read_text(encoding='utf-8'))
for entry in manifest:
    original=root/entry['path']
    delivered=out/'Fontes'/entry['path']
    assert delivered.exists(),str(delivered)
    assert hashlib.sha256(original.read_bytes()).hexdigest()==entry['sha256']
    assert delivered.read_bytes()==original.read_bytes(),f'Source mismatch: {delivered}'
tree=E.parse(out/'StealAnEggTycoonV3.rbxlx')
items=list(tree.getroot().iter('Item'))
scripts=[i for i in items if i.get('class') in ('Script','LocalScript','ModuleScript')]
def nm(i):return i.findtext('Properties/string[@name="Name"]') or ''
tests=[i for i in scripts if 'Studio' in nm(i) and i.get('class')!='ModuleScript']
assert all(i.findtext('Properties/bool[@name="Disabled"]')=='true' for i in tests)
assert any(nm(i)=='EggTycoonV2_Backup' for i in items)
assert len(list((out/'Blender').glob('*.fbx')))==19
assert (out/'Blender/EggTycoonV3.blend').stat().st_size>100000
report={'sources':len(manifest),'deliveredSourceCopies':len(list((out/'Fontes').rglob('*.luau'))),'fbx':19,'disabledTestScripts':len(tests),'portableParses':True,'allSourceCopiesMatch':True,'v2BackupIncluded':True}
(out/'Testes/validacao-pacote.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
