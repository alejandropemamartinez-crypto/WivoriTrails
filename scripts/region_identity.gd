extends Node3D
class_name WivoriRegionIdentity

# Distinct, lightweight scenery for each existing destination. Decorative only:
# production, navigation and save-state ownership stay with WivoriArchipelago.
const Art=preload("res://scripts/art_library.gd")
const REGION_THEMES={
	1:{"name":"Villa Miga · campos dorados","primary":"#bb965a","leaf":"#9caa70"},
	2:{"name":"Puerto Nata · pastos y quesería","primary":"#729985","leaf":"#79a88c"},
	3:{"name":"Bahía Farol · muelles marineros","primary":"#507f94","leaf":"#88b5aa"}
}
var world: MarketWorld
var region_index:=0
var pennants: Array[Dictionary]=[]
var animated_details: Array[Dictionary]=[]
var landmark_count:=0

func configure(source: MarketWorld, selected: int) -> void:
	world=source
	region_index=selected

func _ready() -> void:
	if world==null or not REGION_THEMES.has(region_index):return
	name=REGION_THEMES[region_index]["name"]
	_coastal_details()
	match region_index:
		1:_fields_and_harvest()
		2:_pasture_and_dairy()
		3:_maritime_quarter()
	set_process(not pennants.is_empty() or not animated_details.is_empty())

func _solid(kind: String, at: Vector3, size_: Vector3, color_: Color, title: String="") -> MeshInstance3D:
	return world.shape(self,kind,at,size_,color_,title)

func _asset(asset: String, at: Vector3, size_: float=1.0) -> Node3D:
	var item: Node3D=Art.place(self,asset,at,Vector3.ONE*size_)
	landmark_count+=1
	return item

func _coastal_details() -> void:
	# The coast is outside the commercial lanes and away from buildable plots.
	var stone:=Color("#ded1a7")
	for i in range(18):
		var side:float=-1.0 if i%2==0 else 1.0
		var z:float=-22.0+float(i/2)*5.2
		var pebble:=_solid("sphere",Vector3(side*27.5,.03,z),Vector3(.34,.16,.25),stone.darkened(float(i%3)*.08))
		pebble.rotation.y=float(i)*.73
	# Repeated coastal reeds share a single draw call per district.
	var grass:=BoxMesh.new()
	grass.size=Vector3(.08,.36,.065)
	var grass_mat:=StandardMaterial3D.new()
	grass_mat.vertex_color_use_as_albedo=true
	grass_mat.roughness=1.0
	grass.material=grass_mat
	var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.use_colors=true
	batch.mesh=grass
	batch.instance_count=90
	for i in range(batch.instance_count):
		var side:float=-1.0 if i%2==0 else 1.0
		var z:float=-24.0+float(i/2)*1.02
		var size_:float=.66+float(i%5)*.13
		batch.set_instance_transform(i,Transform3D(Basis(Vector3.UP,float(i)*1.77).scaled(Vector3.ONE*size_),Vector3(side*(25.7+float(i%3)*.31),.2,z)))
		batch.set_instance_color(i,Color(REGION_THEMES[region_index]["leaf"]).lightened(float(i%4)*.07))
	var reeds:=MultiMeshInstance3D.new()
	reeds.name="Juncos costeros · instanciados"
	reeds.multimesh=batch
	reeds.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(reeds)

func _fields_and_harvest() -> void:
	# Villa Miga is predominantly agricultural: furrows, hay bales, grain flags.
	var earth:=Color("#977451")
	for lane in range(3):
		var x:float=9.0+float(lane)*3.6
		_solid("box",Vector3(x,.085,-23),Vector3(2.5,.12,5.5),earth,"Surco agrícola")
		for row in range(5):
			var z:float=-25.0+float(row)*1.0
			for k in range(3):
				_solid("cone",Vector3(x+(float(k)-1.0)*.6,.41,z),Vector3(.24,.58,.24),Color("#cca45e"),"Espiga decorativa")
	for at in [Vector3(-17,0,-23),Vector3(-20,0,-23),Vector3(-17,0,-20)]:
		_solid("cylinder",at+Vector3(0,.48,0),Vector3(1.5,.95,1.1),Color("#d0a765"),"Rollo de heno")
	_solid("cylinder",Vector3(-19,.72,16),Vector3(.25,1.45,.25),Color("#927051"),"Mástil del campo")
	_banner(Vector3(-19,1.55,16),Color("#d8aa58"),0.0)
	_asset("flower_cart",Vector3(16,0,15),.78)
	_solid("box",Vector3(16,.11,15),Vector3(3,.15,2.5),Color("#d6bf8f"),"Plazoleta de la cosecha")

