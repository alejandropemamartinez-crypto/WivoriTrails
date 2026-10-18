"""Original Wivori art. Run in Blender 4.x: blender -b -P art/source/build_assets.py.

Editable loft topology, weighted deforming meshes, keyed skeleton actions and
architectural modelling are kept here alongside the .blend sources. No runtime
primitive assembly and no third-party character/architecture assets.
"""
import bpy
import math
import random
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets' / 'models'
SOURCE = ROOT / 'art' / 'source'
OUT.mkdir(parents=True, exist_ok=True)
R = random.Random(271828)
TAU = math.tau
PARTS = []
MATS = {}


def rgb(value):
    value = value.lstrip('#')
    # Blender expects linear input; glTF converts material factors appropriately.
    def linear(v):
        v = int(v, 16) / 255
        return v / 12.92 if v < .04045 else ((v + .055) / 1.055) ** 2.4
    return tuple(linear(value[i:i+2]) for i in (0, 2, 4))


def mat(name, color, rough=.65, metal=0, painted=False):
    key = (name, color, painted)
    if key in MATS:
        return MATS[key]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (*rgb(color), 1)
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = m.diffuse_color
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metal
    if painted:
        node = m.node_tree.nodes.new('ShaderNodeVertexColor')
        node.layer_name = 'Pigment'
        m.node_tree.links.new(node.outputs['Color'], p.inputs['Base Color'])
    MATS[key] = m
    return m


def clean():
    global PARTS, MATS
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    PARTS = []
    MATS = {}


def mesh(name, verts, faces, material, smooth=True):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    colors=me.color_attributes.new(name='Pigment',type='BYTE_COLOR',domain='POINT')
    for c in colors.data:c.color=(1,1,1,1)
    me.color_attributes.render_color_index=0
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    if material:
        me.materials.append(material)
    for p in me.polygons:
        p.use_smooth = smooth
    PARTS.append(ob)
    return ob


