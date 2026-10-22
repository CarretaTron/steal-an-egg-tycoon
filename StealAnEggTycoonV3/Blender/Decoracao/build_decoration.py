"""Original low-poly nature kit. Execute with Blender MCP; never imports map scripts.

DECOR_OUT: dedicated output directory. DECOR_STAGE: 'prototype' or 'all'.
Creates a NEW scene, preserving every pre-existing scene/object. An existing scene
with the same stage name is an error, so a second run cannot overwrite edits.
Blender coordinates are Z-up; geometry.json is in studs, Roblox Y-up.
"""
import bpy
import json
import math
import os
import random
from collections import defaultdict
from mathutils import Vector

OUT = os.path.abspath(globals().get('DECOR_OUT') or os.path.dirname(__file__))
STAGE = globals().get('DECOR_STAGE', 'all')
assert STAGE in ('prototype', 'all'), 'DECOR_STAGE must be prototype or all'
SCENE_NAME = 'CatalogoDecoracao_Prototipo' if STAGE == 'prototype' else 'CatalogoDecoracao'
assert bpy.data.scenes.get(SCENE_NAME) is None, 'Scene already exists: ' + SCENE_NAME
os.makedirs(os.path.join(OUT, 'Exportacoes'), exist_ok=True)

scene = bpy.data.scenes.new(SCENE_NAME)
bpy.context.window.scene = scene
scene.unit_settings.system = 'NONE'
scene.unit_settings.scale_length = 1.0
scene['Description'] = 'Original nature kit inspired by silhouettes and palettes of local map references'
scene['Generator'] = 'build_decoration.py'
scene['GeometryAxes'] = 'Blender Z-up; JSON Roblox Y-up [X,Z,-Y]'
kit = bpy.data.collections.new(SCENE_NAME + '_Modelos')
scene.collection.children.link(kit)
materials = {}
models = []


def linear(v):
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def palette(hexes):
    return [tuple(int(h.lstrip('#')[i:i+2], 16) / 255 for i in (0, 2, 4)) for h in hexes]


BARK = palette(['68422D', '8B5B38', 'B47C49'])
GREEN = palette(['30774B', '4B9E55', '85C958'])
PINK = palette(['C45E96', 'EC8CB8', 'FFC4D6'])
TROPICAL = palette(['246D49', '429E52', 'A0D34D'])
PINE = palette(['285D58', '387C71', '58A18A'])
SNOW = palette(['C6E5EC', 'F1FCFF'])
SWAMP = palette(['315B4F', '52836B', '88B477'])
CHAR = palette(['272A35', '424150', '625362'])
MOSS = palette(['548048', '9DB75A'])
STONE = palette(['566F78', '7F969A', 'B0C0BB'])
SAND = palette(['B77F4B', 'DBA85F', 'F2CE8A'])
BASALT = palette(['292C3E', '444256', '686076'])
ICE = palette(['337FAF', '6AC8E8', 'C1F8FF'])
VOID = palette(['60309A', '9961DA', 'D6A0FF'])
CREAM = palette(['EFC88B'])
EMBER = palette(['FF763C', 'FFC568'])