func _pasture_and_dairy() -> void:
	# Puerto Nata is livestock country, but animals only appear when their
	# actual project has been purchased: scenery must never fake progression.
	for z in [-24.0,-21.5,-19.0]:
		_solid("box",Vector3(16,.11,z),Vector3(8,.10,1.4),Color("#a4bf89"),"Pradera cercada")
	for x in [11.8,20.2]:
		for z in [-25.0,-17.8]:
			_solid("cylinder",Vector3(x,.65,z),Vector3(.16,1.3,.16),Color("#98704e"),"Poste de pradera")
	for z in [-25.0,-17.8]:
		_solid("box",Vector3(16,1.15,z),Vector3(8.5,.12,.12),Color("#ba9568"),"Cerca de pradera")
	for i in range(4):
		var x:float=-15.5+float(i)*2.4
		_solid("cylinder",Vector3(x,.48,16),Vector3(.90,.96,.90),Color("#b58c68"),"Barril de lácteos")
		_solid("cylinder",Vector3(x,1.00,16),Vector3(.94,.13,.94),Color("#e0c18c"))
	_solid("box",Vector3(-12,.12,16),Vector3(11,.18,3),Color("#c9b996"),"Plaza de barriles")
	_banner(Vector3(10,2.1,15),Color("#88b9a2"),1.0)
	_asset("flower_cart",Vector3(-18,0,17),.7)

func _maritime_quarter() -> void:
	# Bahía Farol is the shipping destination: cargo, navigation markers and
	# lights are visually different from the two agrarian towns.
	for i in range(3):
		var at:=Vector3(-14.5+float(i)*2.1,.12,16)
		_solid("box",at,Vector3(1.85,.2,2.6),Color("#ad8a67"),"Plataforma de carga")
		_asset("goods_crate",at+Vector3(0,.25,0),.78)
	for x in [-17.0,17.0]:
		_solid("cylinder",Vector3(x,.9,21.5),Vector3(.26,1.8,.26),Color("#8c6b52"),"Bolardo portuario")
		_solid("cylinder",Vector3(x,1.8,21.5),Vector3(.53,.19,.53),Color("#e2bb83"))
		_solid("sphere",Vector3(x,.25,24.2),Vector3(.5,.45,.5),Color("#d6a362"),"Boya de navegación")
		_solid("sphere",Vector3(x,.38,24.2),Vector3(.23,.13,.23),Color("#fff3d7"))
	for i in range(4):
		_banner(Vector3(12.0+float(i)*1.5,2.6,17.0),Color("#f0cf89") if i%2==0 else Color("#79bac8"),float(i)*.6)
	for at in [Vector3(-20,0,17),Vector3(20,0,17)]:
		_solid("cylinder",at+Vector3(0,1.4,0),Vector3(.16,2.8,.16),Color("#846c58"),"Farol de muelle")
		_solid("sphere",at+Vector3(0,2.85,0),Vector3(.48,.48,.48),Color("#ffe6a0"),"Luz del muelle")
		_solid("cone",at+Vector3(0,3.18,0),Vector3(.9,.38,.9),Color("#427b85"))

func _banner(at: Vector3, color_: Color, phase: float) -> void:
	var pennant:=Node3D.new()
	pennant.position=at
	pennant.name="Banderín animado de distrito"
	add_child(pennant)
	world.shape(pennant,"box",Vector3(.36,0,0),Vector3(.72,.48,.08),color_)
	pennants.append({"node":pennant,"phase":phase})
	landmark_count+=1

func _process(delta: float) -> void:
	var seconds:float=Time.get_ticks_msec()*.001
	for entry in pennants:
		var node: Node3D=entry["node"]
		if is_instance_valid(node):node.rotation.z=.07*sin(seconds*1.5+entry["phase"])
