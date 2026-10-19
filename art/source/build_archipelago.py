"""Original v0.15 cast, livestock, products and ferry. Never rebuilds Scottie.
Run Blender --background --python art/source/build_archipelago.py.
"""
import bpy, math, importlib.util
from pathlib import Path
P=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('wivori_art',P/'build_assets.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
original_clean=a.clean
def clean_asset():
    original_clean()
    bpy.data.orphans_purge(do_recursive=True)
a.clean=clean_asset

def face(species,fur,rig):
    colors={'fox':'ce7a46','pig':'e6a0a3','duck':'fff0c2'}
    color=colors[species]
    if species=='fox':
        rings=[(0,-.13,1.47,.15,.13),(0,-.18,1.62,.38,.35),(0,-.16,1.83,.55,.39),(0,-.01,2.08,.46,.37),(0,.02,2.30,.30,.23),(0,.02,2.39,.02,.02)]
    elif species=='pig':
        rings=[(0,-.02,1.45,.16,.14),(0,-.05,1.59,.46,.35),(0,-.06,1.84,.56,.44),(0,-.02,2.10,.54,.42),(0,.02,2.31,.37,.30),(0,.02,2.40,.02,.02)]
    else:
        rings=[(0,-.03,1.44,.13,.15),(0,-.03,1.62,.34,.32),(0,-.02,1.89,.43,.38),(0,.01,2.15,.41,.36),(0,.02,2.32,.28,.24),(0,.02,2.39,.02,.02)]
    head=a.loft(species+' sculpted skull',rings,fur,36,2.15,1);a.paint(head,color);a.weight(head,'head',rig)
    cream=a.mat('Cream muzzle','fff0d1',.88);dark=a.mat('Face dark ink','29383f',.6)
    rose=a.mat('Rose ear folds','c87981',.87)
    def piece(name,at,size,mat,bone='head'):
        ob=a.bean(name,at,size,mat,2.4,20,1);a.weight(ob,bone,rig);return ob
    if species=='fox':
        muzzle=a.loft('Fox tapered cream muzzle',[(0,-.38,1.59,.14,.13),(0,-.40,1.71,.32,.24),(0,-.47,1.84,.25,.28),(0,-.40,1.94,.07,.13)],cream,28,2,1);a.weight(muzzle,'head',rig)
        piece('Fox velvet nose',(0,-.70,1.87),(.19,.13,.13),dark)
    elif species=='pig':
        snout=a.mat('Peach pig snout','f4b3b0',.8)
        piece('Wide pig snout',(0,-.43,1.77),(.54,.30,.33),snout)
        for s in [-1,1]:piece('Inset nostril',(s*.105,-.579,1.80),(.07,.026,.09),rose)
    else:
        bill=a.mat('Golden duck bill','f2b64d',.68)
        piece('Broad upper bill',(0,-.42,1.80),(.62,.51,.17),bill)
        piece('Lower bill',(0,-.40,1.74),(.54,.40,.09),bill)
        for s in [-1,1]:piece('Bill nostril',(s*.12,-.55,1.88),(.046,.037,.022),dark)
    for s in [-1,1]:
        side='L' if s<0 else 'R'
        eye_x=s*(.25 if species!='duck' else .22)
        for name,y,size,material in [('eye rim',-.345,(.25,.12,.29),dark),('eye white',-.38,(.21,.12,.25),a.mat('Eye whites','fffbe9',.28)),('pupil',-.442,(.11,.035,.16),dark),('glint',-.464,(.038,.012,.05),a.mat('Eye shine','ffffff',.18))]:
            piece(name,(eye_x,y,2.08 if name!='glint' else 2.12),size,material,'eye.'+side)
        if species=='duck':continue
        if species=='fox':rs=[(s*.33,.02,2.22,.20,.14),(s*.43,.04,2.45,.16,.10),(s*.49,.05,2.68,.015,.01)]
        else:rs=[(s*.39,.01,2.22,.20,.14),(s*.53,.01,2.38,.20,.10),(s*.63,-.03,2.26,.03,.025)]
        ear=a.loft(species+' ear',rs,fur,20,2,1);a.paint(ear,color);a.weight(ear,'ear.'+side,rig)
        inner=a.loft('Ear inner fold',[(x,y-.08,z,rx*.65,.02) for x,y,z,rx,ry in rs],rose,16,2,1);a.weight(inner,'ear.'+side,rig)
    return head

original_export=a.save_export

def export_cast(name,rigged=False):
    # Repaint paws and replace the terrier tail: no Scottie geometry survives in NPC heads/tails.
    fur_color={'fox':'ce7a46','pig':'e6a0a3','duck':'fff0c2'}[name]
    rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    for ob in list(bpy.context.scene.objects):
        if ob.type=='MESH' and ('paw' in ob.name.lower()):a.paint(ob,fur_color)
        if ob.type=='MESH' and 'Characteristic upright tail' in ob.name:
            a.PARTS.remove(ob);bpy.data.objects.remove(ob,do_unlink=True)
    fur=a.mat('Tail coat',fur_color,.9)
    points={'fox':[(0,.25,.78),(.10,.59,.66),(.15,.93,.55),(.11,1.12,.67)],'pig':[(0,.28,.82),(.07,.43,.84),(.12,.48,.95),(.02,.48,1.00),(-.04,.45,.91)],'duck':[(0,.20,.76),(0,.46,.84),(0,.57,.99)]}[name]
    tail=a.tube('Distinct '+name+' tail',points,[.17,.21,.18,.02] if name=='fox' else .04 if name=='pig' else [.17,.16,.02],fur,12);a.weight(tail,'tail',rig)
    original_export(name,rigged)

# Atlases at 512px are sufficient for small NPCs on mobile; hero stays untouched.
source=__import__('inspect').getsource(a.bake_character).replace('1024','512')
exec(source,a.__dict__)
a.head_model=face;a.save_export=export_cast
for species in ['fox','pig','duck']:a.character(species)
a.save_export=original_export

def livestock(kind):
    a.clean();fur=a.mat('Farm coat','fff0d4' if kind!='piglet' else 'e8a6aa',.9);dark=a.mat('Farm details','384044',.83);pink=a.mat('Nose rose','e8a0a4',.83)
    if kind=='hen':
        a.bean('Hen full body',(0,0,.48),(.68,1.05,.76),fur,2,24,1)
        a.bean('Hen neck',(0,-.40,.78),(.38,.40,.64),fur,2,24,1)
        a.bean('Hen head',(0,-.49,1.00),(.40,.43,.44),fur,2,24,1)
        bill=a.mat('Beak gold','ecb145',.7);a.bean('Hen beak',(0,-.75,.98),(.22,.24,.14),bill,2.5,16,1)
        comb=a.mat('Red hen comb','da6b58',.8)
        for j in range(3):a.bean('Comb',(0,-.56+j*.09,1.24),(.11,.15,.19),comb,2,12,1)
        for s in [-1,1]:
            a.bean('Hen eye',(s*.17,-.59,1.07),(.06,.07,.075),dark,2,12,0)
            a.bean('Hen wing',(s*.29,.05,.53),(.20,.66,.46),fur,2,18,1)
            a.tube('Hen leg',[(s*.17,0,.10),(s*.17,0,.28)],.035,bill,8)
        a.bean('Upright hen tail',(0,.45,.70),(.38,.30,.72),fur,2,20,1)
    else:
        a.bean('Livestock body',(0,.08,.82),(1.10,1.84,1.09),fur,2.6,28,1)
        a.bean('Rounded head',(0,-.87,1.02),(.75,.83,.76),fur,2.4,28,1)
        a.bean('Broad muzzle',(0,-1.23,.88),(.70,.26,.36),pink,2.5,24,1)
        for s in [-1,1]:
            for z in [-.49,.62]:
                a.bean('Animal leg',(s*.37,z,.35),(.26,.30,.67),fur,2.5,20,1)
                a.bean('Hoof',(s*.37,z,.10),(.29,.34,.21),dark,2.5,16,1)
            a.bean('Animal eye',(s*.30,-1.09,1.19),(.085,.07,.11),dark,2,14,0)
            a.bean('Animal nostril',(s*.17,-1.36,.92),(.075,.022,.06),dark,2,12,0)
            a.bean('Animal ear',(s*.46,-.78,1.29),(.46,.25,.20),fur,2.3,20,1)
        if kind=='cow':
            horn=a.mat('Horn ivory','e9ce94',.9)
            for s in [-1,1]:a.tube('Gentle curved horn',[(s*.26,-.78,1.30),(s*.33,-.77,1.55),(s*.28,-.74,1.67)],[.10,.075,.01],horn,12)
            a.bean('Udder',(0,.18,.36),(.52,.55,.25),pink,2,20,1)
            for s,z in [(-1,.05),(1,.26)]:a.bean('Cow patch',(s*.50,z,1.00),(.08,.71,.57),dark,2.4,20,1)
    a.save_export('farm_'+kind)
for species in ['cow','hen','piglet']:livestock(species)

def goods(kind):
    a.clean();cream=a.mat('Food cream','ffedc2',.9);gold=a.mat('Food gold','e7b451',.8);teal=a.mat('Enamel teal','469d9b',.5);ink=a.mat('Packaging ink','335d67',.8);wood=a.mat('Crate oak','ba8859',.9)
    if kind=='wheat':
        for j in range(5):
            x=(j-2)*.11;y=(j%2)*.14
            a.tube('Wheat stem',[(x,y,0),(x+.04,y,.8)],.018,gold,6)
            for k in range(4):
                for s in [-1,1]:a.bean('Wheat ear',(x+s*.065,y,.50+k*.07),(.15,.09,.14),gold,2,12,0)
    elif kind in ['milk','flour','feed','provisions','meat']:
        a.loft('Packed '+kind,[(0,0,0,.22,.17),(0,0,.08,.28,.20),(0,0,.52,.28,.20),(0,0,.64,.20,.16),(0,0,.71,.12,.10)],cream if kind!='meat' else a.mat('Butcher wrap','e6a3a2',.8),24,3,1)
        a.block('Distinct colored label',(0,-.205,.34),(.36,.025,.24),teal if kind in ['milk','feed'] else ink,.035)
        a.bean('Product seal',(0,-.23,.34),(.13,.02,.13),gold,2,14,0)
        if kind=='milk':a.lathe('Milk bottle cap',[(0,.67),(.13,.67),(.13,.74),(0,.74)],teal)
    elif kind=='bread':
        a.bean('Golden loaf',(0,0,.22),(.83,.50,.43),gold,3,28,1)
        for j in range(3):a.tube('Bread score',[(j*.20-.20,-.16,.35),(j*.20-.17,.10,.41)],.015,cream,6)
    elif kind=='cheese':
        ob=a.mesh('Cheese wedge',[(-.35,-.25,0),(.35,-.25,0),(0,.30,0),(-.35,-.25,.34),(.35,-.25,.34),(0,.30,.34)],[(0,2,1),(0,1,4,3),(1,2,5,4),(2,0,3,5),(3,4,5)],gold,False)
        for x,z in [(-.16,.13),(.12,.23)]:a.bean('Cheese dimple',(x,-.252,z),(.10,.012,.08),cream,2,12,0)
    elif kind=='egg':
        for j in range(3):a.bean('Egg',(j*.19-.19,0,.20),(.22,.23,.32),cream,2,20,1)
        a.block('Egg tray',(0,0,.05),(.70,.32,.10),wood,.04)
    a.save_export('goods_'+kind)
for item in ['wheat','milk','flour','feed','bread','cheese','egg','provisions','meat']:goods(item)

a.clean();navy=a.mat('Ferry hull blue','397f9b',.5);ivory=a.mat('Ferry ivory','fff0c9',.6);oak=a.mat('Ferry deck','b67d4e',.86);gold=a.mat('Ferry fittings','e9b44f',.4,.3);glass=a.mat('Ferry windows','70bfc7',.25,.1)
a.loft('Curved deep ferry hull',[(0,0,.10,.35,1.60),(0,0,.25,.83,2.35),(0,0,.65,1.12,2.60),(0,0,.94,1.17,2.63)],navy,48,3,1)
a.loft('Ferry cream gunwale',[(0,0,.88,1.16,2.60),(0,0,.99,1.20,2.66),(0,0,1.05,1.19,2.65)],ivory,48,3,0)
a.block('Timber deck',(0,0,.94),(2.06,4.20,.14),oak,.12)
a.block('Ferry cabin',(0,-.55,1.49),(1.55,1.60,1.02),ivory,.18)
a.block('Cabin roof',(0,-.55,2.05),(1.85,1.92,.19),navy,.12)
for x in [-.48,0,.48]:a.block('Cabin front window',(x,-1.36,1.62),(.37,.035,.48),glass,.05)
a.block('Ferry funnel',(.45,.35,2.18),(.32,.33,.69),gold,.07)
for x in [-1.03,1.03]:
    for y in [-1.65,.8,1.75]:a.tube('Rail post',[(x,y,1.02),(x,y,1.53)],.035,ivory,8)
    a.tube('Curved ferry railing',[(x,-1.85,1.53),(x,-.4,1.53),(x,1.8,1.53)],.04,ivory,8)
a.save_export('route_ferry')
a.clean();stone=a.mat('Lighthouse limewash','fff0d0',.9);red=a.mat('Lighthouse coral','d47761',.8);gold=a.mat('Lighthouse brass','efc568',.4,.3);glass=a.mat('Lighthouse glass','8adbd3',.3)
a.lathe('Tapered lighthouse',[(0,0),(1.28,0),(1.28,.35),(.86,.45),(.69,4.7),(.92,4.8),(.92,5.0),(0,5.0)],stone,sides=32)
for z in [1.4,2.9]:a.lathe('Coral lighthouse belt',[(.79,z),(.81,z),(.78,z+.45),(.76,z+.45)],red,sides=32)
a.lathe('Lantern room',[(0,5.0),(.65,5.0),(.65,5.9),(0,5.9)],glass,sides=24)
a.lathe('Lantern roof',[(0,6.6),(.95,5.95),(.95,5.85),(0,5.85)],red,sides=24)
for j in range(8):
    ang=math.tau*j/8;a.tube('Lantern brass frame',[(math.cos(ang)*.67,math.sin(ang)*.67,5),(math.cos(ang)*.67,math.sin(ang)*.67,5.92)],.035,gold,8)
a.save_export('route_lighthouse')
