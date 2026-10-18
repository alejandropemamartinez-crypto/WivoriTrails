"""Export the editable authored .blend sources without rebuilding their sculpt."""
import sys
from pathlib import Path
import bpy

ROOT=Path(__file__).resolve().parents[2]
names=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['terrier','goods_jam','goods_parcel','goods_crate','oak_bench','flower_cart']
for name in names:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source'/(name+'.blend')))
    bpy.ops.object.select_all(action='DESELECT')
    for ob in bpy.context.scene.objects:
        if ob.type in ['MESH','ARMATURE','EMPTY']:ob.select_set(True)
    rigged=any(ob.type=='ARMATURE' for ob in bpy.context.scene.objects)
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_apply=False,export_colors=True,export_animations=rigged,export_nla_strips=True,export_frame_range=False,export_force_sampling=True,export_skins=True,export_def_bones=True,export_cameras=False,export_lights=False)
    print('EXPORTED_AUTHORED',name,flush=True)