def apply(ob, modifier):
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def loft(name, rings, material, sides=24, square=2.0, subdiv=1):
    """Art-directed elliptical/superelliptic sections (x, depth, height, rx, ry)."""
    verts, faces = [], []
    for cx, cy, z, rx, ry in rings:
        for j in range(sides):
            a = TAU * j / sides
            ca, sa = math.cos(a), math.sin(a)
            x = math.copysign(abs(ca) ** (2/square), ca) * max(.002, rx)
            y = math.copysign(abs(sa) ** (2/square), sa) * max(.002, ry)
            verts.append((cx+x, cy+y, z))
    for i in range(len(rings)-1):
        for j in range(sides):
            a = i*sides+j; b = i*sides+(j+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.append(tuple(reversed(range(sides))))
    faces.append(tuple((len(rings)-1)*sides+j for j in range(sides)))
    ob = mesh(name, verts, faces, material)
    if subdiv:
        mod = ob.modifiers.new('Silhouette subdivision', 'SUBSURF')
        mod.levels = subdiv
        apply(ob, mod)
    return ob


def bean(name, center, size, material, square=2, sides=20, subdiv=1):
    x,y,z = center; sx,sy,sz = size
    rings=[]
    for h, w in [(-1,.03),(-.85,.58),(-.5,.88),(0,1),(.5,.86),(.85,.54),(1,.02)]:
        rings.append((x,y,z+h*sz*.5,sx*.5*w,sy*.5*w))
    return loft(name,rings,material,sides,square,subdiv)


def tube(name, points, radius, material, sides=8):
    # Swept curved sections follow the tangent, unlike stacked primitive rods.
    verts=[]; faces=[]
    for i, point in enumerate(points):
        p=Vector(point)
        d=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        if d.length<.001: d=Vector((0,0,1))
        d.normalize(); u=d.cross(Vector((0,1,0)))
        if u.length<.1: u=d.cross(Vector((1,0,0)))
        u.normalize(); v=d.cross(u).normalized()
        r=radius[i] if isinstance(radius,(tuple,list)) else radius
        for j in range(sides):
            a=TAU*j/sides; q=p+r*(u*math.cos(a)+v*math.sin(a)); verts.append(q)
    for i in range(len(points)-1):
        for j in range(sides):
            a=i*sides+j; b=i*sides+(j+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple((len(points)-1)*sides+j for j in range(sides))]
    return mesh(name,verts,faces,material)


def block(name, at, size, material, bevel=.04, rot=(0,0,0)):
    x,y,z=at; a,b,c=[s*.5 for s in size]
    verts=[(-a,-b,-c),(a,-b,-c),(a,b,-c),(-a,b,-c),(-a,-b,c),(a,-b,c),(a,b,c),(-a,b,c)]
    ob=mesh(name,verts,[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],material,False)
    if bevel:
        mod=ob.modifiers.new('Soft crafted edges','BEVEL'); mod.width=bevel; mod.segments=2; apply(ob,mod)
        for p in ob.data.polygons: p.use_smooth=True
        mod=ob.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL'); apply(ob,mod)
    ob.location=at; ob.rotation_euler=rot
    return ob


def paint(ob, color, brindle=False):
    base=rgb(color)
    old=ob.data.color_attributes.get('Pigment')
    if old: ob.data.color_attributes.remove(old)
    attr=ob.data.color_attributes.new(name='Pigment',type='BYTE_COLOR',domain='POINT')
    ob.data.color_attributes.render_color_index=ob.data.color_attributes.find('Pigment')
    for v,c in zip(ob.data.vertices,attr.data):
        x,y,z=v.co
        noise=.5+.5*math.sin(x*11+z*3+math.sin(y*9)*.8)
        streak=.5+.5*math.sin(x*24+z*5+math.sin(z*11+y*9)*1.4)
        factor=(.76+.38*noise+.12*streak) if brindle else (.94+.09*noise)
        # A darker underside provides painted ambient depth without SSAO.
        factor*=.87+.13*max(0,min(1,(z-.3)/2))
        c.color=(*[min(1,b*factor) for b in base],1)


def weight(ob, bone, rig, mapper=None):
    if mapper:
        groups={}
        for v in ob.data.vertices:
            for key, val in mapper(v.co).items():
                if val <= .0001: continue
                if key not in groups: groups[key]=ob.vertex_groups.new(name=key)
                groups[key].add([v.index],val,'REPLACE')
    else:
        group=ob.vertex_groups.new(name=bone)
        group.add(list(range(len(ob.data.vertices))),1,'REPLACE')
    ob.parent=rig
    mod=ob.modifiers.new('Deform with character skeleton','ARMATURE'); mod.object=rig


def make_rig():
    arm=bpy.data.armatures.new('Wivori anatomical skeleton')
    rig=bpy.data.objects.new('WivoriRig',arm); bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig; rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bones={
        'root':((0,0,.02),(0,0,.3),None),
        'pelvis':((0,0,.65),(0,0,.98),'root'),
        'spine':((0,0,.98),(0,0,1.48),'pelvis'),
        'head':((0,0,1.48),(0,0,2.21),'spine'),
        'ear.L':((-.35,0,2.31),(-.48,0,2.88),'head'),
        'ear.R':((.35,0,2.31),(.48,0,2.88),'head'),
        'arm.L':((-.38,0,1.35),(-.51,0,.98),'spine'),
        'arm.R':((.38,0,1.35),(.51,0,.98),'spine'),
        'hand.L':((-.51,0,.98),(-.56,-.02,.78),'arm.L'),
        'hand.R':((.51,0,.98),(.56,-.02,.78),'arm.R'),
        'leg.L':((-.22,0,.66),(-.23,0,.33),'pelvis'),
        'leg.R':((.22,0,.66),(.23,0,.33),'pelvis'),
        'foot.L':((-.23,0,.33),(-.23,-.24,.12),'leg.L'),
        'foot.R':((.23,0,.33),(.23,-.24,.12),'leg.R'),
        'tail':((0,.24,.74),(0,.62,1.12),'pelvis'),
        'eye.L':((-.24,-.39,2.11),(-.24,-.39,2.25),'head'),
        'eye.R':((.24,-.39,2.11),(.24,-.39,2.25),'head'),
    }
    for key,(h,t,parent) in bones.items():
        b=arm.edit_bones.new(key); b.head=h; b.tail=t
        if parent: b.parent=arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT'); rig.select_set(False)
    return rig


def head_model(species, fur, rig):
    scottie=species=='terrier'; rabbit=species=='rabbit'; raccoon=species=='raccoon'
    # Continuous head includes a squared muzzle and chin. Different profiles are
    # designed per animal rather than attaching a sphere as a face.
    if scottie:
        rings=[(0,-.24,1.25,.13,.20),(0,-.24,1.32,.39,.32),(0,-.25,1.47,.49,.43),(0,-.25,1.68,.52,.56),
               (0,-.23,1.86,.51,.56),(0,-.24,1.96,.46,.54),(0,-.12,2.08,.46,.44),(0,-.025,2.24,.47,.39),
               (0,.015,2.39,.37,.31),(0,.02,2.46,.15,.16),(0,.02,2.47,.02,.02)]
    else:
        rings=[(0,-.05,1.46,.13,.14),(0,-.09,1.54,.35,.31),(0,-.12,1.72,.48,.40),
               (0,-.065,1.94,.51,.43),(0,0,2.16,.46,.37),(0,.015,2.33,.31,.27),
               (0,.02,2.39,.12,.13),(0,.02,2.40,.02,.02)]
    head=loft('Sculpted continuous head and muzzle',rings,fur,48,2.7 if scottie else 2.15,1)
    if scottie:
        # Weld full sculpted brow ridges into the skull. They share the same
        # continuous skin, with soft fur edges rather than detached white parts.
        brows=[]
        for sign in (-1,1):
            brows.append(loft('Sculpted terrier brow',[(sign*.30,-.47,2.17,.12,.08),(sign*.29,-.51,2.24,.19,.13),(sign*.23,-.44,2.32,.15,.11),(sign*.20,-.36,2.37,.01,.02)],fur,20,2.5,1))
        bpy.ops.object.select_all(action='DESELECT');head.select_set(True)
        for brow_ob in brows:brow_ob.select_set(True)
        bpy.context.view_layer.objects.active=head;bpy.ops.object.join()
        for brow_ob in brows:PARTS.remove(brow_ob)
        sculpt=head.modifiers.new('Welded organic beard and brows','REMESH');sculpt.mode='VOXEL';sculpt.voxel_size=.024;sculpt.use_smooth_shade=True;apply(head,sculpt)
        polish=head.modifiers.new('Sculpt surface relaxation','SMOOTH');polish.factor=.6;polish.iterations=3;apply(head,polish)
        reduce=head.modifiers.new('Android sculpt topology','DECIMATE');reduce.ratio=.58;apply(head,reduce)
        for face in head.data.polygons:face.use_smooth=True
    if scottie:
        for v in head.data.vertices:
            x,y,z=v.co
            front=max(0,min(1,(-y-.12)/.32))
            ridge=math.exp(-((z-2.23)/.09)**2)*math.exp(-((abs(x)-.28)/.20)**2)*front
            v.co.y-=ridge*.19
            if z<1.76 and y<-.28:
                v.co.z-=.045*front*(.6+.4*math.cos(x*26))
        head.data.update()
    paint(head,'8b9199' if scottie else ('e6d9c2' if rabbit else '9c9895'),scottie)
    if scottie:
        attr=head.data.color_attributes['Pigment']
        grey=rgb('9da6af')
        for v,c in zip(head.data.vertices,attr.data):
            x,y,z=v.co
            beard=max(0,min(1,(1.91-z)/.30))*max(0,min(1,(-y-.21)/.30))
            brow=math.exp(-((z-2.23)/.09)**2)*max(0,min(1,(-y-.23)/.20))*.65
            blend=max(beard*.88,brow)
            stripe=.94+.08*(.5+.5*math.sin(x*18+z*3+math.sin(z*9)*.6))
            c.color=(*[c.color[i]*(1-blend)+grey[i]*stripe*blend for i in range(3)],1)
    def head_weights(v):
        return {'head':1}
    weight(head,'head',rig)
    # The muzzle front is the actual surface, with an inset nose, soft cheeks,
    # fur tufts and brows anchored deeply in it, all weighted to the same skull.
    nose=mat('Velvet nose','232b32',.31)
    pink=mat('Ear velvet','c88e8e',.89)
    brow=mat('Silver whiskers' if scottie else 'Light muzzle','a4acb4' if scottie else 'f5e8d2',.9)
    tip_y=-.80 if scottie else -.474
    nose_ob=bean('Nose embedded in muzzle',(0,tip_y,1.95 if scottie else 1.80),(.30 if scottie else .17,.11,.19 if scottie else .12),nose,3,24,1)
    weight(nose_ob,'head',rig)
    highlight=mat('Nose soft highlight','5c6871',.35)
    n=bean('Nose highlight',(-.045,tip_y-.055,2.00 if scottie else 1.83),(.065,.009,.026),highlight,2,12,0);weight(n,'head',rig)
    for sign in (-1,1):
        # Shaped ridges, tapered locks and asymmetry keep the terrier beard square.
        if scottie:
            # Beard and eyebrows are sculpted and painted on the continuous
            # head below. No pale tooth-like whisker islands are attached.
            pass
        else:
            cheek=bean('Soft muzzle cheek',(sign*.16,-.422,1.73),(.32,.15,.21),brow,2,20,1);weight(cheek,'head',rig)
        # Eyes are seated into the face; the back halves intersect the head.
        eye_x=sign*(.285 if scottie else .245)
        eye_y=-.49 if scottie else -.388
        eye_z=2.13 if scottie else 2.06
        socket=mat('Eye rim','30383d' if scottie else '786858',.8)
        white=mat('Warm eye whites','fff9e8',.25)
        iris=mat('Hazel iris','66523c',.25)
        pupil=mat('Deep pupils','172b30',.15)
        sparkle=mat('Eye glints','ffffff',.16)
        bn='eye.L' if sign<0 else 'eye.R'
        for name,dy,dz,size,material in [
            ('Recessed eye socket',.028,0,(.267,.13,.301),socket),
            ('Eye seated on socket',-.015,0,(.226,.125,.257),white),
            ('Hazel iris',-.080,-.012,(.135,.032,.167),iris),
            ('Pupil',-.096,-.012,(.083,.020,.126),pupil),
            ('Large eye glint',-.111,.035,(.039,.008,.052),sparkle),
            ('Small eye glint',-.112,-.039,(.016,.006,.020),sparkle)]:
            ob=bean(name,(eye_x,eye_y+dy,eye_z+dz),size,material,2,20,1 if 'Eye ' in name else 0)
            weight(ob,bn,rig)
        # Organic ears with curved asymmetric sections, not cone primitives.
        if rabbit:
            rs=[(sign*.32,.02,2.22,.135,.12),(sign*.39,.03,2.45,.15,.105),(sign*.47,.035,2.79,.14,.085),(sign*.49,.045,3.04,.09,.055),(sign*.48,.05,3.14,.01,.015)]
        elif scottie:
            rs=[(sign*.34,.025,2.29,.20,.14),(sign*.40,.045,2.46,.18,.115),(sign*.48,.065,2.72,.10,.075),(sign*.51,.07,2.89,.012,.018)]
        else:
            rs=[(sign*.37,.015,2.22,.18,.14),(sign*.42,.035,2.39,.17,.105),(sign*.45,.05,2.54,.105,.065),(sign*.46,.06,2.60,.015,.015)]
        ear=loft('Organic ear '+str(sign),rs,fur,20,2,2);paint(ear,'989da5' if scottie else ('e6d9c2' if rabbit else '9c9895'),scottie)
        eb='ear.L' if sign<0 else 'ear.R'
        weight(ear,eb,rig,lambda v,eb=eb: {eb:max(0,min(1,(v.z-2.28)/.22)),'head':1-max(0,min(1,(v.z-2.28)/.22))})
        inner=loft('Inner ear velvet',[(x,y-ry*.78,z,rx*.56,.018) for x,y,z,rx,ry in rs[1:]],pink,14,2,1)
        weight(inner,eb,rig)
    if raccoon:
        # Mask is vertex-painted into the actual face, never a floating plate.
        attr=head.data.color_attributes['Pigment']
        dark=rgb('3b4650')
        for v,c in zip(head.data.vertices,attr.data):
            x,y,z=v.co
            if y<-.20 and 1.93<z<2.21 and abs(x)>.09:
                c.color=(*dark,1)
    # Mouth line follows the muzzle, with no separate teeth.
    line=mat('Smile crease','4c4947',.92)
    mouth=tube('Small friendly smile',[(-.12,-.47 if not scottie else -.73,1.66), (0,-.485 if not scottie else -.75,1.64),(.12,-.47 if not scottie else -.73,1.66)],.012,line,6)
    weight(mouth,'head',rig)
    return head


def animate(rig):
    rig.animation_data_create()
    durations={'idle':60,'walk':30,'run':24,'turn':24,'harvest':30,'carry':30,'deliver':30,'collect':30,'celebrate':42,'surprise':30,'intercept':30,'build':36,'alert':36,'relief':42}
    for name,frames in durations.items():
        action=bpy.data.actions.new(name); action.use_fake_user=True
        rig.animation_data.action=action
        for f in range(0,frames+1,3):
            t=f/frames; p=math.sin(t*TAU); q=math.cos(t*TAU); hump=math.sin(t*math.pi)
            for bone in rig.pose.bones:
                bone.rotation_mode='XYZ'; bone.rotation_euler=(0,0,0);bone.location=(0,0,0);bone.scale=(1,1,1)
            def rotate(b,x=0,y=0,z=0): rig.pose.bones[b].rotation_euler=(x,y,z)
            rotate('spine',.012*math.sin(t*TAU),0,.008*p)
            rotate('tail',.05,0,.12*p)
            for b in ['ear.L','ear.R']: rotate(b,.028*p,0,0)
            if name in ['walk','run','carry']:
                stride=.62 if name=='run' else .45
                rotate('leg.L',p*stride);rotate('leg.R',-p*stride)
                # Knee-less short paws use separate ankle compensation.
                rotate('foot.L',-max(0,p)*.32);rotate('foot.R',max(0,p)*.32)
                rotate('arm.L',-p*.48,0,-.10);rotate('arm.R',p*.48,0,.10)
                rig.pose.bones['pelvis'].location.y=.035*abs(p)
                rotate('spine',.10 if name=='run' else .025,0,.045*p)
                rotate('head',-.045,0,-.025*p)
                for b in ['ear.L','ear.R']:rotate(b,.10*q,0,0)
                if name=='carry': rotate('arm.L',-1.0,0,-.20);rotate('arm.R',-1.0,0,.20)
            elif name in ['harvest','collect','deliver','build']:
                rotate('spine',hump*(.29 if name in ['collect','harvest'] else .14))
                rotate('arm.L',-hump*(1.25 if name!='build' else 1.8),.1,-.15)
                rotate('arm.R',-hump*(1.12 if name!='build' else 1.3),-.1,.15)
                rotate('head',-hump*.12)
                rotate('leg.L',-hump*.15);rotate('leg.R',-hump*.15)
            elif name in ['celebrate','relief']:
                rig.pose.bones['pelvis'].location.y=.13*abs(p)
                rotate('arm.L',-.5*hump,0,-1.3*hump);rotate('arm.R',-.5*hump,0,1.3*hump)
                rotate('head',-.12*hump,0,.12*p);rotate('tail',0,0,.4*p)
            elif name in ['surprise','alert']:
                rotate('spine',-.16*hump,0,.045*p)
                rotate('arm.L',-.5,0,-.8-.15*p);rotate('arm.R',-.6,0,.8+.15*p)
                rotate('head',-.12,0,.10*p)
                rotate('ear.L',-.14,0,-.17*p);rotate('ear.R',-.14,0,.17*p)
            elif name=='intercept':
                rotate('spine',.22*hump,0,.15*p);rotate('arm.L',-1.6*hump,0,-.15);rotate('arm.R',-.8*hump,0,.15)
                rotate('head',-.10*hump,0,.12*p)
            elif name=='turn': rotate('head',0,.42*p,0);rotate('spine',0,-.12*p,0)
            if name=='idle':
                # Eyelids squash with eye bones; both eyes remain in their sockets.
                blink=max(.08,1-1.1*math.exp(-((t-.72)/.035)**2))
                for b in ['eye.L','eye.R']:rig.pose.bones[b].scale.y=blink
            for b in rig.pose.bones:
                b.keyframe_insert('rotation_euler',frame=f,group=b.name)
                b.keyframe_insert('location',frame=f,group=b.name)
                b.keyframe_insert('scale',frame=f,group=b.name)
        track=rig.animation_data.nla_tracks.new();track.name=name
        strip=track.strips.new(name,0,action);strip.name=name
    rig.animation_data.action=None
    for track in rig.animation_data.nla_tracks:track.mute=True
    bpy.context.scene.frame_set(0)
    for b in rig.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0);b.scale=(1,1,1)


