"""Adversarial checks on temporary copies; leaves delivered artifacts untouched."""
from pathlib import Path
import copy
import hashlib
import importlib.util
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as E

base = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('delivery_verifier', base / 'verify_package.py')
verify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify)
portable = base / 'Resultados/StealAnEggTycoonV3.rbxlx'
original_hash = hashlib.sha256(portable.read_bytes()).hexdigest()
root_hash = hashlib.sha256((base / portable.name).read_bytes()).hexdigest()
original = E.parse(portable).getroot()
result = verify.verify_embedded_sources(original, base)
assert result['embeddedSourceInstancesVerified'] == 24
assert result['disabledTestScripts'] == 8
print('BASELINE PASS', result)


def find(node, folder, name):
    current = node
    for parent_name, _ in verify.SOURCE_CONTAINERS[folder]:
        current = next(c for c in current.findall('Item') if verify.nm(c) == parent_name)
    return current, next(c for c in current.findall('Item') if verify.nm(c) == name)


def mismatch_source(node):
    _, item = find(node, 'Shared', 'Config')
    source = item.find('Properties/ProtectedString[@name="Source"]')
    source.text = (source.text or '') + '\n-- stale embedded source mutation\n'


def wrong_name(node):
    _, item = find(node, 'Server', 'Building')
    item.find('Properties/string[@name="Name"]').text = 'Building_Stale'


def wrong_class(node):
    _, item = find(node, 'Server', 'Building')
    item.set('class', 'Script')


def wrong_parent_with_v2_decoy(node):
    parent, item = find(node, 'Shared', 'BuildRules')
    parent.remove(item)
    storage = next(c for c in node.findall('Item') if verify.nm(c) == 'ServerStorage')
    backup = next(c for c in storage.findall('Item') if verify.nm(c) == 'EggTycoonV2_Backup')
    backup.append(item)


def duplicate_instance(node):
    parent, item = find(node, 'Shared', 'Config')
    clone = copy.deepcopy(item)
    clone.set('referent', 'NEGATIVE_DUPLICATE')
    parent.append(clone)


def extra_script(node):
    _, item = find(node, 'Server', 'Building')
    clone = copy.deepcopy(item)
    clone.set('referent', 'NEGATIVE_EXTRA')
    workspace = next(c for c in node.findall('Item') if verify.nm(c) == 'Workspace')
    workspace.append(clone)


def enabled_test(node):
    _, item = find(node, 'Server', 'StudioQA')
    item.find('Properties/bool[@name="Disabled"]').text = 'false'


def enabled_test_conflict(node):
    _, item = find(node, 'Client', 'EggTycoonV3_StudioQA')
    E.SubElement(item.find('Properties'), 'bool', {'name': 'Enabled'}).text = 'true'


def missing_source(node):
    _, item = find(node, 'Client', 'EggTycoonV3_Client')
    props = item.find('Properties')
    props.remove(props.find('ProtectedString[@name="Source"]'))


cases = [mismatch_source, wrong_name, wrong_class, wrong_parent_with_v2_decoy,
         duplicate_instance, extra_script, enabled_test, enabled_test_conflict, missing_source]
scratch_parent = Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix='verify-package-mutations-', dir=scratch_parent) as scratch:
    scratch = Path(scratch)
    for mutation in cases:
        mutated = copy.deepcopy(original)
        mutation(mutated)
        copied_portable = scratch / (mutation.__name__ + '.rbxlx')
        E.ElementTree(mutated).write(copied_portable, encoding='utf-8', xml_declaration=True)
        try:
            verify.verify_embedded_sources(E.parse(copied_portable).getroot(), base)
        except AssertionError as error:
            print('REJECTED', mutation.__name__, str(error))
        else:
            raise AssertionError('Verifier accepted mutation ' + mutation.__name__)

    fixture = scratch / 'delivery'
    fixture.mkdir()
    shutil.copytree(base / 'Resultados', fixture / 'Resultados')
    for folder in verify.SOURCE_CONTAINERS:
        shutil.copytree(base / folder, fixture / folder)
    shutil.copytree(base / 'Map', fixture / 'Map')
    shutil.copyfile(portable, fixture / portable.name)
    shutil.copyfile(base / 'verify_package.py', fixture / 'verify_package.py')
    positive = subprocess.run([sys.executable, str(fixture / 'verify_package.py')], capture_output=True, text=True)
    assert positive.returncode == 0, positive.stdout + positive.stderr
    print('FULL SCRIPT TEMPORARY DELIVERY PASS')

    for portable_path in [fixture / portable.name, fixture / 'Resultados' / portable.name]:
        document = E.parse(portable_path)
        mismatch_source(document.getroot())
        document.write(portable_path, encoding='utf-8', xml_declaration=True)
    negative = subprocess.run([sys.executable, str(fixture / 'verify_package.py')], capture_output=True, text=True)
    assert negative.returncode != 0 and 'Embedded source mismatch' in negative.stderr, negative.stdout + negative.stderr
    print('FULL SCRIPT REJECTS TAMPERED PORTABLE', negative.stderr.splitlines()[-1])

assert hashlib.sha256(portable.read_bytes()).hexdigest() == original_hash
assert hashlib.sha256((base / portable.name).read_bytes()).hexdigest() == root_hash
print('ORIGINAL PORTABLES UNCHANGED', original_hash)
print('ALL VERIFIER CHECKS PASS: final baseline, nine mutation files, full CLI positive/negative')
