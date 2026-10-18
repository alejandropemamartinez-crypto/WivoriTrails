extends Node3D
class_name MarketWorld

# The scene is native geometry. All collectible crops, props and trees exist in 3D.
var crop_spots: Array[Dictionary] = []
var dynamic_animals: Array[Dictionary] = []
var farm_root: Node3D
var orchard_root: Node3D
var pier_root: Node3D
var orchard_open := false
var pier_open := false
var clock := 0.0
var rng := RandomNumberGenerator.new()
var shared_meshes := {}
var shared_materials := {}
var market_crates: Array[Node3D] = []

const GREEN = Color("#74b96b")
const DARK_GREEN = Color("#316947")
const WOOD = Color("#a66c3b")
const CREAM = Color("#f4dfb0")
const SOIL = Color("#6e4b36")
const RED = Color("#da6555")
const BLUE = Color("#57a3b9")

func material(tint: Color, rough: float = .91) -> StandardMaterial3D:
	var key := tint.to_html(true) + ":" + str(rough)
	if shared_materials.has(key):return shared_materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = rough
	shared_materials[key] = m
	return m

func shape(parent: Node3D, kind: String, position_: Vector3, scale_: Vector3, tint: Color, name_: String = "") -> MeshInstance3D:
	var item := MeshInstance3D.new()
	if not shared_meshes.has(kind):
		var model: PrimitiveMesh
		match kind:
			"sphere":
				var s := SphereMesh.new(); s.radial_segments = 12; s.rings = 7; model = s
			"cylinder":
				var c := CylinderMesh.new(); c.radial_segments = 12; model = c
			"cone":
				var c := CylinderMesh.new(); c.radial_segments = 12; c.top_radius = 0.0; c.bottom_radius = .5; model = c
			_:
				model = BoxMesh.new()
		shared_meshes[kind] = model
	item.mesh = shared_meshes[kind]
	item.material_override = material(tint)
	item.position = position_
	item.scale = scale_
	item.name = name_ if name_ != "" else kind
	parent.add_child(item)
	return item

func batch_paving(pieces: Array[Dictionary]) -> void:
	# Hundreds of individually instantiated path stones previously caused draw-call pressure.
	# One MultiMesh draw handles them, with per-instance color variations.
	var path_mesh := BoxMesh.new()
	var path_material := StandardMaterial3D.new()
	path_material.vertex_color_use_as_albedo=true
	path_material.roughness=.94
	path_mesh.material=path_material
	var batch := MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.use_colors=true
	batch.mesh=path_mesh
	batch.instance_count=pieces.size()
	for i in range(pieces.size()):
		var tile: Dictionary=pieces[i]
		var transform_ := Transform3D(Basis().scaled(tile["scale"]),tile["pos"])
		batch.set_instance_transform(i,transform_)
		batch.set_instance_color(i,tile["color"])
	var n := MultiMeshInstance3D.new()
	n.name="Caminería de bajo coste GPU"
	n.multimesh=batch
	add_child(n)

func make_label(parent: Node3D, message: String, pos: Vector3, size_: int = 70) -> Label3D:
	var label := Label3D.new()
	label.text = message
	label.font_size = size_
	label.pixel_size = .008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#fff6d8")
	label.outline_size = 10
	label.position = pos
	parent.add_child(label)
	return label

func _ready() -> void:
	rng.seed = 271828
	build_land()
	build_market()
	build_farms()
	build_scenery()
	build_expansions()

