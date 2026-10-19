"""Inspect the GLB file and synchronize its extracted atlas, without Godot."""
import hashlib
import json
import math
import struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
CLIPS={'idle','walk','run','turn','harvest','carry','deliver','collect','celebrate','surprise','intercept','build','alert','relief'}
COMPONENTS={5120:('b',1),5121:('B',1),5122:('h',2),5123:('H',2),5125:('I',4),5126:('f',4)}
WIDTHS={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
def inspect(sync=True):
    asset=ROOT/'assets/models/hero.glb';raw=asset.read_bytes()
    if struct.unpack_from('<4sII',raw)!=(b'glTF',2,len(raw)):raise ValueError('Invalid GLB header')
    cursor=12;document=None;binary=None
    while cursor<len(raw):
        length,kind=struct.unpack_from('<I4s',raw,cursor);cursor+=8
        chunk=raw[cursor:cursor+length];cursor+=length
        if len(chunk)!=length:raise ValueError('Truncated GLB chunk')
        if kind==b'JSON':document=json.loads(chunk)
        elif kind==b'BIN\x00':binary=chunk
    if document is None or binary is None:raise ValueError('Expected embedded JSON and geometry')
    if any('uri' in buffer for buffer in document.get('buffers',[])):raise ValueError('Unexpected external geometry')
    if 'KHR_draco_mesh_compression' in document.get('extensionsRequired',[]):raise ValueError('Unexpected required Draco decoder')
    skins=document.get('skins',[])
    if len(skins)!=1 or len(skins[0]['joints'])!=17:raise ValueError('Incompatible skeleton')
    joints=skins[0]['joints'];names=[document['nodes'][i]['name'] for i in joints]
    for bone in ['head','eye.L','eye.R','ear.L','ear.R','foot.L','foot.R']:
        if bone not in names:raise ValueError('Missing motion bone '+bone)
    if {a['name'] for a in document.get('animations',[])}!=CLIPS:raise ValueError('Missing or renamed clip')
    def values(index):
        accessor=document['accessors'][index]
        if 'sparse' in accessor:raise ValueError('Unexpected sparse accessor')
        view=document['bufferViews'][accessor['bufferView']]
        code,size=COMPONENTS[accessor['componentType']];width=WIDTHS[accessor['type']]
        start=view.get('byteOffset',0)+accessor.get('byteOffset',0);stride=view.get('byteStride',size*width)
        end=start+(accessor['count']-1)*stride+size*width
        if end>len(binary) or end>view.get('byteOffset',0)+view['byteLength']:raise ValueError('Accessor exceeds buffer')
        for row in range(accessor['count']):
            result=struct.unpack_from('<'+code*width,binary,start+row*stride)
            if accessor.get('normalized',False) and code!='f':
                divisor=255 if code=='B' else 65535 if code=='H' else 127 if code=='b' else 32767
                result=tuple(max(-1.0,n/divisor) for n in result)
            yield result
    vertices=0;triangles=0;surfaces=0;weight_error=0.0
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            surfaces+=1
            if primitive.get('mode',4)!=4:raise ValueError('Nontriangle surface')
            attrs=primitive['attributes'];positions=list(values(attrs['POSITION']));vertices+=len(positions)
            if any(not math.isfinite(n) for point in positions for n in point):raise ValueError('Invalid coordinates')
            weights=list(values(attrs['WEIGHTS_0']));indices=list(values(attrs['JOINTS_0']))
            if len(weights)!=len(positions) or len(indices)!=len(positions):raise ValueError('Skin size mismatch')
            for ws,js in zip(weights,indices):
                if any(not math.isfinite(w) or w<0 for w in ws):raise ValueError('Invalid deformation weight')
                weight_error=max(weight_error,abs(sum(ws)-1.0))
                if any(j<0 or j>=len(joints) for j in js):raise ValueError('Absent joint index')
            count=document['accessors'][primitive['indices']]['count'] if 'indices' in primitive else len(positions)
            triangles+=count//3
    if weight_error>.0001 or surfaces>3 or triangles>100000:raise ValueError('Skin or mobile budget exceeded')
    images=[]
    for image in document.get('images',[]):
        if image.get('mimeType')!='image/png' or 'bufferView' not in image:raise ValueError('Expected embedded PNG')
        view=document['bufferViews'][image['bufferView']];start=view.get('byteOffset',0)
        png=binary[start:start+view['byteLength']]
        if image.get('name')!='hero_albedo' or not png.startswith(b'\x89PNG\r\n\x1a\n'):raise ValueError('Invalid atlas')
        if png!=(ROOT/'art/source/textures/hero_albedo.png').read_bytes():raise ValueError('Source atlas differs from GLB')
        target=ROOT/'assets/models/hero_hero_albedo.png'
        if sync:target.write_bytes(png)
        elif not target.exists() or target.read_bytes()!=png:raise ValueError('Stale Godot atlas')
        images.append({'name':image['name'],'bytes':len(png),'sha256':hashlib.sha256(png).hexdigest()})
    if len(images)!=1:raise ValueError('Expected one shared atlas')
    report={'asset':'assets/models/hero.glb','bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'joints':names,
            'clips':sorted(CLIPS),'surfaces':surfaces,'triangles':triangles,'vertices':vertices,
            'maximum_weight_sum_error':weight_error,'images':images,
            'godot_imported':False,'gameplay_tested':False,'android_built':False}
    (ROOT/'art/source/hero.export.json').write_text(json.dumps(report,indent=2)+'\n')
    return report
if __name__=='__main__':print(json.dumps(inspect(),indent=2))
