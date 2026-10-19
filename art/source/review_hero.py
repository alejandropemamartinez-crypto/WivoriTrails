"""Blender previews of the exported GLB; not gameplay or Godot captures.
blender -b --factory-startup -P art/source/review_hero.py -- /absolute/output
"""
import bpy
import hashlib
import json
import sys
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2]
OUTPUT=Path(sys.argv[sys.argv.index('--')+1]);OUTPUT.mkdir(parents=True,exist_ok=True)
ASSET=ROOT/'assets/models/hero.glb'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.fps=30
bpy.ops.import_scene.gltf(filepath=str(ASSET),import_pack_images=True)
rig=next(ob for ob in scene.objects if ob.type=='ARMATURE')
if rig.animation_data is None:rig.animation_data_create()
for track in rig.animation_data.nla_tracks:track.mute=True
clips=list(bpy.data.actions)
def pose(name,frame):
    for bone in rig.pose.bones:bone.matrix_basis=Matrix.Identity(4)
    choices=[action for action in clips if action.name==name or action.name.startswith(name+'_')]
    if len(choices)!=1:raise RuntimeError('Missing or ambiguous animation '+name)
    rig.animation_data.action=choices[0];scene.frame_set(frame);bpy.context.view_layer.update()
def area(name,position,power,size):
    light=bpy.data.lights.new(name,'AREA');light.energy=power;light.shape='DISK';light.size=size
    ob=bpy.data.objects.new(name,light);scene.collection.objects.link(ob);ob.location=position
    ob.rotation_euler=(Vector((0,0,1.4))-ob.location).to_track_quat('-Z','Y').to_euler()
area('Soft key',(-3.5,-4.0,6.0),600,4.5)
area('Broad fill',(4.5,-2.0,3.5),350,4.0)
area('Rim separation',(1.5,4.0,5.0),550,3.5)
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.63,.67,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.35
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.01))
floor=bpy.context.object;floor.name='Review studio floor (not in GLB)'
material=bpy.data.materials.new('Review backdrop');material.use_nodes=True
material.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.69,.75,.73,1)
material.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.9
floor.data.materials.append(material)
camera_data=bpy.data.cameras.new('Asset review camera')
camera=bpy.data.objects.new('Asset review camera',camera_data);scene.collection.objects.link(camera)
camera_data.type='ORTHO';camera_data.ortho_scale=3.45;scene.camera=camera
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.cycles.use_denoising=False;scene.render.threads_mode='FIXED';scene.render.threads=4
scene.render.resolution_x=640;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX';scene.view_settings.exposure=.2
views=[('01_front','idle',3,(0,-8,2.8)),('02_three_quarter','idle',3,(4,-7,2.8)),
       ('03_profile','idle',3,(8,0,2.8)),('04_back','idle',3,(3.5,7.5,2.8)),
       ('05_run','run',6,(3,-7,2.8)),('06_carry','carry',8,(3,-7,2.8)),
       ('07_harvest','harvest',15,(3,-7,2.8)),('08_blink','idle',43,(0,-8,2.8))]
if '--first' in sys.argv[sys.argv.index('--')+2:]:views=views[:1]
for name,clip,frame,position in views:
    pose(clip,frame);camera.location=position
    camera.rotation_euler=(Vector((0,0,1.43))-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUTPUT/(name+'.png'));bpy.ops.render.render(write_still=True)
    print('HERO_REVIEW',name,flush=True)
report={'asset':'assets/models/hero.glb','sha256':hashlib.sha256(ASSET.read_bytes()).hexdigest(),
        'renderer':'Blender 4.0.2 / Cycles CPU, imported exported GLB','bones':len(rig.data.bones),
        'actions':[a.name for a in clips],'views':[name for name,_,_,_ in views],
        'game_executed':False,'godot_imported':False,'android_built':False}
(OUTPUT/'review.json').write_text(json.dumps(report,indent=2))