func build_land() -> void:
	shape(self,"box",Vector3(0,-.42,0),Vector3(65,.8,65),GREEN,"Base de isla")
	shape(self,"box",Vector3(0,-.84,0),Vector3(66,.35,66),Color("#c6aa72"),"Corte de isla")
	# Each paving block is a GPU instance, not a separate scene node.
	var stones: Array[Dictionary] = []
	for i in range(-20,22):
		for j in range(-2,3):
			var p := Vector3(float(j)*.92,.025,float(i)*.95)
			p.x += sin(float(i) * .32) * .45
			stones.append({"pos":p,"scale":Vector3(.86,.08,.86),"color":CREAM.darkened(rng.randf_range(0,.12))})
	for i in range(-5,7):
		for j in range(-4,5):
			stones.append({"pos":Vector3(float(i)*.94,.045,float(j)*.89-2.0),"scale":Vector3(.87,.08,.84),"color":CREAM.darkened(rng.randf_range(0,.16))})
	for z in [-9.0,8.5]:
		for i in range(-12,1):
			stones.append({"pos":Vector3(float(i)*.82,.05,z),"scale":Vector3(.73,.08,.9),"color":CREAM.darkened(rng.randf_range(0,.13))})
	batch_paving(stones)
	# Shallow pond with solid shore, decorative and not in player movement area.
	shape(self,"cylinder",Vector3(18,.08,15),Vector3(7,.12,6),Color("#c8e5ca"))
	shape(self,"cylinder",Vector3(18,.12,15),Vector3(6,.14,5),Color("#5aaec2"))

func build_market() -> void:
	var root := Node3D.new(); root.position = Vector3(4,0,-2); root.name = "Puesto central"; add_child(root)
	shape(root,"box",Vector3(0,.66,0),Vector3(4.5,1.35,3.2),WOOD)
	shape(root,"box",Vector3(0,1.31,1.5),Vector3(4.8,.18,.45),Color("#e9b775"))
	shape(root,"box",Vector3(0,1.75,-1.3),Vector3(4.5,2.25,.28),Color("#d2a36d"))
	# Roof pitched with striped awning parts. The stripe rhythm animates with light.
	for i in range(10):
		shape(root,"box",Vector3((i-4.5)*.49,2.99,.38),Vector3(.48,.14,4.7),Color("#f7ecda") if i%2 == 0 else RED)
	for x in [-2.35,2.35]:
		for z in [-1.35,1.35]:
			shape(root,"cylinder",Vector3(x,1.5,z),Vector3(.17,3.0,.17),Color("#83502f"))
	make_label(root,"MERCADO CON PATAS",Vector3(0,3.45,1.67),45)
	# Product crates and chunky produce form physical sale stock.
	for i in range(4):
		var rack := Node3D.new(); rack.name="Cajón surtido %d" % i; rack.position=Vector3.ZERO; root.add_child(rack)
		market_crates.append(rack)
		var c := Vector3(-1.55 + float(i)*1.03,1.47,1.2)
		shape(root,"box",c,Vector3(.86,.30,.93),Color("#7c4c27"))
		for f in range(6):
			shape(rack,"sphere",c+Vector3((float(f%3)-1.0)*.22,.25+float(f/3)*.18,0),Vector3(.24,.23,.25),[RED,Color("#f3b843"),Color("#8bc963"),Color("#ac71b5")][i])
	# Delivery pad is an explicit, visible interaction area.
	shape(self,"cylinder",Vector3(4,.10,2.5),Vector3(2.8,.11,2.8),Color("#f2c870"))
	make_label(self,"ENTREGAR",Vector3(4,.75,2.5),36)
	# Coin chest and market decorations.
	shape(root,"box",Vector3(2.0,.37,-.05),Vector3(.9,.7,.9),Color("#9a6f40"))
	shape(root,"box",Vector3(2.0,.78,-.05),Vector3(.94,.12,.94),Color("#efcc67"))

func build_farms() -> void:
	farm_root = Node3D.new(); farm_root.name = "Huertos"; add_child(farm_root)
	make_bed("Tomates",Vector3(-8,0,0),Color("#ef6955"),"tomato",true)
	make_bed("Zanahorias",Vector3(-8,0,8),Color("#f4a644"),"carrot",true)
	make_bed("Arandanos",Vector3(-8,0,-9),Color("#816bb1"),"berry",true)