def character(species):
    clean(); rig=make_rig()
    fur=mat('Brindle grey coat' if species=='terrier' else 'Hand shaded fur','989da5' if species=='terrier' else ('e6d9c2' if species=='rabbit' else '9c9895'),.92,painted=True)
    teal=mat('Woven teal canvas','318c88' if species=='terrier' else ('d39a63' if species=='rabbit' else '63788a'),.86)
    dark=mat('Indigo work clothes','314a5a',.88)
    gold=mat('Warm brass fittings','eac16c',.37,.32)
    linen=mat('Cream stitching','f6dfae',.85)
    leather=mat('Cognac leather','a16c46',.85)
    body=loft('Tailored organic torso',[(0,0,.57,.23,.19),(0,.015,.66,.36,.29),(0,.025,.89,.43,.32),(0,.005,1.15,.39,.29),(0,0,1.36,.30,.22),(0,0,1.47,.18,.17)],teal,28,2.3,2)
    weight(body,'spine',rig,lambda v:{'spine':max(0,min(1,(v.z-.68)/.52)),'pelvis':1-max(0,min(1,(v.z-.68)/.52))})
    head_model(species,fur,rig)
    for s in (-1,1):
        side='L' if s<0 else 'R'
        arm=loft('Cloth sleeve '+side,[(s*.33,0,1.34,.14,.14),(s*.43,0,1.23,.16,.15),(s*.48,-.01,1.05,.14,.13),(s*.51,-.025,.94,.105,.105)],teal,20,2,2)
        weight(arm,'arm.'+side,rig,lambda v,side=side: {'arm.'+side:max(0,min(1,(v.z-.91)/.24)),'hand.'+side:1-max(0,min(1,(v.z-.91)/.24))})
        paw=bean('Shaped working paw '+side,(s*.53,-.035,.86),(.26,.25,.28),fur,2.4,24,1)
        paint(paw,'989da5' if species=='terrier' else ('e6d9c2' if species=='rabbit' else '9c9895'),species=='terrier');weight(paw,'hand.'+side,rig)
        leg=loft('Short trouser leg '+side,[(s*.22,0,.68,.19,.22),(s*.24,0,.52,.19,.20),(s*.24,-.005,.30,.17,.18),(s*.24,-.03,.20,.17,.19)],dark,20,2.6,2);weight(leg,'leg.'+side,rig)
        foot=bean('Broad terrier paw '+side,(s*.24,-.10,.135),(.39,.56,.27),fur,3,24,1)
        paint(foot,'989da5' if species=='terrier' else ('e6d9c2' if species=='rabbit' else '9c9895'),species=='terrier');weight(foot,'foot.'+side,rig)
        # Overall shoulder straps and small stitch details.
        strap=tube('Overall strap '+side,[(s*.21,-.21,1.41),(s*.24,-.285,1.27),(s*.24,-.307,1.10)],.045,dark,8);weight(strap,'spine',rig)
        button=bean('Brass overall button',(s*.24,-.323,1.105),(.072,.025,.072),gold,2,12,0);weight(button,'spine',rig)
    pocket=loft('Canvas bib pocket',[(0,-.315,.87,.16,.028),(0,-.337,.95,.20,.028),(0,-.324,1.06,.20,.025)],dark,20,3,1);weight(pocket,'spine',rig)
    seam=tube('Pocket saddle stitch',[(-.16,-.345,.99),(-.13,-.352,.91),(0,-.356,.89),(.13,-.352,.91),(.16,-.345,.99)],.009,linen,6);weight(seam,'spine',rig)
    scarf=loft('Folded golden neckerchief',[(0,0,1.38,.25,.24),(0,-.015,1.45,.28,.26),(0,-.015,1.51,.24,.22)],gold,24,2,1);weight(scarf,'spine',rig)
    tie=mesh('Neckerchief fold',[(-.07,-.25,1.43),(.15,-.24,1.43),(.12,-.34,1.19),(-.01,-.35,1.24)],[(0,1,2,3)],gold)
    mod=tie.modifiers.new('Cloth thickness','SOLIDIFY');mod.thickness=.025;apply(tie,mod);weight(tie,'spine',rig)
    tail=tube('Characteristic upright tail',[(0,.23,.77),(0,.43,.81),(0,.61,.99),(0,.65,1.17),(0,.64,1.22)],[.12,.12,.095,.06,.012],fur,16)
    paint(tail,'989da5' if species=='terrier' else ('e6d9c2' if species=='rabbit' else '9c9895'),species=='terrier');weight(tail,'tail',rig)
    if species=='raccoon':
        # Longer ringed tail with painted bands on continuous swept topology.
        tail.hide_render=True;tail.hide_viewport=True
        bpy.data.objects.remove(tail,do_unlink=True);PARTS.remove(tail)
        tail=tube('Ringed raccoon tail',[(0,.24,.75),(0,.49,.72),(.06,.78,.62),(.12,1.06,.49),(.14,1.23,.43)],[.17,.18,.17,.13,.025],fur,16);paint(tail,'9c9895')
        attr=tail.data.color_attributes['Pigment']
        for v,c in zip(tail.data.vertices,attr.data):
            if math.sin(v.co.y*21)>0:c.color=(*rgb('3e4850'),1)
        weight(tail,'tail',rig)
    bag=loft('Harvest leather backpack',[(0,.30,.70,.21,.12),(0,.36,.78,.29,.17),(0,.37,1.11,.30,.18),(0,.34,1.30,.24,.15),(0,.32,1.34,.11,.08)],leather,24,3,2);weight(bag,'spine',rig)
    flap=bean('Backpack folded flap',(0,.49,1.18),(.48,.11,.25),leather,3,24,1);weight(flap,'spine',rig)
    clasp=block('Backpack brass buckle',(0,.553,1.11),(.10,.035,.12),gold,.018);weight(clasp,'spine',rig)
    animate(rig)
    bpy.context.scene.render.fps=30
    save_export(species,rigged=True)


