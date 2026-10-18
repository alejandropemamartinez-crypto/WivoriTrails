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
var navigation = preload("res://scripts/navigation.gd").new()
var pier_boat: Node3D
var pier_label: Label3D
var orchard_label: Label3D
var upgrade_pads := {}
var locked_sites := {}
var hero_ring: MeshInstance3D
var premium_root: Node3D
var premium_label: Label3D
var security_root: Node3D
var lock_root: Node3D
var alarm_root: Node3D
var alarm_ring: MeshInstance3D
var security_active := false
var alarm_radius := 6.0

const GREEN = Color("#90bc92")
const DARK_GREEN = Color("#316947")
const WOOD = Color("#ba8d62")
const CREAM = Color("#f4dfb0")
const SOIL = Color("#6e4b36")
const RED = Color("#df7867")
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
	if scale_.x*scale_.y*scale_.z<.30:item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	label.outline_size = 4
	label.outline_modulate = Color("#244b40")
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
	build_upgrade_pads()
	build_security()
	navigation.build()

func build_land() -> void:
	shape(self,"box",Vector3(0,-.42,0),Vector3(65,.8,65),GREEN,"Base de isla")
	shape(self,"box",Vector3(0,-.84,0),Vector3(66,.35,66),Color("#c6aa72"),"Corte de isla")
	# Broad quiet surfaces give the arrows, produce and interaction pads priority.
	shape(self,"box",Vector3(0,.02,0),Vector3(5.0,.12,43),Color("#b9a887"),"Paseo principal")
	shape(self,"box",Vector3(4.8,.035,-.4),Vector3(12.5,.14,10),Color("#b9a887"),"Plaza comercial")
	shape(self,"box",Vector3(9.5,.045,4.6),Vector3(3.5,.14,8.6),Color("#b6a283"),"Zona de fila")
	for z in [-9.0,0.0,8.5]:
		shape(self,"box",Vector3(-5,.04,z),Vector3(9,.12,1.8),Color("#b9a887"))
	var stones: Array[Dictionary]=[]
	for z in range(-10,11):
		for x in [-2.7,2.7]:
			stones.append({"pos":Vector3(x,.04,float(z)*2),"scale":Vector3(.24,.16,1.5),"color":Color("#c2b291")})
	batch_paving(stones)
	for i in range(6):
		var at := Vector3(8.3,.14,.6) if i==0 else Vector3(9.5+(.55 if i%2==0 else 0),.14,.8+float(i)*1.4)
		shape(self,"cylinder",at,Vector3(.85,.035,.85),Color("#e1cfaa"),"Lugar de cliente %d" % i)
	# Shallow pond with solid shore, decorative and not in player movement area.
	shape(self,"cylinder",Vector3(18,.08,15),Vector3(7,.12,6),Color("#c8e5ca"))
	shape(self,"cylinder",Vector3(18,.12,15),Vector3(6,.14,5),Color("#5aaec2"))