def mat(color, glow=False):
    key = (tuple(color), glow)
    if key not in materials:
        name = 'DECOR_' + ''.join(f'{round(c*255):02X}' for c in color) + ('_Luz' if glow else '')
        material = bpy.data.materials.new(name)
        material.use_nodes = True
        material.diffuse_color = (*[linear(c) for c in color], 1)
        shader = next(n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        shader.inputs['Base Color'].default_value = (*[linear(c) for c in color], 1)
        shader.inputs['Roughness'].default_value = .8
        if glow:
            if 'Emission Color' in shader.inputs:
                shader.inputs['Emission Color'].default_value = (*[linear(c) for c in color], 1)
            if 'Emission Strength' in shader.inputs:
                shader.inputs['Emission Strength'].default_value = .35
        material['ExportColorSRGB'] = list(color)
        material['ExportGlow'] = glow
        materials[key] = material
    return materials[key]


class Asset:
    def __init__(self, ident, name, biome, category):
        self.id, self.name, self.biome, self.category = ident, name, biome, category
        self.seed = random.Random(451 + sum(ord(c) for c in ident))
        self.groups = defaultdict(lambda: [[], []])
        self.objects = []
        self.origin = Vector(((len(models) % 5) * 30, (len(models) // 5) * 32, 0))
        self.collection = bpy.data.collections.new(ident + ('_Proto' if STAGE == 'prototype' else ''))
        kit.children.link(self.collection)
        models.append(self)

    def poly(self, points, color, collision=False, glow=False):
        key = (tuple(color), collision, glow)
        verts, faces = self.groups[key]
        base = len(verts)
        verts.extend(tuple(v) for v in points)
        faces.append(tuple(range(base, base + len(points))))

    def surface(self, verts, faces, colors, collision=False, glow=False):
        light = Vector((-.55, -.8, 1)).normalized()
        for face in faces:
            pts = [Vector(verts[i]) for i in face]
            n = (pts[1]-pts[0]).cross(pts[2]-pts[0])
            score = n.normalized().dot(light) if n.length > 1e-6 else 0
            score += self.seed.uniform(-.12, .12)
            shade = min(len(colors)-1, max(0, int((score*.48+.5)*len(colors))))
            self.poly(pts, colors[shade], collision, glow)

    def finish(self):
        # The reusable pivot is the exact lowest vertex of the WHOLE asset, not
        # the lowest vertex of each color group. Preserve inter-part alignment.
        ground = min(v[2] for verts, _faces in self.groups.values() for v in verts)
        for verts, _faces in self.groups.values():
            verts[:] = [(v[0], v[1], v[2]-ground) for v in verts]
        parts = []
        for index, ((color, collision, glow), (verts, faces)) in enumerate(self.groups.items()):
            mesh = bpy.data.meshes.new(self.id + '_Geo_' + str(index+1))
            mesh.from_pydata(verts, [], faces)
            mesh.update()
            mesh.calc_loop_triangles()
            obj = bpy.data.objects.new(self.id + ('_Solido_' if collision else '_Folha_') + str(index+1), mesh)
            self.collection.objects.link(obj)
            obj.location = self.origin
            obj.data.materials.append(mat(color, glow))
            obj['DecorId'] = self.id
            obj['DisplayName'] = self.name
            obj['Collision'] = collision
            obj['Glow'] = glow
            obj['Biome'] = self.biome
            obj['Source'] = 'Original Blender geometry; build_decoration.py'
            for p in mesh.polygons:
                p.use_smooth = False
            # Every component is defined relative to its model's ground pivot.
            parts.append({'Name': obj.name, 'Vertices': [[round(v.co.x, 5), round(v.co.z, 5), round(-v.co.y, 5)] for v in mesh.vertices],
                          'Triangles': [[i+1 for i in tri.vertices] for tri in mesh.loop_triangles],
                          'Color': [round(v, 6) for v in color], 'Glow': glow, 'Collision': collision})
            self.objects.append(obj)
        self.data = {'Id': self.id, 'Name': self.name, 'Biome': self.biome, 'Category': self.category, 'Parts': parts}


def tube(a, points, radii, colors=BARK, sides=7, collision=True, glow=False):
    pts = [Vector(p) for p in points]
    verts, faces = [], []
    for j, (p, radius) in enumerate(zip(pts, radii)):
        tangent = (pts[min(j+1, len(pts)-1)]-pts[max(0, j-1)]).normalized()
        u = tangent.cross(Vector((0, 0, 1)))
        if u.length < .1:
            u = tangent.cross(Vector((0, 1, 0)))
        u.normalize()
        v = tangent.cross(u).normalized()
        for i in range(sides):
            angle = i * math.tau / sides + .12
            irregular = 1 + .06 * math.sin(i*2.7+j*.75)
            verts.append(p + radius*irregular*(math.cos(angle)*u + math.sin(angle)*v))
    faces.append(tuple(reversed(range(sides))))
    for j in range(len(pts)-1):
        for i in range(sides):
            nxt = (i+1) % sides
            faces.append((j*sides+i, j*sides+nxt, (j+1)*sides+nxt, (j+1)*sides+i))
    faces.append(tuple((len(pts)-1)*sides+i for i in range(sides)))
    a.surface(verts, faces, colors, collision, glow)


def blob(a, center, scale, colors=GREEN, segments=9, rings=4, twist=.15, collision=False, glow=False):
    c, s = Vector(center), Vector(scale)
    verts = [c + Vector((0, 0, -s.z))]
    for j in range(1, rings):
        lat = -math.pi/2 + math.pi*j/rings
        for i in range(segments):
            angle = i*math.tau/segments + twist*j
            jitter = 1 + .08*math.sin(i*3+j*2)
            verts.append(c + Vector((s.x*math.cos(lat)*math.cos(angle)*jitter,
                                     s.y*math.cos(lat)*math.sin(angle)*jitter,
                                     s.z*math.sin(lat))))
    top = len(verts)
    verts.append(c + Vector((.07*s.x, 0, s.z)))
    faces = [(0, 1+(i+1)%segments, 1+i) for i in range(segments)]
    for j in range(rings-2):
        for i in range(segments):
            l, n = 1+j*segments+i, 1+j*segments+(i+1)%segments
            faces.extend([(l, n, n+segments), (l, n+segments, l+segments)])
    last = 1+(rings-2)*segments
    faces.extend((last+i, last+(i+1)%segments, top) for i in range(segments))
    a.surface(verts, faces, colors, collision, glow)


def leaf(a, start, end, width, colors=TROPICAL, sag=.3, steps=5, curl=.15, glow=False):
    start, end = Vector(start), Vector(end)
    delta = end-start
    side = Vector((-delta.y, delta.x, 0)).normalized()
    if side.length < .1:
        side = Vector((1, 0, 0))
    centers = []
    verts = []
    for j in range(steps+1):
        t = j/steps
        p = start.lerp(end, t) + Vector((0, 0, sag*math.sin(math.pi*t) - curl*t*t))
        centers.append(p)
        w = width * math.sin(math.pi*t)**.72 + .015
        verts.extend([p-side*w + Vector((0, 0, -.05)), p+Vector((0, 0, .12*math.sin(math.pi*t))), p+side*w+Vector((0, 0, -.05))])
    for j in range(steps):
        k, n = j*3, (j+1)*3
        # Ridged upper surface plus a closed underside with slight thickness.
        for f in ((k, n, n+1, k+1), (k+1, n+1, n+2, k+2)):
            pts = [verts[i] for i in f]
            a.poly(pts, colors[min(len(colors)-1, 1 if j%3 else 2)], glow=glow)
            a.poly([p-Vector((0, 0, .08)) for p in reversed(pts)], colors[0], glow=glow)
        for edge in ((k, n), (n+2, k+2)):
            p, q = verts[edge[0]], verts[edge[1]]
            a.poly([p, q, q-Vector((0, 0, .08)), p-Vector((0, 0, .08))], colors[0], glow=glow)


def root_spread(a, radius=1.15, colors=BARK, count=5, height=.8):
    for i in range(count):
        angle = i*math.tau/count+.28
        d = Vector((math.cos(angle), math.sin(angle), 0))
        tube(a, [d*radius*1.7+Vector((0, 0, .16)), d*radius*.6+Vector((0, 0, .5)), Vector((0, 0, height))],
             [.14, .33, .48], colors, sides=5)


def campestre():
    a = Asset('ArvoreCampestre', 'Árvore campestre', 'Campo', 'Árvores')
    root_spread(a)
    tube(a, [(0, 0, .45), (.25, .1, 4), (-.3, 0, 7.8), (.8, .1, 11)], [1.05, .85, .58, .17])
    crowns = [(-3.5, .2, 10.6, 3.3), (3.3, -.6, 11, 3.6), (-1.3, 2.6, 12, 3.5),
              (.5, -.9, 14.2, 3.8), (3, 2.1, 13.2, 2.5), (-3, -2, 13, 2.8)]
    for i, (x, y, z, r) in enumerate(crowns):
        tube(a, [(-.1, 0, 5.7), (x*.5, y*.5, z-2.5), (x, y, z-.5)], [.42, .27, .06])
        blob(a, (x, y, z), (r, r*.85, r*.72), GREEN, twist=.15+i*.07)
    return a


def sakura():
    a = Asset('ArvoreSakura', 'Cerejeira rosa', 'Floresta', 'Árvores')
    root_spread(a, .95, BARK)
    tube(a, [(0, 0, .4), (-.3, .1, 3.5), (.3, 0, 6.2), (-1.5, .4, 9.2)], [.82, .62, .42, .12])
    for i, (x, y, z, r) in enumerate([(-4.2, .2, 9.2, 2.9), (3.7, 0, 9.8, 3.4), (0, 2.7, 11, 3.5), (-1.4, -1.5, 12, 3.5), (3, -2.2, 12.2, 2.7)]):
        tube(a, [(0, 0, 4.6), (x*.55, y*.55, z-2.3), (x, y, z)], [.39, .22, .05])
        blob(a, (x, y, z), (r, r*.83, r*.62), PINK, twist=.28+i*.13)
    # Three fallen petals, fixed geometry rather than particle effects.
    for x, y, z in [(-2, -2, .12), (1.8, -1.2, .12), (2.8, .7, .12)]:
        blob(a, (x, y, z), (.34, .22, .08), PINK, segments=5, rings=2)
    return a


def palm():
    a = Asset('PalmeiraBananeira', 'Palmeira bananeira', 'Deserto', 'Árvores')
    root_spread(a, .85)
    tube(a, [(0, 0, .4), (.2, .05, 4), (1.1, .2, 8), (1.8, .4, 12), (1.5, .2, 15)], [.95, .8, .66, .53, .4], sides=8)
    for j in range(9):
        z = 1.8+j*1.35
        x = .15+1.5*min(1, z/12)
        tube(a, [(x, .17, z-.09), (x, .17, z+.09)], [.91-.034*z, .93-.034*z], [BARK[0]], sides=8)
    crown = Vector((1.5, .2, 15))
    for i in range(9):
        angle = i*math.tau/9
        d = Vector((math.cos(angle), math.sin(angle), 0))
        tip = crown+d*(6.7 if i%2 else 7.4)+Vector((0, 0, -.7 if i%2 else -2))
        leaf(a, crown, tip, 1.0 if i%2 else 1.2, TROPICAL, sag=2.2, steps=6, curl=.8)
        tube(a, [crown, crown+d*3+Vector((0, 0, 1.5)), tip], [.13, .08, .02], [TROPICAL[1]], sides=5, collision=False)
    for i in range(3):
        blob(a, crown+Vector((.7*math.cos(i*2.1), .7*math.sin(i*2.1), -.8)), (.45, .4, .6), [BARK[0]], segments=6, rings=3)
    return a


def tier(a, z, radius, height, colors, snow=False):
    sides = 9
    verts = []
    for j, (rr, zz) in enumerate([(radius*.8, z), (radius, z+.3), (radius*.55, z+height*.65), (.08, z+height)]):
        for i in range(sides):
            angle = i*math.tau/sides + .18*j
            verts.append((math.cos(angle)*rr, math.sin(angle)*rr, zz+.15*math.sin(i*2.3)))
    faces = [tuple(reversed(range(sides)))]
    for j in range(3):
        for i in range(sides):
            n = (i+1)%sides
            f = (j*sides+i, j*sides+n, (j+1)*sides+n, (j+1)*sides+i)
            if snow and j >= 1:
                a.surface(verts, [f], SNOW)
            else:
                a.surface(verts, [f], colors)
    faces.append(tuple(3*sides+i for i in range(sides)))
    a.surface(verts, faces, colors)


def pine():
    a = Asset('PinheiroNevado', 'Pinheiro nevado', 'Gelo', 'Árvores')
    root_spread(a, .7)
    tube(a, [(0, 0, .3), (.12, 0, 8), (0, 0, 16.7)], [.7, .38, .08])
    for z, r, h in [(2, 4.8, 6), (5.3, 4, 5.7), (8.5, 3.1, 5.1), (11.5, 2.1, 5)]:
        tier(a, z, r, h, PINE, snow=True)
    return a


def willow():
    a = Asset('SalgueiroPantano', 'Salgueiro do pântano', 'Pântano', 'Árvores')
    root_spread(a, 1.3, BARK, count=6, height=1.7)
    tube(a, [(0, 0, 1), (.5, 0, 4.5), (0, .4, 8.5), (-.5, .1, 10.4)], [1, .85, .58, .14])
    for i in range(6):
        angle = i*math.tau/6+.2
        d = Vector((math.cos(angle), math.sin(angle), 0))
        p = d*3.7+Vector((0, 0, 10.8+i%2*.8))
        tube(a, [(0, 0, 5.6), d*1.9+Vector((0, 0, 9.1)), p], [.43, .31, .08])
        blob(a, p, (2.9, 2.6, 1.8), SWAMP, rings=3)
        for j in range(2):
            angle2 = angle+(j-.5)*.45
            q = Vector((math.cos(angle2), math.sin(angle2), 0))
            leaf(a, p+q*1.1, p+q*(2+j*.35)+Vector((0, 0, -5.5)), .5, SWAMP, sag=.5, steps=5, curl=.35)
    return a


def burnt():
    a = Asset('ArvoreCarbonizada', 'Árvore carbonizada', 'Vulcão', 'Árvores')
    root_spread(a, 1, CHAR)
    tube(a, [(0, 0, .4), (-.3, 0, 4.2), (.5, .2, 7.2), (-.2, .3, 12)], [1.05, .8, .53, .07], CHAR)
    for points, radii in [([(0, 0, 4.8), (-2.4, .2, 6.5), (-3.5, 0, 10)], [.5, .28, .04]),
                          ([(0, 0, 6.4), (2.8, .5, 8), (4, .1, 9.7)], [.45, .23, .04]),
                          ([(.2, 0, 8.2), (.5, -2.1, 10.1), (1.2, -2, 12.7)], [.3, .2, .04])]:
        tube(a, points, radii, CHAR)
    for x, y, z in [(.7, -.38, 2.2), (.62, -.24, 5.5), (-2.5, -.17, 7.6), (.15, -.18, 9.3)]:
        leaf(a, (x, y, z), (x+.16, y-.03, z+1.3), .09, [EMBER[0]], sag=0, steps=2, curl=0, glow=True)
    return a


def shrubs(flowered=False):
    a = Asset('ArbustoFlorido' if flowered else 'ArbustoRedondo', 'Arbusto florido' if flowered else 'Arbusto arredondado', 'Campo', 'Vegetação')
    for x, y, z, r in [(-1.1, .1, 1.2, 1.45), (1.1, .2, 1.5, 1.65), (0, -.6, 1.95, 1.75)]:
        blob(a, (x, y, z), (r, r*.9, r*.85), GREEN, rings=3)
    if flowered:
        for p in [(-1.3, -1.1, 2), (.25, -1.6, 2.3), (1.5, -.9, 2.4), (.5, .5, 3.1)]:
            flower(a, Vector(p), .43, PINK[2], CREAM[0], stem=False)
    return a


def fern():
    a = Asset('Samambaia', 'Samambaia aberta', 'Floresta', 'Vegetação')
    for i in range(7):
        angle = i*math.tau/7
        d = Vector((math.cos(angle), math.sin(angle), 0))
        side = Vector((-d.y, d.x, 0))
        end = d*(2.6+(i%2)*.5)+Vector((0, 0, 1.6))
        tube(a, [(0, 0, .1), d*1+Vector((0, 0, 1.8)), end], [.06, .045, .015], [TROPICAL[1]], sides=4, collision=False)
        for j in range(1, 6):
            t = j/6
            p = d*2.8*t+Vector((0, 0, 2.6*math.sin(t*math.pi*.74)))
            for sign in (-1, 1):
                tip = p+side*sign*(1-t)*1.15+d*.45+Vector((0, 0, -.12))
                leaf(a, p, tip, .18*(1-t)+.035, TROPICAL, sag=.15, steps=2, curl=.06)
    return a


def flower(a, p, radius, petal_color, center_color, stem=True):
    if stem:
        tube(a, [Vector((p.x, p.y, .08)), p+Vector((-.08, .03, -.6)), p], [.07, .055, .035], [GREEN[0]], sides=5, collision=False)
        leaf(a, (p.x, p.y, p.z*.45), (p.x+.6, p.y+.2, p.z*.6), .18, [GREEN[1]], steps=2)
    for j in range(5):
        angle = j*math.tau/5
        d = Vector((math.cos(angle), math.sin(angle), 0))
        blob(a, p+d*radius*.65, (radius*.48, radius*.48, radius*.19), [petal_color], segments=5, rings=2)
    blob(a, p+Vector((0, 0, radius*.11)), (radius*.3, radius*.3, radius*.22), [center_color], segments=7, rings=2)


def flowers():
    a = Asset('FloresSilvestres', 'Flores silvestres', 'Campo', 'Vegetação')
    for i, p in enumerate([(-1.2, 0, 1.4), (-.2, .55, 2.2), (.5, -.65, 1.6), (1.2, .4, 1.9), (-.65, -.8, 1.7)]):
        flower(a, Vector(p), .52 if i%2 else .62, CREAM[0] if i%2 else PINK[2], (1, .73, .2))
    return a


def mushrooms():
    a = Asset('CogumelosLuminosos', 'Cogumelos luminosos', 'Pântano', 'Vegetação')
    for x, y, h, r in [(-1, 0, 2.6, 1.3), (1.1, .2, 1.8, .9), (.4, -1.2, 1.1, .65)]:
        tube(a, [(x, y, .08), (x+.1, y, h*.65), (x, y, h)], [.18, .16, .12], [CREAM[0]], sides=6, collision=False)
        blob(a, (x, y, h), (r, r, r*.45), [VOID[0], VOID[1]], segments=9, rings=4)
        # A luminous rim is geometry, not PointLights or particle emitters.
        tube(a, [(x, y, h-.12), (x, y, h+.02)], [r*.96, r*.98], [VOID[2]], sides=10, collision=False, glow=True)
        for k in range(3):
            t = k*math.tau/3+.4
            blob(a, (x+math.cos(t)*r*.55, y+math.sin(t)*r*.55, h+r*.38), (.13*r, .13*r, .045), [CREAM[0]], segments=5, rings=2)
    return a


def cactus():
    a = Asset('CactoRamificado', 'Cacto ramificado', 'Deserto', 'Vegetação')
    colors = palette(['367C68', '5CAC70', '9BCB7E'])
    tube(a, [(0, 0, .1), (0, 0, 2.8), (.1, 0, 6), (0, 0, 7)], [.66, .75, .65, .24], colors, sides=8)
    for s, z in [(-1, 2.6), (1, 4.1)]:
        tube(a, [(0, 0, z), (s*1.45, 0, z), (s*2.1, 0, z+.6), (s*2.1, 0, z+2.1)], [.43, .44, .36, .12], colors, sides=7)
    for z in [1.3, 2.4, 3.5, 4.6, 5.7]:
        for s in (-1, 1):
            leaf(a, (s*.41, -.59, z), (s*.61, -.72, z+.25), .035, CREAM, steps=1, sag=0, curl=0)
    flower(a, Vector((.02, 0, 7.14)), .55, PINK[1], CREAM[0], stem=False)
    return a


def rock(a, center, scale, colors=STONE):
    c, s = Vector(center), Vector(scale)
    sides = 7
    verts = []
    for j, (r, z) in enumerate([(.58, 0), (1, .23), (.83, .73), (.42, 1)]):
        for i in range(sides):
            angle = i*math.tau/sides + j*.11
            jitter = 1+.13*math.sin(i*2.31+j*2.1)
            verts.append(c+Vector((s.x*r*math.cos(angle)*jitter, s.y*r*math.sin(angle)*jitter, s.z*z)))
    faces = [tuple(reversed(range(sides)))]
    for j in range(3):
        for i in range(sides):
            n = (i+1)%sides
            faces.extend([(j*sides+i, j*sides+n, (j+1)*sides+n), (j*sides+i, (j+1)*sides+n, (j+1)*sides+i)])
    faces.append(tuple(3*sides+i for i in range(sides)))
    a.surface(verts, faces, colors, True)


def rocks(kind):
    names = [('PedraMusgo', 'Pedras com musgo', 'Floresta', STONE), ('RochaArenito', 'Rochas de arenito', 'Deserto', SAND), ('RochaVulcanica', 'Rocha vulcânica', 'Vulcão', BASALT)]
    ident, title, biome, colors = names[kind]
    a = Asset(ident, title, biome, 'Rochas')
    rock(a, (0, .2, 0), (2.3, 1.7, 2.9), colors)
    rock(a, (2, -.3, 0), (1.15, 1.3, 1.5), colors)
    rock(a, (-1.7, -.9, 0), (.85, .9, 1.1), colors)
    if kind == 0:
        blob(a, (-.3, .2, 2.65), (1.3, .9, .22), MOSS, segments=7, rings=2)
        blob(a, (1.9, -.3, 1.35), (.7, .6, .18), MOSS, segments=6, rings=2)
    elif kind == 2:
        for p, q in [((-.9, -1.3, .6), (-.6, -1.1, 1.8)), ((.5, -1.45, .5), (.9, -1, 2.3))]:
            leaf(a, p, q, .07, [EMBER[0]], steps=2, sag=0, curl=0, glow=True)
    return a


def log(stump=False):
    a = Asset('TocoRaizes' if stump else 'TroncoCaido', 'Toco com raízes' if stump else 'Tronco caído com musgo', 'Floresta', 'Troncos')
    if stump:
        root_spread(a, 1.05)
        tube(a, [(0, 0, .25), (.15, 0, 1.3), (0, 0, 2.5)], [1.1, .9, .85], BARK, sides=9)
        tube(a, [(0, 0, 2.5), (0, 0, 2.53)], [.7, .7], CREAM, sides=9)
        tube(a, [(0, 0, 2.54), (0, 0, 2.56)], [.38, .38], [BARK[1]], sides=9)
    else:
        tube(a, [(-3.6, 0, .97), (-1.5, .1, 1), (1.3, 0, .95), (3.6, .2, .94)], [.8, .96, .91, .75], BARK, sides=9)
        for s in (-1, 1):
            tube(a, [(s*3.6, .1, .95), (s*3.64, .1, .95)], [.65, .65], CREAM, sides=9)
            tube(a, [(s*3.65, .1, .95), (s*3.67, .1, .95)], [.32, .32], [BARK[1]], sides=9)
        tube(a, [(.6, .1, 1.3), (.7, .6, 2.1), (1.8, .7, 2.6)], [.35, .24, .06])
        blob(a, (-1.1, .05, 1.85), (1.5, .7, .25), MOSS, segments=7, rings=2)
    return a


def crystal(a, base, h, r, colors):
    b = Vector(base)
    sides = 5
    verts = []
    for j, (rr, z, lean) in enumerate([(r*.65, 0, 0), (r, h*.22, .1), (r*.8, h*.72, .22)]):
        for i in range(sides):
            angle = i*math.tau/sides
            verts.append(b+Vector((rr*math.cos(angle)+lean, rr*math.sin(angle), z)))
    verts.append(b+Vector((.4, -.1, h)))
    faces = [tuple(reversed(range(sides)))]
    for j in range(2):
        for i in range(sides):
            n = (i+1)%sides
            faces.append((j*sides+i, j*sides+n, (j+1)*sides+n, (j+1)*sides+i))
    faces.extend((2*sides+i, 2*sides+(i+1)%sides, 3*sides) for i in range(sides))
    a.surface(verts, faces, colors, True)


def crystals(void=False):
    a = Asset('CristaisVazio' if void else 'CristaisGelo', 'Cristais do vazio' if void else 'Cristais de gelo', 'Vazio' if void else 'Gelo', 'Cristais')
    colors = VOID if void else ICE
    for p, h, r in [((0, 0, 0), 5.7, .85), ((-1.4, -.2, 0), 3.4, .7), ((1.2, .4, 0), 3.8, .7), ((.6, -1, 0), 2.4, .55)]:
        crystal(a, p, h, r, colors)
    # Small bright cores remain under two extra material groups.
    for x, y in [(-.5, -.6), (.8, -.4)]:
        blob(a, (x, y, .28), (.24, .24, .25), [colors[2]], segments=5, rings=2, glow=True)
    return a


def reeds():
    a = Asset('JuncoPantano', 'Juncos do pântano', 'Pântano', 'Vegetação')
    for i, (x, y, h) in enumerate([(-.9, .3, 3.7), (0, 0, 4.6), (.8, .5, 4.1), (-.3, -.7, 3.2), (1.1, -.6, 3.5)]):
        tube(a, [(x, y, .05), (x+.12, y, h*.6), (x+.22, y, h)], [.055, .045, .025], [GREEN[0]], sides=5, collision=False)
        blob(a, (x+.22, y, h-.2), (.19, .19, .62), [BARK[0], BARK[1]], segments=6, rings=3)
        for sign in (-1, 1):
            leaf(a, (x, y, .1), (x+sign*(.6+i%2*.4), y+.3, h*.7), .13, [SWAMP[1], SWAMP[2]], sag=.6, steps=4, curl=.3)
    return a


if STAGE == 'prototype':
    campestre()
else:
    for build in (campestre, sakura, palm, pine, willow, burnt,
                  lambda: shrubs(True), shrubs, fern, flowers, mushrooms, cactus,
                  lambda: rocks(0), lambda: rocks(1), lambda: rocks(2), log,
                  lambda: log(True), crystals, lambda: crystals(True), reeds):
        build()
for asset in models:
    asset.finish()

data = {'Revision': 'Decoracao_v1', 'Models': [a.data for a in models]}
geometry_path = os.path.join(OUT, 'geometry_prototype.json' if STAGE == 'prototype' else 'geometry.json')
with open(geometry_path, 'w', encoding='utf-8') as handle:
    json.dump(data, handle, ensure_ascii=False, separators=(',', ':'))

# Export each asset at its own ground origin, restoring the presentation layout.
for obj in scene.objects:
    obj.select_set(False)
fbx_results = []
for asset in models:
    try:
        for obj in asset.objects:
            obj.location = (0, 0, 0)
            obj.select_set(True)
        bpy.context.view_layer.objects.active = asset.objects[0]
        suffix = '_Prototype' if STAGE == 'prototype' else ''
        filename = os.path.join(OUT, 'Exportacoes', asset.id + suffix + '.fbx')
        bpy.ops.export_scene.fbx(filepath=filename, use_selection=True,
                                 object_types={'MESH'}, axis_forward='-Z', axis_up='Y',
                                 apply_unit_scale=False, bake_anim=False, add_leaf_bones=False,
                                 use_mesh_modifiers=True, path_mode='AUTO')
        fbx_results.append({'Id': asset.id, 'Exported': True})
    finally:
        for obj in asset.objects:
            obj.location = asset.origin
            obj.select_set(False)

# Camera and lights belong to this new scene only. No gameplay object is exported.
target = Vector((0, 0, 8)) if STAGE == 'prototype' else Vector((60, 47, 5))
camera_data = bpy.data.cameras.new(SCENE_NAME + '_Camera')
camera = bpy.data.objects.new(SCENE_NAME + '_Camera', camera_data)
scene.collection.objects.link(camera)
camera.location = target + Vector((32, -47, 27)) if STAGE == 'prototype' else target + Vector((100, -150, 115))
camera.rotation_euler = (target-camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 25 if STAGE == 'prototype' else 173
scene.camera = camera
world = bpy.data.worlds.new(SCENE_NAME + '_World')
world.use_nodes = True
background = next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND')
background.inputs['Color'].default_value = (.13, .18, .24, 1)
background.inputs['Strength'].default_value = .45
scene.world = world
for name, location, energy, size in [('Key', (-15, -25, 60), 18000, 42), ('Fill', (80, 55, 55), 12000, 52)]:
    lamp_data = bpy.data.lights.new(SCENE_NAME + '_' + name, 'AREA')
    lamp_data.energy = energy
    lamp_data.shape = 'DISK'
    lamp_data.size = size
    lamp = bpy.data.objects.new(lamp_data.name, lamp_data)
    scene.collection.objects.link(lamp)
    lamp.location = location if STAGE == 'prototype' else Vector(location)+Vector((40, 30, 0))
    lamp.rotation_euler = (target-lamp.location).to_track_quat('-Z', 'Y').to_euler()
scene.render.resolution_x, scene.render.resolution_y = (1600, 1200) if STAGE == 'all' else (900, 900)
scene.render.resolution_percentage = 100
try:
    scene.view_settings.view_transform = 'Standard'
except TypeError:
    pass
for area in bpy.context.screen.areas:
    if area.type == 'VIEW_3D':
        area.spaces.active.region_3d.view_perspective = 'CAMERA'

blend_path = os.path.join(OUT, 'CatalogoDecoracao_Prototipo.blend' if STAGE == 'prototype' else 'CatalogoDecoracao.blend')
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(json.dumps({'Stage': STAGE, 'Scene': SCENE_NAME, 'Models': len(models),
                  'Parts': sum(len(a.data['Parts']) for a in models),
                  'Triangles': sum(len(p['Triangles']) for a in models for p in a.data['Parts']),
                  'Geometry': geometry_path, 'Blend': blend_path, 'FBX': len(fbx_results)}, ensure_ascii=False))