def arch(name, at, width, height, depth, material):
    x,y,z=at; r=width*.5; verts=[]
    outline=[(-r,0),(r,0),(r,height-r)]
    for j in range(1,13):
        a=j*math.pi/12;outline.append((r*math.cos(a),height-r+r*math.sin(a)))
    outline.append((-r,0))
    n=len(outline)
    for dy in [-depth/2,depth/2]:verts.extend((x+px,y+dy,z+pz) for px,pz in outline)
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    return mesh(name,verts,faces,material,False)


def leaf(name, at, length, width, material, angle=0):
    x,y,z=at;verts=[(0,0,0),(-width*.5,length*.38,.03),(0,length*.52,.11),(width*.5,length*.38,.03),(0,length,0)]
    ob=mesh(name,verts,[(0,1,2),(0,2,3),(1,4,2),(2,4,3)],material)
    ob.location=at;ob.rotation_euler=(.35,0,angle)
    mod=ob.modifiers.new('Leaf thickness','SOLIDIFY');mod.thickness=.012;apply(ob,mod)
    return ob


def planter(x,y,z,wood,foliage,flower):
    block('Carved window box',(x,y,z),(.98,.35,.24),wood,.04)
    for j in range(5):
        a=TAU*j/5
        leaf('Window foliage',(x+(j-2)*.16,y,z+.14),.34,.17,foliage,a)
        if j%2==0:bean('Planter blossom',(x+(j-2)*.16,y-.05,z+.28),(.14,.12,.12),flower,2,10,0)