func build_market() -> void:
	navigation.add_obstacle(Rect2(1.30, -3.95, 5.40, 3.85))
	var root := Node3D.new(); root.position = Vector3(4,0,-2); root.name = "Puesto central"; add_child(root)
	shape(root,"box",Vector3(0,.08,0),Vector3(5.25,.24,4.1),Color("#356a62"),"Base del puesto")
	shape(root,"box",Vector3(0,.66,0),Vector3(4.5,1.35,3.2),WOOD)
	shape(root,"box",Vector3(0,1.31,1.5),Vector3(4.8,.18,.45),Color("#e9b775"))
	shape(root,"box",Vector3(0,1.75,-1.3),Vector3(4.5,2.25,.28),Color("#d2a36d"))
	# Roof pitched with striped awning parts. The stripe rhythm animates with light.
	for i in range(10):
		shape(root,"box",Vector3((i-4.5)*.49,2.99,.38),Vector3(.48,.14,4.7),Color("#f7ecda") if i%2 == 0 else RED)
	for x in [-2.35,2.35]:
		for z in [-1.35,1.35]:
			shape(root,"cylinder",Vector3(x,1.5,z),Vector3(.17,3.0,.17),Color("#83502f"))
	shape(root,"box",Vector3(0,3.23,1.5),Vector3(3.2,.65,.16),Color("#285d59"),"Rótulo")
	make_label(root,"WIVORI",Vector3(0,3.28,1.67),62)
	# Product crates and chunky produce form physical sale stock.
	for i in range(4):
		var rack := Node3D.new(); rack.name="Cajón surtido %d" % i; rack.position=Vector3.ZERO; root.add_child(rack)
		market_crates.append(rack)
		var c := Vector3(-1.55 + float(i)*1.03,1.47,1.2)
		shape(root,"box",c,Vector3(.86,.30,.93),Color("#7c4c27"))
		for f in range(6):
			shape(rack,"sphere",c+Vector3((float(f%3)-1.0)*.22,.25+float(f/3)*.18,0),Vector3(.24,.23,.25),[RED,Color("#f3b843"),Color("#8bc963"),Color("#ac71b5")][i])
	# Delivery pad is an explicit, visible interaction area.
	shape(self,"cylinder",Vector3(4,.12,2.5),Vector3(3.3,.13,3.3),Color("#b18d47"))
	shape(self,"cylinder",Vector3(4,.20,2.5),Vector3(2.95,.08,2.95),Color("#f5d57f"))
	var stock_sign := make_label(self,"ENTREGAR",Vector3(4,.75,2.5),48)
	stock_sign.modulate=Color("#72552d"); stock_sign.outline_size=0; stock_sign.pixel_size=.010
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
			if resource=="carrot":
				shape(unit,"cone",Vector3(0,.20,0),Vector3(.42,-.65,.42),tint)
				for x in [-.15,.15]:
					var leaf := shape(unit,"sphere",Vector3(x,.68,0),Vector3(.18,.50,.16),DARK_GREEN)
					leaf.rotation.z=x*2
			elif resource=="berry":
				shape(unit,"sphere",Vector3(0,.30,0),Vector3(.80,.64,.72),DARK_GREEN)
				for x in [-.22,0,.22]:shape(unit,"sphere",Vector3(x,.55,.25),Vector3(.25,.26,.25),tint)
			else:
				shape(unit,"cylinder",Vector3(0,.30,0),Vector3(.1,.65,.11),DARK_GREEN)
				shape(unit,"sphere",Vector3(0,.64,0),Vector3(.68,.22,.43),Color("#4e9850"))
				shape(unit,"sphere",Vector3(-.18,.38,.17),Vector3(.44,.43,.42),tint)
				shape(unit,"sphere",Vector3(.20,.38,-.10),Vector3(.41,.40,.41),tint)
			crop_spots.append({"node":unit,"kind":resource,"ready":true,"regrow":0.0,"enabled":enabled_,"root":bed})
	var bed_label := make_label(bed,title.to_upper(),Vector3(0,1.65,-2.35),48)
	bed_label.pixel_size=.010
	# Corners and fences are built from meshes, not backdrop pixels.
	for z in [-2.35,2.35]:
		for x in [-2.85,2.85]:
			shape(bed,"cylinder",Vector3(x,.40,z),Vector3(.16,.93,.16),WOOD)

func build_scenery() -> void:
	for i in range(30):
		var x := rng.randf_range(-28.0,28.0)
		var z := rng.randf_range(-28.0,28.0)
		if absf(x) < 14.0 and absf(z) < 13.0: continue
		if absf(x)<4.5 and z>-18 and z<-10:continue
		build_tree(Vector3(x,0,z),rng.randf_range(.73,1.55))
	# Trees at visible edges frame the player; custom individual crowns and fruit.
	for loc in [Vector3(-14,0,-5),Vector3(-15,0,13),Vector3(-12,0,16),Vector3(13,0,11),Vector3(15,0,-11)]:
		build_tree(loc,1.12)
	for i in range(45):
		var p := Vector3(rng.randf_range(-20,20),.05,rng.randf_range(-22,22))
		if absf(p.x)<14 and absf(p.z)<14:continue
		shape(self,"sphere",p,Vector3(.12,.15,.12),Color("#f9eab8") if i%2 == 0 else Color("#ffc1d0"))
	# Chicken pen and rustic lamp posts.
	shape(self,"box",Vector3(16.5,.20,4.0),Vector3(5.5,.35,5.5),Color("#83bb6b"))
	for x in [13.8,19.2]:
		for z in [1.3,6.7]:
			shape(self,"cylinder",Vector3(x,.62,z),Vector3(.20,1.25,.20),WOOD)
	for i in range(4):
		var n := Node3D.new(); n.position = Vector3(15.3+float(i%2)*2.2,.20,3.0+float(i/2)*2); add_child(n)
		shape(n,"sphere",Vector3(0,.48,0),Vector3(.75,.63,.65),Color("#f8f2d9"))
		shape(n,"sphere",Vector3(0,.96,.25),Vector3(.36,.35,.38),Color("#fff7e5"))
		shape(n,"cone",Vector3(0,.90,.59),Vector3(.22,.29,.22),Color("#f2b14b"))
		dynamic_animals.append({"node":n,"base":n.position,"phase":float(i)*1.8})
	for pos in [Vector3(-4.6,0,3.7),Vector3(8,0,-7),Vector3(-5,0,14.5)]:
		navigation.add_obstacle(Rect2(Vector2(pos.x, pos.z) - Vector2.ONE * .38, Vector2.ONE * .76))
		shape(self,"cylinder",pos+Vector3(0,.64,0),Vector3(.17,1.28,.17),WOOD)
		shape(self,"sphere",pos+Vector3(0,1.27,0),Vector3(.46,.50,.46),Color("#f6d891"))
		shape(self,"cone",pos+Vector3(0,1.59,0),Vector3(.67,.25,.67),Color("#326c63"))

