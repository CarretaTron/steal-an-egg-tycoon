"""Read-only visual reference inspection; does not run source-map scripts."""
from pathlib import Path
import importlib.util
import json
import hashlib
from collections import Counter

ROOT = Path(__file__).resolve().parents[3]
parser_path = ROOT / 'StealAnEggTycoonV3/Blender/Decoracao/Referencias/extract_reference_samples.py'
spec = importlib.util.spec_from_file_location('reference_parser', parser_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
ReferenceFile = module.ReferenceFile


def main():
    exports = []
    inventory = []
    for file in (ROOT / 'Mapas open source').iterdir():
        source = ReferenceFile(file)
        plot_root = next((i for i in source.nodes if source.path(i) == 'Workspace/Plots'), None)
        plots = source.children[plot_root]
        visible_neon = [i for p in plots for i in source.descendants(p)
                        if source.nodes[i]['Properties'].get('Material') == 288
                        and source.nodes[i]['Properties'].get('Transparency', 0) < .99]
        inventory.append({'File': file.name, 'SHA256': hashlib.sha256(file.read_bytes()).hexdigest(),
                          'Bytes': file.stat().st_size, 'Instances': len(source.nodes),
                          'Plots': [{'Path': source.path(i), 'Descendants': len(source.descendants(i))} for i in plots],
                          'VisibleNeonPartsInPlots': len(visible_neon)})
        targets = {'2.rbxlx': ('Workspace/Plots/7/ToUpdate/StarterPen', 'Curral_portao_madeira'),
                   'MeuMapa.rbxlx': ('Workspace/Plots/Base_7/Build', 'Base_grama_degraus_cerca')}
        if file.name not in targets:
            continue
        target_path, label = targets[file.name]
        ref = next(i for i in source.nodes if source.path(i) == target_path)
        sample = source.sample(ref, label)
        rows = []
        unsupported = []
        for row in sample['Parts']:
            prop = row['Properties']
            if row['Class'] not in ('Part', 'WedgePart', 'CornerWedgePart'):
                unsupported.append({'Class': row['Class'], 'Path': source.path(row['Id']),
                                    'MeshId': prop.get('MeshId')})
                continue
            if prop.get('Transparency', 0) >= .99:
                continue
            assert 'CFrame' in prop and 'size' in prop
            rows.append({'Name': prop.get('Name', row['Class']), 'Class': row['Class'],
                         'CFrame': prop['CFrame'], 'Size': prop['size'],
                         'Color': prop.get('Color3uint8', [163,162,165]),
                         'Material': prop.get('Material', 256),
                         'Transparency': prop.get('Transparency', 0), 'Shape': prop.get('shape', 1)})
        corners = []
        for row in rows:
            cf, size = row['CFrame'], row['Size']
            for ix in (-.5,.5):
                for iy in (-.5,.5):
                    for iz in (-.5,.5):
                        local = [ix*size[0], iy*size[1], iz*size[2]]
                        corners.append([cf[axis]+sum(cf[3+axis*3+k]*local[k] for k in range(3)) for axis in range(3)])
        low = [min(c[k] for c in corners) for k in range(3)]
        high = [max(c[k] for c in corners) for k in range(3)]
        pivot = [(low[0]+high[0])/2, low[1], (low[2]+high[2])/2]
        for row in rows:
            row['CFrame'][:3] = [row['CFrame'][k]-pivot[k] for k in range(3)]
        exports.append({'Label': label, 'SourceFile': file.name, 'SourcePath': target_path,
                        'SourceBounds': {'Min': low, 'Max': high}, 'SourcePivot': pivot,
                        'Dimensions': [high[k]-low[k] for k in range(3)], 'Parts': rows,
                        'Unsupported': unsupported,
                        'Notes': 'Visual primitive properties only. No scripts, UI, package links, constraints or game logic. CFrame translations recentered; Y=0 is bottom.'})
    out = Path(__file__).resolve().parent / 'bases-referencia.json'
    out.write_text(json.dumps({'Inventory': inventory, 'Samples': exports}, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
    print(json.dumps({'File':str(out), 'Inventory':inventory, 'Samples':[{k:v for k,v in s.items() if k!='Parts'}|{'PartCount':len(s['Parts']), 'Palette':Counter(tuple(p['Color']) for p in s['Parts']).most_common()} for s in exports]}, ensure_ascii=False))


if __name__ == '__main__':
    main()