def roof(width,depth,base,peak,roofmat,trim):
    # Curved crafted roof section with overlapping individual scalloped shingles.
    for side in (-1,1):
        verts=[]
        for j in range(9):
            t=j/8; x=side*t*width*.5
            z=peak-(peak-base)*(t**.88)-.10*math.sin(t*math.pi)
            verts.extend([(x,-depth*.5,z),(x,depth*.5,z)])
        ob=mesh('Curved roof underlay',verts,[(j*2,j*2+1,j*2+3,j*2+2) for j in range(8)],roofmat)
        mod=ob.modifiers.new('Eave thickness','SOLIDIFY');mod.thickness=.12;apply(ob,mod)
        for row in range(5):
            t0=row/5;t1=(row+1.18)/5
            x0=side*t0*width*.5;x1=side*min(t1,1.07)*width*.5
            z0=peak-(peak-base)*t0**.88+.04
            z1=peak-(peak-base)*min(t1,1.07)**.88+.02
            for col in range(10):
                cy=(col-4.5)*depth/10;half=depth/20*.96
                verts=[(x0,cy-half,z0),(x0,cy+half,z0),(x1,cy+half,z1),(x1+side*.035,cy,z1-.018),(x1,cy-half,z1)]
                tile=mesh('Individual hand laid shingle',verts,[(0,1,2,3,4)],roofmat,False)
                mod=tile.modifiers.new('Shingle edge','SOLIDIFY');mod.thickness=.035;apply(tile,mod)
        for y in [-depth*.5,depth*.5]:
            tube('Curved eave beam',[(side*t*width*.5,y,peak-(peak-base)*t**.88-.07) for t in [0,.25,.5,.75,1]],.08,trim,8)
    tube('Roof ridge cap',[(0,-depth*.52,peak+.08),(0,depth*.52,peak+.08)],.105,trim,12)