func build_tree(pos: Vector3, scale_: float) -> void:
	var radius := .28 * scale_ + .25
	navigation.add_obstacle(Rect2(Vector2(pos.x, pos.z) - Vector2.ONE * radius, Vector2.ONE * radius * 2))
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
	orchard_label=make_label(orchard_root,"HUERTO",Vector3(0,5,0),30)
	orchard_root.visible = false
	pier_root = Node3D.new(); pier_root.position = Vector3(19,0,15); pier_root.name = "Muelle desbloqueable"; add_child(pier_root)
	for z in range(5):
		shape(pier_root,"box",Vector3(0,.48,float(z)*1.45),Vector3(4.5,.30,1.28),WOOD)
	for z in [0.0, 5.8]:
		for x in [-2.15, 2.15]:
			shape(pier_root,"cylinder",Vector3(x,.9,z),Vector3(.2,1.8,.2),WOOD)
	pier_boat = Node3D.new(); pier_boat.name = "Barco de pedidos"; pier_root.add_child(pier_boat)
	shape(pier_boat,"sphere",Vector3(0,.25,0),Vector3(2.1,.60,3.0),Color("#367e96"))
	shape(pier_boat,"box",Vector3(0,.65,0),Vector3(1.3,.6,1.4),CREAM)
	shape(pier_boat,"box",Vector3(0,1.02,0),Vector3(1.5,.16,1.6),RED)
	pier_label = make_label(pier_root,"EXPORTACIÓN AUTOMÁTICA\nReserva 3; envía lotes de 6",Vector3(0,3,0),30)
	update_pier_shipment("",0,0,30)
	pier_root.visible = false

func build_orchard_tree(parent: Node3D, loc: Vector3) -> void:
	var p := Node3D.new(); p.position=loc; parent.add_child(p)
	shape(p,"cylinder",Vector3(0,1,0),Vector3(.45,2,.45),WOOD)
	shape(p,"sphere",Vector3(0,2.6,0),Vector3(2.5,2.2,2.3),Color("#368a65"))
	for k in range(5):
		var theta := float(k)*TAU/5.0
		shape(p,"sphere",Vector3(cos(theta),2.5,sin(theta)),Vector3(.3,.33,.3),RED)

func build_upgrade_pads() -> void:
	var locations := {"helper":Vector3(-2.6,0,6.3),"bag":Vector3(-3,0,11),"speed":Vector3(3.5,0,10),
		"checkout":Vector3(9,0,-3),"expand":Vector3(10,0,-10),"pier":Vector3(16,0,12),"lock":Vector3(7,0,-6.5),"alarm":Vector3(12,0,9.8),"guard":Vector3(7.5,0,11)}
	var names := {"helper":"EQUIPO","bag":"MOCHILA","speed":"TURBO","checkout":"CAJA","expand":"HUERTO","pier":"MUELLE","lock":"CERROJO","alarm":"ALARMA","guard":"GUARDIA"}
	for kind in locations:
		var pad := Node3D.new(); pad.position=locations[kind]; pad.name="Mejora " + kind; add_child(pad)
		shape(pad,"cylinder",Vector3(0,.10,0),Vector3(2.5,.18,2.5),Color("#356a62"))
		var face := shape(pad,"cylinder",Vector3(0,.22,0),Vector3(2.22,.08,2.22),Color("#e9eddf"))
		var sign := make_label(pad,names[kind],Vector3(0,.95,0),52)
		sign.modulate=Color("#285d59"); sign.outline_size=0; sign.pixel_size=.012
		var price := make_label(pad,"",Vector3(0,.47,.35),68)
		price.outline_size=0; price.pixel_size=.012
		upgrade_pads[kind]={"node":pad,"face":face,"label":sign,"price":price,"short":names[kind]}
	for kind in ["expand","pier"]:
		var site := Node3D.new(); add_child(site)
		var center := Vector3(14,0,-13) if kind=="expand" else Vector3(19,0,15)
		shape(site,"box",center+Vector3(0,.03,0),Vector3(9,.12,7),Color("#a3c4a0") if kind=="expand" else Color("#a4c9c2"))
		for x in [-4.5,4.5]:
			for z in [-3.5,3.5]:
				shape(site,"cylinder",center+Vector3(x,.5,z),Vector3(.15,1,.15),CREAM)
		make_label(site,"PRÓXIMO: HUERTO" if kind=="expand" else "PRÓXIMO: EXPORTACIÓN",center+Vector3(0,1.5,-2),30)
		locked_sites[kind]=site

