"""Unnamed protagonist v0.16. Original sculpt, sewn clothes and mobile PBR atlas.
Blender 4.x --background --python art/source/build_hero.py.
Reuses the anatomical rig and animation API, never the old bearded head.
"""
import bpy, math, importlib.util
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
P=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('wivori_art',P/'build_assets.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
COAT='596b75'

def sculpt_head(species,fur,rig):
    rings=[(0,-.05,1.49,.11,.13),(0,-.10,1.57,.32,.29),(0,-.13,1.69,.46,.42),
           (0,-.12,1.83,.52,.49),(0,-.055,1.98,.57,.46),(0,.015,2.16,.55,.43),
           (0,.035,2.35,.45,.36),(0,.045,2.46,.29,.25),(0,.045,2.50,.04,.04)]
    head=a.loft('Continuous rounded puppy face',rings,fur,48,2.18,2)
    a.paint(head,COAT)
    pigment=head.data.color_attributes['Pigment'];muzzle=a.rgb('bbc4bf')
    for v,c in zip(head.data.vertices,pigment.data):
        x,y,z=v.co
        # A small integrated muzzle patch, with no pale beard or heavy brows.
        patch=math.exp(-((x/.37)**4)-(((z-1.78)/.21)**4))*max(0,min(1,(-y-.28)/.16))*.90
        top=.94+.11*max(0,min(1,(z-1.5)))
        c.color=(*[c.color[i]*top*(1-patch)+muzzle[i]*patch for i in range(3)],1)
    bpy.context.view_layer.update()
    bvh=BVHTree.FromObject(head,bpy.context.evaluated_depsgraph_get())
    def face_y(x,z):
        hit=bvh.ray_cast(Vector((x,-3,z)),Vector((0,1,0)),5)[0]
        if hit is None:raise RuntimeError('Facial detail has no skin beneath it')
        return hit.y
    a.weight(head,'head',rig)
    def piece(name,center,size,material,bone='head',subdiv=1):
        ob=a.bean(name,center,size,material,2.2,24,subdiv);a.weight(ob,bone,rig);return ob
    ink=a.mat('Face warm charcoal','253841',.56)
    ivory=a.mat('Eyes soft ivory','fff7e6',.30)
    amber=a.mat('Eyes amber iris','ac7943',.28)
    pupil=a.mat('Eyes pupils','152a32',.22)
    shine=a.mat('Eyes glints','fffefd',.18)
    # Eye bones are centered on the actual recessed eye socket for anchored blinking.
    bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for s,side in [(-1,'L'),(1,'R')]:
        x=s*.265;z=2.135;y=face_y(x,z)
        bone=rig.data.edit_bones['eye.'+side];bone.head=(x,y,z);bone.tail=(x,y,z+.15)
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    for s,side in [(-1,'L'),(1,'R')]:
        x=s*.265;z=2.135;y=face_y(x,z);bone='eye.'+side
        # Back halves intersect the head; all accents share the same eyelid bone.
        piece('Inset eye rim '+side,(x,y+.018,z),(.295,.17,.333),ink,bone)
        piece('Warm eye '+side,(x,y-.022,z),(.255,.145,.293),ivory,bone)
        piece('Amber iris '+side,(x+.012,y-.090,z-.006),(.161,.038,.203),amber,bone)
        piece('Deep pupil '+side,(x+.012,y-.108,z-.006),(.111,.023,.158),pupil,bone)
        piece('Key reflection '+side,(x-.018,y-.122,z+.047),(.045,.008,.056),shine,bone,0)
        piece('Bounce reflection '+side,(x+.044,y-.120,z-.042),(.018,.008,.024),shine,bone,0)
        rs=[(s*.35,.045,2.31,.19,.145),(s*.43,.065,2.49,.16,.12),
            (s*(.48 if s<0 else .52),.09,2.73 if s<0 else 2.69,.08,.07),
            (s*(.475 if s<0 else .55),.115,2.86 if s<0 else 2.80,.01,.015)]
        ear=a.loft('Soft asymmetric ear '+side,rs,fur,24,2,2);a.paint(ear,COAT)
        a.weight(ear,'ear.'+side,rig,lambda v,side=side:{'ear.'+side:max(0,min(1,(v.z-2.34)/.20)),'head':1-max(0,min(1,(v.z-2.34)/.20))})
        rose=a.mat('Inner ear dusky peach','be938c',.88)
        inner=a.loft('Recessed ear lining '+side,[(x,y-ry*.80,z,rx*.55,.018) for x,y,z,rx,ry in rs[1:]],rose,18,2,1);a.weight(inner,'ear.'+side,rig)
    ny=face_y(0,1.90)
    piece('Embedded soft nose',(0,ny-.025,1.90),(.285,.18,.19),ink)
    piece('Nose broad reflection',(-.035,ny-.105,1.945),(.075,.015,.025),a.mat('Nose reflected light','647a83',.35),subdiv=0)
    points=[]
    for x,z in [(-.19,1.749),(-.10,1.715),(0,1.705),(.10,1.715),(.19,1.755)]:points.append((x,face_y(x,z)-.006,z))
    smile=a.tube('Smile anchored to muzzle',points,.013,ink,8);a.weight(smile,'head',rig)
    return head

original_export=a.save_export

def export_hero(name,rigged=False):
    rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    scarf=a.mat('Woven saffron cotton','efb74d',.88)
    for ob in list(bpy.context.scene.objects):
        if ob.type!='MESH':continue
        if 'paw' in ob.name.lower() or 'Characteristic upright tail' in ob.name:a.paint(ob,COAT)
        if 'neckerchief' in ob.name.lower():ob.data.materials.clear();ob.data.materials.append(scarf)
        if 'Neckerchief fold' in ob.name:
            for v in ob.data.vertices:v.co.x-=.04;v.co.z-=.025
    # Cloth seams and cuff edges catch light without noisy detail at play scale.
    linen=a.mat('Jacket piping','84bab1',.89)
    for s,side in [(-1,'L'),(1,'R')]:
        seam=a.tube('Sleeve stitched edge '+side,[(s*.40,-.105,1.16),(s*.46,-.14,1.07),(s*.51,-.135,.97)],.012,linen,6);a.weight(seam,'arm.'+side,rig)
    # Soft eye blink and secondary ear motion are already keyed in every idle loop.
    original_export('hero',True)

a.head_model=sculpt_head;a.save_export=export_hero
old_mat=a.mat

def hero_material(name,color,rough=.65,metal=0,painted=False):
    if name=='Brindle grey coat':return old_mat('Soft shaded coat',COAT,.90,0,True)
    return old_mat(name,color,rough,metal,painted)
a.mat=hero_material
a.character('terrier')