def building(kind, small=False):
    clean()
    cream=mat('Limewashed stucco','f2deac',.95)
    timber=mat('Honey oak structure','9e724e',.83)
    edge=mat('Dark walnut joinery','664f42',.84)
    stone=mat('Warm cut limestone','cdb995',.96)
    ivory=mat('Ivory trim','fff0cb',.83)
    foliage=mat('Deep garden foliage','5c9764',.9)
    blossom=mat('Coral blossoms','ed9c92',.85)
    glass=mat('Reflective turquoise glazing','92cdd0',.24,.1)
    gold=mat('Brushed brass details','edc776',.35,.45)
    accents={'house':'a85d50','cafe':'529b90','depot':'6b8498','bakery':'d69466','greenhouse':'80ad93','workshop':'688ba5','watchtower':'626c8e','mill':'729eaa','park':'91b69a',
             'helper':'db9b5c','collector':'4b9a8c','bag':'b17a5b','speed':'6899bc','checkout':'539e96','lock':'76869f','alarm':'cd7f63','guard':'657e9f','expand':'83a879','pier':'709fa9','market':'d77c64','register':'549c90','treasury':'647e99','premium':'e1b260'}
    accent=mat('Enamel '+kind,accents.get(kind,'6f9e90'),.68)
    terracotta=mat('Hand fired roof tiles',accents.get(kind,'a85d50'),.84)
    if kind=='park':
        block('Garden limestone terrace',(0,0,.12),(4.5,4.2,.24),stone,.12)
        for x in [-1.6,1.6]:
            block('Oak garden bench',(x,0,.62),(.55,1.8,.16),timber,.06)
            for y in [-.6,.6]:block('Bench cast leg',(x,y,.34),(.40,.12,.60),edge,.04)
            for y in [-1.5,1.5]:planter(x,y,.35,timber,foliage,blossom)
        # Lathed fountain bowls, real concave cross sections and water surface.
        lathe('Stone fountain basin',[(0,.11),(1.18,.11),(1.27,.20),(1.30,.44),(1.17,.55),(1.05,.47),(1.02,.29),(0,.29)],stone)
        lathe('Upper fountain bowl',[(0,0),(.15,0),(.19,.70),(.66,.86),(.73,1.04),(.63,1.12),(.54,1.03),(.08,.85),(0,.85)],stone,at=(0,0,.42))
        lathe('Turquoise fountain water',[(0,.455),(1.04,.455),(1.04,.47),(0,.47)],glass)
        tube('Fountain jet',[(0,0,1.4),(0,0,1.9),(0,0,2.1)],[.06,.075,.015],glass,12)
        save_export(kind);return
    if kind in ['register','treasury']:
        block('Turned plinth',(0,0,.12),(1.65,1.22,.24),stone,.09)
        for x in [-.67,.67]:block('Cash counter legs',(x,.32,.43),(.12,.18,.64),timber,.035)
        block('Moulded cash cabinet',(0,0,.58),(1.40,.96,.79),accent,.09)
        block('Cabinet brass top',(0,0,1.00),(1.56,1.08,.14),gold,.06)
        block('Drawer inset',(0,-.495,.67),(1.16,.035,.40),edge,.025)
        block('Drawer painted panel',(0,-.523,.67),(1.02,.025,.30),accent,.04)
        tube('Cash drawer brass handle',[(-.15,-.56,.69),(-.15,-.60,.69),(.15,-.60,.69),(.15,-.56,.69)],.024,gold,8)
        if kind=='register':
            block('Enamel register body',(-.37,.12,1.20),(.60,.52,.33),accent,.06)
            block('Register brass bezel',(-.37,.22,1.46),(.53,.15,.29),gold,.035,rot=(.17,0,0))
            block('Register display',(-.37,.125,1.46),(.42,.025,.18),edge,.018)
            for x in range(3):
                for y in range(2):block('Pearl register key',(-.53+x*.15,-.04+y*.12,1.39),(.09,.08,.035),ivory,.014)
        else:
            arch('Treasury inset vault',(0,-.50,.44),.73,.49,.06,gold)
            lathe('Treasury emblem',[(0,0),(.15,0),(.16,.04),(0,.04)],gold,at=(0,-.55,.67),rotation=(math.pi/2,0,0))
        save_export(kind);return
    if small:
        w,d,h=1.75,1.36,1.58
    elif kind in ['market','premium']:
        w,d,h=4.6,3.05,2.0
    else:
        w,d,h=4.1,3.5,2.55
    block('Stepped limestone foundation',(0,0,.15),(w+.36,d+.30,.30),stone,.11)
    block('Carved timber foundation cap',(0,0,.33),(w+.13,d+.10,.13),timber,.04)
    block('Stucco facade',(0,0,.37+h*.5),(w,d,h),cream,.09)
    # Solid gable wall avoids the old disconnected lid silhouette.
    peak=h+1.32 if not small else h+.95
    mesh('Stucco gables',[(-w/2,-d/2,h+.35),(w/2,-d/2,h+.35),(0,-d/2,peak-.1),(-w/2,d/2,h+.35),(w/2,d/2,h+.35),(0,d/2,peak-.1)],[(0,1,2),(3,5,4)],cream,False)
    roof(w+.65,d+.65,h+.39,peak,terracotta,edge)
    for x in [-w*.49,w*.49]:
        for y in [-d*.49,d*.49]:block('Timber corner post',(x,y,.40+h*.5),(.13,.13,h+.12),timber,.035)
    block('Facade lintel',(0,-d*.5-.045,h+.18),(w+.12,.16,.18),timber,.025)
    if small:
        block('Shopfront dark recess',(0,-d*.5-.02,1.10),(w*.78,.075,.74),edge,.045)
        block('Enamel cabinet front',(0,-d*.5-.09,.76),(w*.85,.13,.65),accent,.045)
        block('Rounded sales counter',(0,-d*.5-.18,1.13),(w*1.03,.40,.13),timber,.055)
        for x in [-w*.34,w*.34]:
            block('Cabinet raised panel',(x,-d*.5-.17,.77),(.34,.045,.41),ivory,.025)
        if kind in ['helper','collector']:
            for x in [-.34,.34]:
                arch('Staff notice frame',(x,-d*.5-.08,1.47),.41,.40,.05,ivory)
                bean('Staff brass badge',(x,-d*.5-.12,1.64),(.15,.055,.16),gold,2,12,0)
        elif kind=='bag':
            for x in [-.38,.24]:
                bean('Displayed leather satchel',(x,-d*.5-.23,1.34),(.43,.24,.40),mat('Satchel leather','b78054'),3,16,1)
                tube('Satchel handle',[(x-.08,-d*.5-.20,1.53),(x,-d*.5-.20,1.64),(x+.08,-d*.5-.20,1.53)],.025,edge,8)
        elif kind=='speed':
            for x in [-.33,.30]:bean('Displayed running boot',(x,-d*.5-.24,1.29),(.35,.51,.22),accent,3,16,1)
        elif kind in ['lock','guard','alarm']:
            emblem=mesh('Shield enamel crest',[(-.24,-d*.5-.16,1.74),(.24,-d*.5-.16,1.74),(.19,-d*.5-.16,1.37),(0,-d*.5-.17,1.21),(-.19,-d*.5-.16,1.37)],[(0,1,2,3,4)],accent)
            mod=emblem.modifiers.new('Shield emboss','SOLIDIFY');mod.thickness=.07;apply(emblem,mod)
            tube('Shield brass stripe',[(0,-d*.5-.24,1.31),(0,-d*.5-.24,1.65)],.025,gold,8)
        else:
            bean('Trade guild medallion',(0,-d*.5-.15,1.53),(.46,.10,.46),gold,2,20,1)
        for x in [-w*.57,w*.57]:
            block('Shop planter',(x,-.45,.47),(.35,.42,.35),timber,.04)
            for j in range(3):leaf('Shop planter leaf',(x,-.45,.69),.33,.20,foliage,TAU*j/3)
        # Elevated sign posts deliberately extend above the complete roof.
        for x in [-.70,.70]:tube('Elevated sign support',[(x,.25,1.70),(x,.25,3.05)],.035,timber,8)
    elif kind in ['market','premium']:
        # Deep front opening and striped, curved awning with scalloped valance.
        block('Market open shadow',(0,-d/2-.02,1.56),(w-.5,.05,1.22),edge,.04)
        block('Long market countertop',(0,-d/2-.25,1.08),(w+.14,.70,.19),timber,.065)
        for j in range(12):
            x=(j-5.5)*w/12
            ob=mesh('Woven awning stripe',[(x-w/24,-d/2,2.47),(x+w/24,-d/2,2.47),(x+w/24,-d/2-.70,2.22),(x-w/24,-d/2-.70,2.22)],[(0,1,2,3)],ivory if j%2 else accent)
            mod=ob.modifiers.new('Canvas thickness','SOLIDIFY');mod.thickness=.025;apply(ob,mod)
            bean('Scalloped awning edge',(x,-d/2-.70,2.15),(w/12,.055,.21),ivory if j%2 else accent,2,12,0)
        for x in [-w*.37,0,w*.37]:
            block('Crate front panel',(x,-d/2-.28,1.31),(1.16,.58,.36),timber,.035)
            for dz in [-.11,.07]:block('Crate slat groove',(x,-d/2-.58,1.32+dz),(1.06,.023,.025),edge,.004)
        block('Market hanging plaque',(0,-d/2-.09,2.81),(2.5,.14,.57),accent,.07)
    else:
        doorx=-w*.25
        arch('Arched front door trim',(doorx,-d/2-.05,.35),.98,1.83,.15,timber)
        arch('Inset arched teal door',(doorx,-d/2-.14,.39),.79,1.64,.08,accent)
        for j in range(4):block('Door plank joint',(doorx-.28+j*.18,-d/2-.188,.96),(.012,.012,1.02),edge,.002)
        bean('Brass door handle',(doorx+.21,-d/2-.22,1.12),(.062,.05,.062),gold,2,12,0)
        for x in [.55,1.44]:
            arch('Arched window surround',(x,-d/2-.08,1.21),.71,1.07,.15,ivory)
            arch('Recessed turquoise window',(x,-d/2-.17,1.30),.53,.87,.06,glass)
            block('Window central mullion',(x,-d/2-.212,1.73),(.045,.035,.80),ivory,.008)
            block('Window crossbar',(x,-d/2-.212,1.69),(.57,.035,.05),ivory,.008)
            planter(x,-d/2-.23,1.17,timber,foliage,blossom)
        # Side wall windows visible to the isometric camera.
        for y in [-.72,.65]:
            block('Side window trim',(w/2+.04,y,1.80),(.14,.83,1.03),ivory,.045)
            block('Side window glass',(w/2+.12,y,1.83),(.035,.65,.80),glass,.025)
            block('Side window mullion',(w/2+.148,y,1.83),(.025,.045,.80),ivory,.005)
        block('Front entry step',(doorx,-d/2-.38,.20),(1.26,.70,.24),stone,.06)
        # Roof dormer, carved lintels and chimney courses add readable scale.
        block('Dormer housing',(.70,-.35,peak-.46),(1.18,1.34,.73),cream,.06)
        arch('Attic oval trim',(.70,-1.04,peak-.57),.60,.57,.10,ivory)
        arch('Attic oval glazing',(.70,-1.103,peak-.52),.44,.43,.025,glass)
        for j in range(4):block('Chimney brick course',(-1.19,.67,peak-.45+j*.20),(.53,.61,.18),stone if j%2 else timber,.025)
        block('Chimney crown',(-1.19,.67,peak+.27),(.66,.72,.13),ivory,.045)
        if kind in ['cafe','bakery']:
            for j in range(9):
                x=(j-4)*.43
                block('Cafe striped awning',(x,-d/2-.38,2.45),(.43,.88,.12),ivory if j%2 else accent,.03,rot=(.14,0,0))
            for x in [-1.43,1.38]:
                lathe('Cafe table',[(0,0),(.10,0),(.10,.65),(.48,.65),(.48,.75),(0,.75)],timber,at=(x,-d/2-1.05,.08))
                bean('Cafe cup',(x,-d/2-1.05,.91),(.18,.18,.21),ivory,2,16,0)
        if kind in ['depot','workshop']:
            for x,y in [(2.18,-.9),(2.2,.2)]:
                for j in range(3):block('Stacked supply crate',(x,y,.35+j*.42),(.65,.71,.39),timber,.035)
        if kind=='greenhouse':
            # A glazed attached cold frame, with actual roof framing.
            for j in range(5):
                block('Glass roof pane',(-1.25+j*.60,.15,peak-.48),(.56,2.72,.09),glass,.02,rot=(0,.28,0))
                block('Greenhouse glazing bar',(-1.53+j*.60,.15,peak-.43),(.045,2.79,.08),ivory,.008,rot=(0,.28,0))
        if kind=='watchtower':
            # Tiered lookout keeps the same walkable footprint.
            block('Watchtower upper tier',(0,.10,peak+.05),(2.0,1.9,1.12),cream,.08)
            for x in [-.75,.75]:block('Lookout shutter',(x,-.88,peak+.08),(.47,.07,.68),accent,.035)
        if kind=='mill':
            wheel=bpy.data.objects.new('WindmillRotor',None);bpy.context.collection.objects.link(wheel);wheel.location=(0,-d/2-.42,peak-.12)
            for j in range(4):
                a=j*math.pi/2
                ob=block('Windmill sail',(math.sin(a)*1.10,-d/2-.42,peak-.12+math.cos(a)*1.10),(.36,.12,2.13),ivory,.04,rot=(0,a,0))
                world=ob.matrix_world.copy();ob.parent=wheel;ob.matrix_world=world
                for k in range(3):
                    sl=block('Windmill slat',(math.sin(a)*(.55+k*.5),-d/2-.51,peak-.12+math.cos(a)*(.55+k*.5)),(.73,.08,.09),timber,.02,rot=(0,a,0));world=sl.matrix_world.copy();sl.parent=wheel;sl.matrix_world=world
            bean('Windmill central brass hub',(0,-d/2-.57,peak-.12),(.39,.20,.39),gold,2,16,1)
    # Hand-cut foundation masonry and facade joinery.
    for j in range(8):block('Foundation masonry joint',((j-3.5)*w/8,-d/2-.035,.15),(.022,.035,.19),edge,.003)
    save_export('booth_'+kind if small else kind)