func update_upgrade_pads(upgrades: Dictionary, coins: int, recommended: String) -> void:
	for kind in upgrade_pads:
		var pad: Dictionary=upgrade_pads[kind]
		var upgrade: Dictionary=upgrades[kind]
		var done: bool=upgrade["done"]
		pad["node"].visible=not done and not upgrade["locked"]
		var afford: bool=coins>=upgrade["price"]
		pad["face"].material_override=material(Color("#f6d27b") if afford else Color("#d2dfcf"))
		pad["label"].text=("★ " if kind==recommended and afford else "")+pad["short"]
		pad["price"].text=str(upgrade["price"])
		pad["price"].modulate=Color("#76552c") if afford else Color("#51706b")
		if locked_sites.has(kind):locked_sites[kind].visible=not done

func celebrate_upgrade(kind: String) -> void:
	if not upgrade_pads.has(kind):return
	var at: Vector3=upgrade_pads[kind]["node"].position
	for i in range(9):
		var piece := shape(self,"box",at+Vector3(0,.6,0),Vector3(.16,.16,.16),[RED,BLUE,Color("#f2d382")][i%3])
		var angle := float(i)*TAU/9
		var tween := create_tween().set_parallel(true)
		tween.tween_property(piece,"position",at+Vector3(cos(angle)*2,2.5,sin(angle)*2),.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece,"scale",Vector3.ZERO,.85)
		tween.chain().tween_callback(piece.queue_free)

func sale_receipt(at: Vector3, income: int) -> void:
	var receipt := make_label(self,"+%d" % income,at+Vector3(0,2.8,0),38)
	receipt.modulate=Color("#ffde8c")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(receipt,"position",receipt.position+Vector3(0,1.8,0),1.15)
	tween.tween_property(receipt,"modulate:a",0.0,1.15)
	tween.chain().tween_callback(receipt.queue_free)

func update_market_stock(stock: Dictionary) -> void:
	for i in range(market_crates.size()):
		var kind: String = ["tomato","carrot","berry","apple"][i]
		market_crates[i].visible=int(stock.get(kind,0))>0

func open_orchard() -> void:
	if orchard_open: return
	orchard_open=true
	orchard_root.visible=true
	orchard_label.text="HUERTO DE MANZANAS"
	make_bed("Manzanas",Vector3(13,0,-13),RED,"apple",true)

func open_pier() -> void:
	pier_open=true
	pier_root.visible=true

func update_pier_shipment(kind: String, amount: int, remaining: float, duration: float) -> void:
	if pier_boat == null: return
	if kind.is_empty():
		pier_boat.position = Vector3(-3.1,0,0)
		pier_label.text = "EXPORTACIÓN AUTOMÁTICA\nReserva 3; envía lotes de 6"
	else:
		var progress := clampf(1.0 - remaining / duration, 0, 1)
		var sailing := sin(progress * PI)
		pier_boat.position = Vector3(-3.1 + sailing,0,-sailing * .65)
		pier_label.text = "EXPORTANDO %d\nLlega en %ds" % [amount, ceili(remaining)]

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
	if alarm_root!=null:
		alarm_root.rotation.y=sin(clock*3)*.3 if security_active else 0.0
	if alarm_ring!=null:
		alarm_ring.scale=Vector3.ONE*(alarm_radius/6)*(1+sin(clock*5)*.025)
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