func make_bed(title: String, pos: Vector3, tint: Color, resource: String, enabled_: bool) -> void:
	var bed := Node3D.new(); bed.name = title; bed.position = pos; farm_root.add_child(bed)
	shape(bed,"box",Vector3.ZERO,Vector3(5.5,.5,4.4),Color("#a06e45"))
	shape(bed,"box",Vector3(0,.28,0),Vector3(5.06,.11,3.96),SOIL)
	for row in range(3):
		for col in range(3):
			var local := Vector3((float(col)-1)*1.55,.40,(float(row)-1)*1.25)
			var unit := Node3D.new(); unit.position = local; bed.add_child(unit)
			shape(unit,"cylinder",Vector3(0,.20,0),Vector3(.1,.44,.11),DARK_GREEN)
			shape(unit,"sphere",Vector3(0,.44,0),Vector3(.48,.22,.43),Color("#4e9850"))
			shape(unit,"sphere",Vector3(-.18,.31,.17),Vector3(.33,.32,.32),tint)
			shape(unit,"sphere",Vector3(.20,.32,-.10),Vector3(.31,.29,.31),tint)
			crop_spots.append({"node":unit,"kind":resource,"ready":true,"regrow":0.0,"enabled":enabled_,"root":bed})
	make_label(bed,title.to_upper(),Vector3(0,2.18,-2.35),44)
	# Corners and fences are built from meshes, not backdrop pixels.
	for z in [-2.35,2.35]:
		for x in [-2.85,2.85]:
			shape(bed,"cylinder",Vector3(x,.40,z),Vector3(.16,.93,.16),WOOD)

func build_scenery() -> void:
	for i in range(30):
		var x := rng.randf_range(-28.0,28.0)
		var z := rng.randf_range(-28.0,28.0)
		if absf(x) < 14.0 and absf(z) < 13.0: continue
		build_tree(Vector3(x,0,z),rng.randf_range(.73,1.55))
	# Trees at visible edges frame the player; custom individual crowns and fruit.
	for loc in [Vector3(-14,0,-5),Vector3(-15,0,13),Vector3(-12,0,16),Vector3(13,0,11),Vector3(15,0,-11)]:
		build_tree(loc,1.12)
	for i in range(110):
		var p := Vector3(rng.randf_range(-20,20),.05,rng.randf_range(-22,22))
		if absf(p.x) < 3.5: continue
		shape(self,"sphere",p,Vector3(.12,.15,.12),Color("#f9eab8") if i%2 == 0 else Color("#ffc1d0"))
	# Chicken pen and rustic lamp posts.
	shape(self,"box",Vector3(12,.20,3.2),Vector3(7,.35,5.5),Color("#83bb6b"))
	for x in [8.6,15.4]:
		for z in [.5,5.8]:
			shape(self,"cylinder",Vector3(x,.62,z),Vector3(.20,1.25,.20),WOOD)
	for i in range(4):
		var n := Node3D.new(); n.position = Vector3(10.3+float(i%2)*2.2,.20,2.1+float(i/2)*2); add_child(n)
		shape(n,"sphere",Vector3(0,.48,0),Vector3(.75,.63,.65),Color("#f8f2d9"))
		shape(n,"sphere",Vector3(0,.96,.25),Vector3(.36,.35,.38),Color("#fff7e5"))
		shape(n,"cone",Vector3(0,.90,.59),Vector3(.22,.29,.22),Color("#f2b14b"))
		dynamic_animals.append({"node":n,"base":n.position,"phase":float(i)*1.8})
	for pos in [Vector3(-3,0,3),Vector3(8,0,-7),Vector3(-4,0,13)]:
		shape(self,"cylinder",pos+Vector3(0,1.3,0),Vector3(.17,2.6,.17),WOOD)
		shape(self,"box",pos+Vector3(0,2.4,0),Vector3(.76,.72,.76),Color("#f6d891"))
		shape(self,"cone",pos+Vector3(0,2.83,0),Vector3(1.02,.42,1.02),Color("#593e2d"))

