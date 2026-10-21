"""Rebuild the portable project from reviewed sources, preserving the imported V2 backup."""
from pathlib import Path
import json, xml.etree.ElementTree as ET, hashlib, struct, base64

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT/'Backups/AntesContinuacao/StealAnEggTycoonV3.rbxlx'
OUT=ROOT/'Resultados'
OUT.mkdir(exist_ok=True)
tree=ET.parse(SOURCE); root=tree.getroot()

def name(item): return item.findtext('Properties/string[@name="Name"]')
def prop(item, tag, key, value):
    properties=item.find('Properties')
    if properties is None: properties=ET.SubElement(item,'Properties')
    old=properties.find(f'*[@name="{key}"]')
    if old is not None: properties.remove(old)
    field=ET.SubElement(properties,tag,{'name':key}); field.text=str(value)
    return field
def item(parent, cls, nm, ref):
    result=ET.SubElement(parent,'Item',{'class':cls,'referent':ref})
    ET.SubElement(result,'Properties');prop(result,'string','Name',nm)
    return result

server_service=next(i for i in root.findall('Item') if i.get('class')=='ServerScriptService')
server_folder=next(i for i in server_service.findall('Item') if i.get('class')=='Folder')
prop(server_folder,'string','Name','EggTycoonV3')
starter=next(i for i in root.findall('Item') if i.get('class')=='StarterPlayer')
client_folder=next(i for i in starter.findall('Item') if i.get('class')=='StarterPlayerScripts')
replicated=next(i for i in root.findall('Item') if i.get('class')=='ReplicatedStorage')
shared_folder=next(i for i in replicated.iter('Item') if name(i)=='Shared')
manifest=[]
for folder in ('Shared','Server','Client'):
    for path in sorted((ROOT/folder).glob('*.luau')):
        suffix='.server.luau' if path.name.endswith('.server.luau') else '.client.luau' if path.name.endswith('.client.luau') else '.luau'
        short=path.name.removesuffix(suffix)
        wanted='EggTycoonV3_'+short if folder=='Client' else short
        aliases={wanted,'EggTycoonV3'+short} if folder=='Client' else {wanted}
        matches=[i for i in root.iter('Item') if name(i) in aliases and i.get('class') in ('Script','LocalScript','ModuleScript')]
        if matches: target=matches[0]
        else:
            parent=client_folder if folder=='Client' else shared_folder if folder=='Shared' else server_folder
            cls='LocalScript' if suffix=='.client.luau' else 'Script' if suffix=='.server.luau' else 'ModuleScript'
            target=item(parent,cls,wanted,'NEW_'+short)
        prop(target,'string','Name',wanted)
        source=path.read_text(encoding='utf-8-sig')
        prop(target,'ProtectedString','Source',source)
        if short.startswith('Studio') and target.get('class')!='ModuleScript': prop(target,'bool','Disabled','true')
        manifest.append({'path':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})

storage=next((i for i in root.findall('Item') if i.get('class')=='ServerStorage'),None)
if storage is None: storage=item(root,'ServerStorage','ServerStorage','V3_ServerStorage')
for old in list(storage.findall('Item')):
    if name(old)=='EggTycoonV2_Backup': storage.remove(old)
backup=json.loads((ROOT/'Backups/V2-backup.json').read_text(encoding='utf-8'))
nodes={}
def attributes_binary(attributes):
    data=struct.pack('<I',len(attributes))
    for key,entry in attributes.items():
        encoded=key.encode('utf-8');data+=struct.pack('<I',len(encoded))+encoded
        typ,value=entry['Type'],entry['Value']
        if typ=='string':
            encoded=value.encode('utf-8');data+=bytes([2])+struct.pack('<I',len(encoded))+encoded
        elif typ=='boolean': data+=bytes([3,1 if value else 0])
        elif typ=='number': data+=bytes([6])+struct.pack('<d',value)
        else: raise ValueError('Unsupported backup attribute '+typ)
    return base64.b64encode(data).decode('ascii')
for row in backup:
    parent=nodes.get(row.get('Parent'),storage)
    node=item(parent,row['Class'],row['Properties']['Name']['Value'],row['Id']); nodes[row['Id']]=node
    for key,entry in row['Properties'].items():
        if key=='Name' or entry is None: continue
        typ,val=entry['Type'],entry['Value']
        if key=='WorldPivot': continue
        tag={'string':'ProtectedString' if key=='Source' else 'string','boolean':'bool','number':'double','Vector3':'Vector3','Vector2':'Vector2','Color3':'Color3','CFrame':'CoordinateFrame','UDim2':'UDim2','UDim':'UDim','Ref':'Ref','token':'token'}.get(typ)
        if not tag: continue
        f=prop(node,tag,key,'')
        if typ=='boolean': f.text=str(val).lower()
        elif typ in ('string','number','Ref','token'): f.text=str(val)
        else:
            keys={'Vector3':['X','Y','Z'],'Vector2':['X','Y'],'Color3':['R','G','B'],'CFrame':['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],'UDim2':['XS','XO','YS','YO'],'UDim':['S','O']}[typ]
            for k,v in zip(keys,val): ET.SubElement(f,k).text=str(v)
    if row['Attributes']: prop(node,'BinaryString','AttributesSerialize',attributes_binary(row['Attributes']))
    if row['Class'] in ('Script','LocalScript'): prop(node,'bool','Disabled','true')
# Retain the exact typed attributes and all properties alongside the inert original hierarchy.
raw=item(nodes[backup[0]['Id']],'StringValue','BackupMetadataJSON','V2_Metadata')
prop(raw,'string','Value',json.dumps(backup,separators=(',',':'),ensure_ascii=False))

path=OUT/'StealAnEggTycoonV3.rbxlx'
tree.write(path,encoding='utf-8',xml_declaration=True)
(OUT/'manifesto-fontes.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps({'project':str(path),'sources':len(manifest),'backupInstances':len(backup),'bytes':path.stat().st_size}))