func build_security() -> void:
	navigation.add_obstacle(Rect2(-2.15,-15.6,4.3,2.8))
	premium_root=Node3D.new(); premium_root.position=Vector3(0,0,-14.2); add_child(premium_root)
	shape(premium_root,"box",Vector3(0,.7,0),Vector3(3.6,1.15,2.1),Color("#e8b356"))
	shape(premium_root,"box",Vector3(0,1.39,0),Vector3(3.7,.16,2.2),Color("#356f70"))
	for x in [-1.5,1.5]:
		for z in [-.82,.82]:
			var wheel:=shape(premium_root,"cylinder",Vector3(x,.3,z),Vector3(.50,.16,.50),Color("#45565d")); wheel.rotation.z=PI*.5
	shape(premium_root,"box",Vector3(0,1.9,-.6),Vector3(3.3,.20,2.6),Color("#3c8d86"))
	for x in [-1.45,1.45]:shape(premium_root,"cylinder",Vector3(x,1.5,0),Vector3(.11,1.8,.11),WOOD)
	premium_label=make_label(premium_root,"PEDIDO PREMIUM ×2",Vector3(0,2.9,.6),48)
	premium_label.pixel_size=.010
	premium_root.visible=false
	security_root=Node3D.new(); add_child(security_root)
	lock_root=Node3D.new(); security_root.add_child(lock_root)
	shape(lock_root,"box",Vector3(6,.7,1.3),Vector3(1.2,1.3,1.15),Color("#557a78"))
	shape(lock_root,"box",Vector3(6,.80,1.9),Vector3(1.24,.19,.1),Color("#efc86e"))
	shape(lock_root,"sphere",Vector3(6,.83,2.02),Vector3(.35,.40,.13),Color("#efc86e"))
	lock_root.visible=false
	alarm_root=Node3D.new(); alarm_root.position=Vector3(6,3.3,-1.8); security_root.add_child(alarm_root)
	shape(alarm_root,"cylinder",Vector3(0,.12,0),Vector3(.70,.12,.70),Color("#385d67"))
	shape(alarm_root,"sphere",Vector3(0,.40,0),Vector3(.59,.53,.59),Color("#eaa365"))
	alarm_root.visible=false
	alarm_ring=MeshInstance3D.new(); var ring:=TorusMesh.new(); ring.inner_radius=6; ring.outer_radius=6.04; ring.rings=64; ring.ring_segments=6
	alarm_ring.mesh=ring; alarm_ring.position=Vector3(4,.17,2.5)
	var mat:=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color=Color("#e8a752")
	alarm_ring.material_override=mat; alarm_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	security_root.add_child(alarm_ring); alarm_ring.visible=false

func update_security(run) -> void:
	premium_root.visible=true
	premium_label.text=("PEDIDO PREMIUM ×2\n%d/%d %s" % [run.contract_done,run.contract_goal(),run.g.CROP_NAMES[run.contract_kind()].to_upper()]) if run.level>=4 else "PEDIDOS PREMIUM\nNIVEL 4"
	lock_root.visible=run.lock_level>0
	alarm_root.visible=run.alarm_level>0
	security_active=not run.raiders.is_empty() or run.warning>0
	alarm_radius=6+run.alarm_level
	alarm_ring.visible=run.alarm_level>0 and security_active

func whistle_pulse(at: Vector3) -> void:
	var item:=MeshInstance3D.new(); var mesh:=TorusMesh.new(); mesh.inner_radius=.7; mesh.outer_radius=.8; mesh.rings=32; mesh.ring_segments=6
	item.mesh=mesh; item.position=at+Vector3(0,.25,0)
	var mat:=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color=Color("#fff0b3"); mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	item.material_override=mat; add_child(item)
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(item,"scale",Vector3.ONE*4,.55)
	tween.tween_property(mat,"albedo_color:a",0.0,.55)
	tween.chain().tween_callback(item.queue_free)

func ground_height(at: Vector3) -> float:
	var point:=Vector2(at.x,at.z)
	var height: float=-.02
	if absf(at.x)<2.5 and absf(at.z)<21.5:height=.08
	if Rect2(-1.45,-5.4,12.5,10).has_point(point):height=.105
	if Rect2(7.75,.3,3.5,8.6).has_point(point):height=.115
	if point.distance_to(Vector2(4,2.5))<1.48:height=.28
	for pad in upgrade_pads.values():
		if pad["node"].visible and point.distance_to(Vector2(pad["node"].position.x,pad["node"].position.z))<1.11:height=maxf(height,.30)
	for bed in farm_root.get_children():
		if absf(at.x-bed.position.x)<2.75 and absf(at.z-bed.position.z)<2.2:height=maxf(height,.335)
	return height