def lathe(name, profile, material, at=(0,0,0), rotation=(0,0,0), sides=32):
    verts=[];faces=[]
    for r,z in profile:
        for j in range(sides):
            a=TAU*j/sides;verts.append((r*math.cos(a),r*math.sin(a),z))
    for i in range(len(profile)-1):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
    ob=mesh(name,verts,faces,material);ob.location=at;ob.rotation_euler=rotation;return ob


def garden():
    clean()
    bark=mat('Bark carved ridges','937050',.95)
    leafmat=mat('Painted emerald leaves','66965f',.93,painted=True)
    trunk=tube('Twisting tapered trunk',[(0,0,0),(.04,0,.6),(-.04,.025,1.24),(.13,.01,1.9),(.12,.03,2.65)],[.22,.20,.15,.09,.025],bark,12)
    for k in range(6):
        a=k*2.4; h=1.55+k*.16;x=math.cos(a)*.77;y=math.sin(a)*.66
        tube('Sculpted spreading branch',[(.04,0,h),(.35*x,.35*y,h+.17),(x,y,h+.52)],[.10,.07,.018],bark,8)
        for j in range(3):
            cx=x+math.sin(j*2)*.25;cy=y+math.cos(j*2)*.25;z=h+.53+j*.21
            ob=loft('Faceted leafy crown',[(cx,cy,z-.36,.08,.08),(cx,cy,z-.25,.52,.46),(cx+.05,cy,z+.06,.65,.59),(cx,cy,z+.36,.46,.40),(cx,cy,z+.53,.03,.03)],leafmat,14,2,1)
            paint(ob,['5f975c','78a862','568a59'][j])
    save_export('tree')
    for kind in ['tomato','carrot','berry','apple']:
        clean();stem=mat('Fresh green stem','4e8050',.94);fruit=mat('Fresh '+kind,{'tomato':'e8795a','carrot':'e8ad59','berry':'7784ad','apple':'db7c60'}[kind],.55)
        if kind=='carrot':
            loft('Tapered carrot root',[(0,0,0,.012,.012),(0,0,.15,.09,.08),(0,0,.37,.16,.14),(0,0,.46,.12,.11)],fruit,20,2,1)
            for j in range(5):leaf('Carrot frond',(0,0,.44),.52,.18,stem,j*TAU/5)
        elif kind=='berry':
            for j in range(7):
                a=j*2.4;bean('Berry cluster',(math.cos(a)*.17,math.sin(a)*.17,.24+j*.023),(.28,.26,.28),fruit,2.3,14,1)
            for j in range(4):leaf('Berry leaf',(0,0,.38),.38,.23,stem,j*TAU/4)
        else:
            loft('Lobed fruit body',[(0,0,0,.06,.06),(0,0,.07,.22,.20),(0,0,.24,.28,.25),(0,0,.40,.22,.20),(0,0,.44,.07,.07)],fruit,28,2.5,2)
            tube('Fruit stem',[(0,0,.42),(.02,0,.54),(.07,0,.58)],.024,stem,8)
            for j in range(5 if kind=='tomato' else 1):leaf('Fruit calyx',(0,0,.44),.23,.11,stem,j*TAU/5)
        save_export('produce_'+kind)


def props():
    clean()
    cloth=mat('Warm canvas money bag','d6b47c',.93)
    dark=mat('Braided drawstring','8c6548',.9)
    brass=mat('Minted Wivori gold','efbf55',.27,.55)
    loft('Gathered canvas money bag',[(0,0,0,.12,.10),(0,0,.10,.30,.24),(0,0,.37,.35,.28),(0,0,.63,.28,.21),(0,0,.74,.11,.10),(0,0,.84,.15,.13),(0,0,.87,.17,.14)],cloth,32,2.3,2)
    tube('Braided bag tie',[(-.12,-.04,.76),(0,-.13,.73),(.12,-.04,.76)],.022,dark,8)
    for i in range(4):
        lathe('Gold coins inside bag',[(0,0),(.12,0),(.12,.045),(0,.045)],brass,at=((i%2-.5)*.14,0,.84+i*.025))
    save_export('money_bag')
    clean()
    brass=mat('Minted Wivori gold','efbf55',.29,.55)
    pale=mat('Coin relief highlight','ffe5a3',.34,.35)
    lathe('Milled coin rim',[(0,0),(.17,0),(.185,.025),(.185,.075),(.17,.10),(0,.10)],brass,sides=32)
    lathe('Embossed inner coin face',[(0,0),(.14,0),(.145,.015),(0,.015)],pale,at=(0,0,.10),sides=32)
    verts=[(0,0,.128)]+[(math.cos(i*TAU/10)*(.105 if i%2==0 else .049),math.sin(i*TAU/10)*(.105 if i%2==0 else .049),.128) for i in range(10)]
    mesh('Wivori star stamp',verts,[(0,1+i,1+(i+1)%10) for i in range(10)],brass,False)
    save_export('coin')