func build_tree(pos: Vector3, scale_: float) -> void:
	var n := Node3D.new(); n.position = pos; n.scale = Vector3.ONE * scale_; add_child(n)
	shape(n,"cylinder",Vector3(0,1.22,0),Vector3(.52,2.46,.50),WOOD)
	for p in [Vector3(-.80,2.65,0),Vector3(.82,2.82,.06),Vector3(0,3.25,0),Vector3(0,2.58,.85)]:
		shape(n,"sphere",p,Vector3(1.32,1.06,1.27),GREEN.darkened(rng.randf_range(.12,.31)))
	for i in range(3):
		var angle := float(i) * TAU / 3.0
		shape(n,"sphere",Vector3(cos(angle)*1.07,2.55,sin(angle)*1.06),Vector3(.2,.21,.2),Color("#ec8a51"))

func build_expansions() -> void:
	orchard_root = Node3D.new(); orchard_root.position = Vector3(14,0,-13); orchard_root.name = "Huerto desbloqueable"; add_child(orchard_root)
	shape(orchard_root,"box",Vector3(0,.05,0),Vector3(10,.22,9),Color("#88c575"))
	for x in [-3.5,0.0,3.5]:
		build_orchard_tree(orchard_root,Vector3(x,0,0))
	make_label(orchard_root,"HUERTO 300 MONEDAS",Vector3(0,5,0),32)
	orchard_root.visible = false
	pier_root = Node3D.new(); pier_root.position = Vector3(19,0,15); pier_root.name = "Muelle desbloqueable"; add_child(pier_root)
	for z in range(5):
		shape(pier_root,"box",Vector3(0,.48,float(z)*1.45),Vector3(4.5,.30,1.28),WOOD)
	pier_root.visible = false

func build_orchard_tree(parent: Node3D, loc: Vector3) -> void:
	var p := Node3D.new(); p.position=loc; parent.add_child(p)
	shape(p,"cylinder",Vector3(0,1,0),Vector3(.45,2,.45),WOOD)
	shape(p,"sphere",Vector3(0,2.6,0),Vector3(2.5,2.2,2.3),Color("#368a65"))
	for k in range(5):
		var theta := float(k)*TAU/5.0
		shape(p,"sphere",Vector3(cos(theta),2.5,sin(theta)),Vector3(.3,.33,.3),RED)

func update_market_stock(stock: Dictionary) -> void:
	for i in range(market_crates.size()):
		var kind := ["tomato","carrot","berry","apple"][i]
		market_crates[i].visible=int(stock.get(kind,0))>0

func open_orchard() -> void:
	orchard_open=true
	orchard_root.visible=true
	make_bed("Manzanas",Vector3(13,0,-13),RED,"apple",true)

func open_pier() -> void:
	pier_open=true
	pier_root.visible=true

func pick_closest(pos: Vector3) -> Dictionary:
	var nearest: Dictionary = {}
	var distance := 3.2
	for crop in crop_spots:
		if not crop["ready"] or not crop["enabled"]: continue
		var at: Vector3 = crop["node"].global_position
		var d := Vector2(at.x-pos.x,at.z-pos.z).length()
		if d < distance:
			distance=d
			nearest=crop
	return nearest

func pick_any() -> Dictionary:
	var available: Array[Dictionary] = []
	for crop in crop_spots:
		if crop["ready"] and crop["enabled"]:
			available.append(crop)
	if available.is_empty(): return {}
	return available[rng.randi_range(0, available.size()-1)]

func harvest(crop: Dictionary) -> String:
	if crop.is_empty() or not crop["ready"]: return ""
	crop["ready"] = false
	crop["regrow"] = 3.0
	crop["node"].scale = Vector3(.1,.1,.1)
	return crop["kind"]

func _process(delta: float) -> void:
	clock+=delta
	for crop in crop_spots:
		if not crop["ready"]:
			crop["regrow"] = float(crop["regrow"])-delta
			crop["node"].scale=Vector3.ONE * maxf(.12, 1.0-float(crop["regrow"])/3.0)
			if crop["regrow"] <= 0:
				crop["ready"] = true
				crop["node"].scale=Vector3.ONE
	for data in dynamic_animals:
		var animal: Node3D = data["node"]
		var phase: float = data["phase"]
		animal.position=data["base"]+Vector3(sin(clock*.9+phase)*.36,0,cos(clock*.75+phase)*.3)
		animal.rotation.y=sin(clock+phase)*.30
