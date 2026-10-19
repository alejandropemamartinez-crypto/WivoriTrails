"""Unnamed protagonist. Original sculpt, sewn clothes and mobile PBR atlas.
Blender 4.x --background --python art/source/build_hero.py.
Reuses the anatomical rig and animation API, never the old bearded head.
Stages 5E/7: shorter square-jawed Scottish Terrier proportions, tapered upright
asymmetric ears and subtle charcoal-grey brindle shading; not a Schnauzer beard.
"""
import bpy, math, importlib.util
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
P=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('wivori_art',P/'build_assets.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
COAT='4c5b63'

def sculpt_head(species,fur,rig):
    # Strong little cheeks, a forward muzzle and compact skull; without the
    # hanging beard, oversized mustache or arching Schnauzer eyebrow.
    rings=[(0,-.055,1.49,.11,.13),(0,-.12,1.57,.31,.28),(0,-.21,1.69,.47,.42),
           (0,-.24,1.83,.54,.47),(0,-.075,1.98,.58,.46),(0,.015,2.16,.53,.42),
           (0,.04,2.35,.44,.35),(0,.046,2.46,.29,.24),(0,.046,2.50,.04,.04)]
    head=a.loft('Continuous rounded puppy face',rings,fur,48,2.18,2)
    # Sculpt the socket into the skin, rather than mounting eyes on a flat face.
    for vertex in head.data.vertices:
        x,y,z=vertex.co
        if y>=-.12:continue
        recess=sum(math.exp(-1.6*(((x-side*.265)/.16)**2+((z-2.135)/.19)**2)) for side in [-1,1])
        vertex.co.y+=.05*recess
    a.paint(head,COAT)
    pigment=head.data.color_attributes['Pigment'];muzzle=a.rgb('73848e')
    for v,c in zip(head.data.vertices,pigment.data):
        x,y,z=v.co
        # Breed-readable grey brindle is painted into the deforming coat,
        # NOT hanging tuft meshes or a brightly coloured muzzle beard.
        fleck=.045*math.sin(x*31+z*17)*math.sin(z*25-x*9)
        coat_shade=.92+.10*max(0,min(1,(z-1.5)))+fleck
        # A small soft muzzle blaze; preserve dark coat around chin/eyes.
        patch=math.exp(-((x/.30)**4)-(((z-1.81)/.185)**4))*max(0,min(1,(-y-.38)/.20))*.61
        c.color=(*[min(1,max(0,c.color[i]*coat_shade*(1-patch)+muzzle[i]*patch)) for i in range(3)],1)
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
    eye_finish=a.mat('Continuous painted eye surface','fff7e6',.28,painted=True)
    def integrated_eye(x,y,z,bone):
        # Iris, pupil and glints share one surface. Raised layers looked
        # like loose coins when viewed in profile.
        verts=[];faces=[];sides=48;rings=28
        for row in range(rings+1):
            latitude=math.pi*(1.0-(row+.0001)/(rings+.0002))
            for j in range(sides):
                longitude=math.tau*j/sides
                verts.append((x+.1155*math.sin(latitude)*math.cos(longitude),
                              y+.070*math.sin(latitude)*math.sin(longitude),
                              z+.1335*math.cos(latitude)))
        for row in range(rings):
            for j in range(sides):
                k=row*sides+j;n=row*sides+(j+1)%sides
                faces.append((k,n,n+sides,k+sides))
        faces.extend([tuple(reversed(range(sides))),tuple(rings*sides+j for j in range(sides))])
        eye=a.mesh('Integrated eye '+bone,verts,faces,eye_finish)
        ivory=a.rgb('fff7e6');amber=a.rgb('ac7943');pupil=a.rgb('152a32');shine=a.rgb('fffefd')
        def blend(left,right,weight):return tuple(left[i]*(1-weight)+right[i]*weight for i in range(3))
        for vertex,color in zip(eye.data.vertices,eye.data.color_attributes['Pigment'].data):
            px,py,pz=vertex.co;rgb=ivory
            if py<y:
                iris=math.hypot((px-x-.012)/.079,(pz-z+.006)/.104)
                rgb=blend(rgb,amber,max(0,min(1,(1.04-iris)/.09)))
                core=math.hypot((px-x-.012)/.052,(pz-z+.006)/.076)
                rgb=blend(rgb,pupil,max(0,min(1,(1.04-core)/.10)))
                glint=math.hypot((px-x+.018)/.020,(pz-z-.047)/.027)
                rgb=blend(rgb,shine,max(0,min(1,(1.1-glint)/.30)))
                bounce=math.hypot((px-x-.044)/.009,(pz-z+.042)/.012)
                rgb=blend(rgb,shine,max(0,min(1,(1.1-bounce)/.30)))
            color.color=(*rgb,1)
        a.weight(eye,bone,rig)
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
        lid=piece('Skin-coloured orbital lid '+side,(x,y+.050,z),(.269,.165,.307),fur,bone)
        a.paint(lid,COAT)
        integrated_eye(x,y-.004,z,bone)
        rs=[(s*.35,.045,2.31,.18,.145),(s*.43,.066,2.50,.145,.115),
            (s*(.48 if s<0 else .52),.09,2.68 if s<0 else 2.65,.072,.060),
            (s*(.475 if s<0 else .55),.115,2.83 if s<0 else 2.78,.012,.014)]
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
    # Keep the tracked Godot texture source identical to the embedded atlas.
    check_spec=importlib.util.spec_from_file_location('hero_export_check',P/'validate_hero_export.py')
    checker=importlib.util.module_from_spec(check_spec);check_spec.loader.exec_module(checker)
    checker.inspect()

a.head_model=sculpt_head;a.save_export=export_hero
old_mat=a.mat

def hero_material(name,color,rough=.65,metal=0,painted=False):
    if name=='Brindle grey coat':return old_mat('Soft shaded coat',COAT,.90,0,True)
    return old_mat(name,color,rough,metal,painted)
a.mat=hero_material
if __name__=='__main__':
    a.character('terrier')