def bake_character(name):
    """Original colour + contact-shadow atlases; real texture assets, not concepts."""
    import numpy as np
    ob=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True)
    bpy.context.view_layer.objects.active=ob
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.1519,island_margin=.012)
    bpy.ops.object.mode_set(mode='OBJECT')
    # Add fine fur grain before baking. UVs are packed once for the whole skin.
    for material in ob.data.materials:
        if material and 'fur' in material.name.lower() or material and 'Brindle' in material.name:
            nodes=material.node_tree.nodes;links=material.node_tree.links
            shader=nodes.get('Principled BSDF')
            pigment=next(n for n in nodes if n.type=='VERTEX_COLOR')
            noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=62;noise.inputs['Detail'].default_value=2
            blend=nodes.new('ShaderNodeMixRGB');blend.blend_type='MULTIPLY';blend.inputs[0].default_value=.17
            links.new(pigment.outputs['Color'],blend.inputs[1]);links.new(noise.outputs['Fac'],blend.inputs[2]);links.new(blend.outputs[0],shader.inputs['Base Color'])
            if 'Brindle' in material.name:
                bands=nodes.new('ShaderNodeTexWave');bands.wave_type='BANDS';bands.bands_direction='X'
                bands.inputs['Scale'].default_value=13;bands.inputs['Distortion'].default_value=7
                bands.inputs['Detail Scale'].default_value=1.8
                ramp=nodes.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.22;ramp.color_ramp.elements[0].color=(.30,.33,.36,1)
                ramp.color_ramp.elements[1].position=.76;ramp.color_ramp.elements[1].color=(1,1,1,1)
                links.new(bands.outputs['Color'],ramp.inputs[0])
                pattern=nodes.new('ShaderNodeMixRGB');pattern.blend_type='MULTIPLY';pattern.inputs[0].default_value=.50
                links.new(blend.outputs[0],pattern.inputs[1]);links.new(ramp.outputs[0],pattern.inputs[2]);links.new(pattern.outputs[0],shader.inputs['Base Color'])

    color=bpy.data.images.new(name+'_albedo',1024,1024,alpha=False)
    ao=bpy.data.images.new(name+'_contact_shadows',1024,1024,alpha=False)
    targets=[]
    for material in ob.data.materials:
        node=material.node_tree.nodes.new('ShaderNodeTexImage');node.image=color
        material.node_tree.nodes.active=node;targets.append((material,node))
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16
    scene.cycles.device='CPU';scene.cycles.use_denoising=False
    scene.render.threads_mode='FIXED';scene.render.threads=4
    scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True
    bpy.ops.object.bake(type='DIFFUSE',margin=8,use_clear=True)
    for material,node in targets:node.image=ao;material.node_tree.nodes.active=node
    bpy.ops.object.bake(type='AO',margin=8,use_clear=True)
    pixels=np.empty(1024*1024*4,dtype=np.float32);shadows=np.empty_like(pixels)
    color.pixels.foreach_get(pixels);ao.pixels.foreach_get(shadows)
    if float(pixels.max())<.01 or float(shadows.max())<.01:
        raise RuntimeError('Texture baking failed: refusing to export an empty atlas')
    pixels=pixels.reshape((-1,4));shadows=shadows.reshape((-1,4))
    pixels[:,:3]*=(.58+.42*np.clip(shadows[:,:3],0,1))
    color.pixels.foreach_set(pixels.ravel());color.update()
    textures=SOURCE/'textures';textures.mkdir(exist_ok=True)
    color.filepath_raw=str(textures/(name+'_albedo.png'));color.file_format='PNG';color.save();color.pack()
    ao.filepath_raw=str(textures/(name+'_contact_shadows.png'));ao.file_format='PNG';ao.save();ao.pack()
    for material,node in targets:
        node.image=color
        material.node_tree.links.new(node.outputs['Color'],material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    # Colour is now in the atlas. Leaving the pigment here would multiply it a
    # second time in glTF. The original painter is reproducible in this script.
    for c in ob.data.color_attributes['Pigment'].data:c.color=(1,1,1,1)
    print('WIVORI_TEXTURES',name,flush=True)


def save_export(name, rigged=False):
    # Apply transforms for stable metre-scale import. Materials use only glTF
    # standard PBR + vertex colour: no missing procedural Blender nodes.
    # Batch meshes by parent. A character is one skin with material surfaces;
    # a building has one static mesh plus a separate windmill rotor, not 180
    # tiny runtime draw submissions for every tile and timber joint.
    parents={}
    for ob in list(bpy.context.scene.objects):
        if ob.type=='MESH':parents.setdefault(ob.parent,[]).append(ob)
    for parent,objects in parents.items():
        bpy.ops.object.select_all(action='DESELECT')
        for ob in objects:ob.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
        objects[0].name=name+'_crafted_mesh'
        objects[0].data.color_attributes.render_color_index=objects[0].data.color_attributes.find('Pigment')
    bpy.ops.object.select_all(action='DESELECT')
    for ob in list(bpy.context.scene.objects):
        if ob.type in ['MESH','ARMATURE','EMPTY']:ob.select_set(True)
    bpy.context.scene.world.color=(.5,.5,.5)
    bpy.context.scene.render.fps=30
    if rigged:
        bake_character(name)
        batch_character_materials()
    # Baking selects only the skin. Re-select the armature so glTF exports all
    # action clips as well as the deforming mesh and its joints.
    bpy.ops.object.select_all(action='DESELECT')
    for ob in bpy.context.scene.objects:
        if ob.type in ['MESH','ARMATURE','EMPTY']:ob.select_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(name+'.blend')),compress=True)
    options=dict(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_apply=False,export_colors=True,export_animations=rigged,export_nla_strips=True,export_frame_range=False,export_force_sampling=True,export_skins=True,export_def_bones=True,export_cameras=False,export_lights=False)
    bpy.ops.export_scene.gltf(**options)
    if rigged:
        import struct
        raw=(OUT/(name+'.glb')).read_bytes()
        data=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
        if len(data.get('animations',[]))<12:raise RuntimeError('Missing skeletal animation clips')
    print('WIVORI_ASSET',name,'triangles',sum(len(o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH'),flush=True)


def batch_character_materials():
    # Once colour is baked, fur, canvas, thread and leather can share one matte
    # draw. Keep a glossy surface for eyes/nose and a metallic brass surface.
    ob=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    old=list(ob.data.materials)
    image=next(n.image for n in old[0].node_tree.nodes if n.type=='TEX_IMAGE' and n.image and '_albedo' in n.image.name)
    groups=[]
    for label,rough,metal in [('Matte',.87,0),('Gloss',.24,0),('Brass',.38,.32)]:
        material=bpy.data.materials.new('Wivori atlas '+label);material.use_nodes=True
        shader=material.node_tree.nodes.get('Principled BSDF')
        shader.inputs['Roughness'].default_value=rough;shader.inputs['Metallic'].default_value=metal
        tex=material.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
        material.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
        groups.append(material)
    mapping=[]
    for material in old:
        shader=material.node_tree.nodes.get('Principled BSDF')
        mapping.append(2 if shader.inputs['Metallic'].default_value>.1 else (1 if shader.inputs['Roughness'].default_value<.4 else 0))
    indices=[mapping[p.material_index] for p in ob.data.polygons]
    ob.data.materials.clear()
    for material in groups:ob.data.materials.append(material)
    for poly,index in zip(ob.data.polygons,indices):poly.material_index=index


if __name__=='__main__':
    import sys
    wanted=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    if not wanted or 'characters' in wanted:
        for species in ['terrier','rabbit','raccoon']:character(species)
    else:
        for species in ['terrier','rabbit','raccoon']:
            if species in wanted:character(species)
    if not wanted or 'buildings' in wanted:
        for kind in ['house','cafe','depot','bakery','greenhouse','workshop','watchtower','mill','park','market','register','treasury','premium']:building(kind)
        for kind in ['helper','collector','bag','speed','checkout','lock','alarm','guard','expand','pier']:building(kind,True)
    if not wanted or 'garden' in wanted:garden()
    if not wanted or 'props' in wanted:props()
