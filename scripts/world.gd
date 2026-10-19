extends Node3D
class_name MarketWorld

# Gameplay geometry and original imported production meshes share navigation.
const Art=preload("res://scripts/art_library.gd")
const TownFont=preload("res://assets/fonts/Quicksand-Bold.ttf")
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
var sign_textures := {}
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

const GREEN = Color("#79a984")
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

func make_label(parent: Node3D, message: String, pos: Vector3, size_: int = 70, sign_: bool=false) -> Label3D:
	var is_sign: bool=sign_ or message in ["ENTREGAR","TESORERÍA","Tomates","Zanahorias","ARÁNDANOS","TOMATES","ZANAHORIAS","ARANDANOS","MUELLE","PEDIDO PREMIUM","ENCARGOS DEL VALLE","WIVORI"] or message in ["RUTA AL FARO","EMBARCAR","CAJA LOCAL"] or parent.name.begins_with("Caja ")
	var label: Label3D=preload("res://scripts/world_sign.gd").new() if is_sign else Label3D.new()
	if is_sign:
		label.symbol="money" if message=="TESORERÍA" or message in ["RUTA AL FARO","EMBARCAR","CAJA LOCAL"] or parent.name.begins_with("Caja ") else "harvest" if message in ["Tomates","Zanahorias","ARÁNDANOS","TOMATES","ZANAHORIAS","ARANDANOS"] else "deliver"
		size_=maxi(size_,46)
	label.text = message
	label.font=TownFont
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
	var quarters:=preload("res://scripts/village_scenery.gd").new()
	quarters.w=self
	add_child(quarters)
	navigation.build()

func build_land() -> void:
	var grass:=shape(self,"box",Vector3(0,-.42,0),Vector3(150,.8,150),GREEN,"Base de isla")
	var lawn:=ShaderMaterial.new();lawn.shader=preload("res://scripts/ground.gdshader");lawn.set_shader_parameter("base_color",Color("#6d9e72"));grass.material_override=lawn
	shape(self,"box",Vector3(0,-.84,0),Vector3(151,.35,151),Color("#c6aa72"),"Corte de isla")
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
	for child in get_children():
		if child is MeshInstance3D and child.name in ["Paseo principal","Plaza comercial","Zona de fila"]:
			var cobble:=ShaderMaterial.new();cobble.shader=preload("res://scripts/ground.gdshader");cobble.set_shader_parameter("cobbled",true);cobble.set_shader_parameter("base_color",Color("#d2c3a1"));child.material_override=cobble
	for i in range(6):
		var at := Vector3(8.3,.14,.6) if i==0 else Vector3(9.5+(.55 if i%2==0 else 0),.14,.8+float(i)*1.4)
		shape(self,"cylinder",at,Vector3(.85,.035,.85),Color("#e1cfaa"),"Lugar de cliente %d" % i)
	# Shallow pond with solid shore, decorative and not in player movement area.
	shape(self,"cylinder",Vector3(18,.08,15),Vector3(7,.12,6),Color("#c8e5ca"))
	shape(self,"cylinder",Vector3(18,.12,15),Vector3(6,.14,5),Color("#5aaec2"))

func build_market() -> void:
	navigation.add_obstacle(Rect2(1.30,-3.95,5.40,4.25))
	var root:=Node3D.new();root.position=Vector3(4,0,-2);root.name="Mercado Wivori";add_child(root)
	Art.place(root,"market")
	var title:=make_label(root,"WIVORI",Vector3(0,2.80,1.65),58)
	title.outline_size=8;title.pixel_size=.008
	for i in range(4):
		var rack:=Node3D.new();root.add_child(rack);market_crates.append(rack)
		for f in range(5):
			var at:=Vector3(-1.65+float(i)*1.10+(float(f%2)-.5)*.23,1.22+float(f/2)*.12,1.77)
			Art.place(rack,"produce_"+["tomato","carrot","berry","apple"][i],at,Vector3.ONE*.55)
	shape(self,"box",Vector3(4,.10,2.5),Vector3(3.7,.12,2.7),Color("#aa8967"),"Terraza de entregas")
	var rug:=shape(self,"box",Vector3(4,.18,2.5),Vector3(3.30,.08,2.34),Color("#d6ba84"),"Alfombra de entregas")
	var paint:=ShaderMaterial.new();paint.shader=preload("res://scripts/ground.gdshader");paint.set_shader_parameter("cobbled",true);paint.set_shader_parameter("base_color",Color("#e0c89a"));rug.material_override=paint
	var sign:=make_label(self,"ENTREGAR",Vector3(1.25,1.7,3.5),48)
	sign.pixel_size=.011

func build_farms() -> void:
	farm_root = Node3D.new(); farm_root.name = "Huertos"; add_child(farm_root)
	make_bed("Tomates",Vector3(-8,0,0),Color("#ef6955"),"tomato",true)
	make_bed("Zanahorias",Vector3(-8,0,8),Color("#f4a644"),"carrot",true)
	make_bed("Arandanos",Vector3(-8,0,-9),Color("#816bb1"),"berry",true)

func make_bed(title: String, pos: Vector3, tint: Color, resource: String, enabled_: bool) -> void:
	var bed:=Node3D.new();bed.name=title;bed.position=pos;farm_root.add_child(bed)
	shape(bed,"box",Vector3.ZERO,Vector3(5.5,.5,4.4),Color("#a97e52"))
	shape(bed,"box",Vector3(0,.28,0),Vector3(5.06,.11,3.96),Color("#725941"))
	for z in [-2.16,2.16]:
		shape(bed,"box",Vector3(0,.34,z),Vector3(5.6,.18,.16),Color("#c79e69"))
	for x in [-2.72,2.72]:
		shape(bed,"box",Vector3(x,.34,0),Vector3(.16,.18,4.4),Color("#c79e69"))
	for row in range(3):
		for col in range(3):
			var at:=Vector3((float(col)-1)*1.55,.40,(float(row)-1)*1.25)
			var unit:=Node3D.new();unit.position=at;bed.add_child(unit)
			for j in range(2 if resource!="carrot" else 3):
				Art.place(unit,"produce_"+resource,Vector3((j-.5)*.27,.06,float(j%2)*.15),Vector3.ONE*(1.15 if resource!="berry" else 1.35))
			crop_spots.append({"node":unit,"kind":resource,"ready":true,"regrow":0.0,"enabled":enabled_,"root":bed})
	var label:=make_label(bed,title.to_upper(),Vector3(0,1.20,-2.35),39)
	label.pixel_size=.010;label.outline_size=0
	_batch_crop_bed(bed)

func _batch_crop_bed(bed: Node3D) -> void:
	var groups: Dictionary={}
	for crop in crop_spots:
		if crop["root"]!=bed:continue
		crop["instances"]=[]
		for part in crop["node"].find_children("*","MeshInstance3D",true,false):
			var key: int=part.mesh.get_instance_id()
			if not groups.has(key):groups[key]=[]
			groups[key].append({"mesh":part,"crop":crop,"local":crop["node"].global_transform.affine_inverse()*part.global_transform})
	for entries in groups.values():
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=entries[0]["mesh"].mesh;batch.instance_count=entries.size()
		var draw:=MultiMeshInstance3D.new();draw.multimesh=batch;draw.name="Cultivos instanciados";bed.add_child(draw)
		for i in range(entries.size()):
			var entry: Dictionary=entries[i]
			batch.set_instance_transform(i,entry["crop"]["node"].transform*entry["local"])
			entry["crop"]["instances"].append({"batch":batch,"index":i,"local":entry["local"]});entry["mesh"].queue_free()

func update_crop_visual(crop: Dictionary) -> void:
	for part in crop.get("instances",[]):part["batch"].set_instance_transform(part["index"],crop["node"].transform*part["local"])

func build_scenery() -> void:
	for i in range(30):
		var x := rng.randf_range(-28.0,28.0)
		var z := rng.randf_range(-28.0,28.0)
		if absf(x) < 14.0 and absf(z) < 13.0: continue
		var plot_overlap:=false
		for plot in [Vector2(-18,-8),Vector2(-17,8),Vector2(14,21),Vector2(-29,-22),Vector2(-29,-4),Vector2(28,-20),Vector2(28,0),Vector2(-13,29),Vector2(8,29)]:
			if Vector2(x,z).distance_to(plot)<4.6:plot_overlap=true;break
		if plot_overlap:continue
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
	var radius:=.28*scale_+.25
	navigation.add_obstacle(Rect2(Vector2(pos.x,pos.z)-Vector2.ONE*radius,Vector2.ONE*radius*2))
	var tree:=Art.place(self,"tree",pos,Vector3.ONE*scale_)
	tree.rotation.y=rng.randf_range(0,TAU)

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
	var tree:=Art.place(parent,"tree",loc,Vector3.ONE*1.04)
	for i in range(5):
		var angle:=float(i)*TAU/5
		Art.place(tree,"produce_apple",Vector3(cos(angle)*.95,2.15,sin(angle)*.80),Vector3.ONE*.66)

func _sign_texture(accent: Color) -> Texture2D:
	var key:=accent.to_html()
	if sign_textures.has(key):return sign_textures[key]
	# A crisp wooden plaque with high-contrast trim, independent of roof angle.
	var canvas:=Image.create(360,168,false,Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	for py in range(168):
		for px in range(360):
			var radius: float=24.0
			var bx: float=maxf(absf(float(px)-180.0)-156.0,0)
			var by: float=maxf(absf(float(py)-84.0)-60.0,0)
			var dist: float=sqrt(bx*bx+by*by)
			if dist<radius:
				var alpha: float=clampf(radius-dist,0,1)
				var border: bool=dist>radius-9 or px<11 or py<11 or px>348 or py>155
				var base: Color=accent.darkened(.30) if border else Color("#fff0c9")
				if py>107 and not border:base=Color("#e9c993")
				base.a=alpha
				canvas.set_pixel(px,py,base)
	var texture:=ImageTexture.create_from_image(canvas)
	sign_textures[key]=texture
	return texture

func _upgrade_emblem(node: Node3D, kind: String, accent: Color) -> void:
	var p:=Node3D.new()
	p.position=Vector3(0,2.35,-.13)
	p.name="Ícono grande de "+kind
	node.add_child(p)
	match kind:
		"helper":
			for x in [-.29,.29]:
				shape(p,"sphere",Vector3(x,.12,0),Vector3(.36,.40,.29),Color("#ebd7ad"))
				shape(p,"sphere",Vector3(x,-.22,.10),Vector3(.38,.44,.28),accent)
		"bag":
			shape(p,"box",Vector3(0,0,.0),Vector3(.92,.88,.45),Color("#9a6a47"))
			shape(p,"sphere",Vector3(0,.28,-.07),Vector3(.59,.29,.30),accent)
			shape(p,"box",Vector3(0,0,.27),Vector3(.50,.30,.09),Color("#f3d183"))
		"speed":
			var arrow:=shape(p,"cone",Vector3(0,.07,.0),Vector3(.85,1.06,.5),Color("#edbf55"))
			arrow.rotation.z=PI
			shape(p,"box",Vector3(0,-.18,.08),Vector3(.31,.51,.18),accent)
		"checkout":
			shape(p,"box",Vector3(0,-.04,0),Vector3(1.05,.55,.47),accent)
			shape(p,"box",Vector3(0,.33,.01),Vector3(.79,.23,.44),Color("#f5d394"))
		"expand":
			shape(p,"cylinder",Vector3(0,-.1,0),Vector3(.32,.92,.32),Color("#956b4e"))
			for x in [-.38,.38]:
				shape(p,"sphere",Vector3(x,.34,0),Vector3(.74,.67,.64),Color("#72ae78"))
		"pier":
			shape(p,"box",Vector3(0,-.26,0),Vector3(1.20,.28,.62),Color("#639db0"))
			shape(p,"cone",Vector3(0,.31,0),Vector3(.83,.76,.31),Color("#fff3d7"))
		"lock":
			shape(p,"box",Vector3(0,-.12,.10),Vector3(.70,.58,.38),Color("#e5bd6e"))
			shape(p,"cylinder",Vector3(0,.30,-.02),Vector3(.41,.68,.40),accent)
		"alarm":
			shape(p,"cone",Vector3(0,.10,.0),Vector3(1.0,.84,.9),Color("#d87a59"))
			shape(p,"sphere",Vector3(0,-.40,.11),Vector3(.35,.28,.30),Color("#f3c474"))
		"collector":
			shape(p,"box",Vector3(0,0,0),Vector3(.85,.67,.45),Color("#e5b55e"))
			shape(p,"sphere",Vector3(0,.32,.07),Vector3(.43,.30,.30),Color("#f6df96"))
		"guard":
			shape(p,"box",Vector3(0,0,0),Vector3(.86,.92,.27),Color("#6c8e9d"))
			shape(p,"sphere",Vector3(0,.12,.18),Vector3(.43,.47,.19),Color("#e3ce93"))
		_:
			shape(p,"sphere",Vector3.ZERO,Vector3.ONE*.6,accent)

func build_upgrade_pads() -> void:
	var locations: Dictionary=preload("res://scripts/town_layout.gd").UPGRADES
	var names: Dictionary={"helper":"AYUDANTES","collector":"RECAUDADOR","bag":"MOCHILA","speed":"TURBO","checkout":"CAJA","expand":"HUERTO","pier":"MUELLE","lock":"CERROJO","alarm":"ALARMA","guard":"GUARDIA"}
	var colors: Dictionary={"helper":Color("#d79b5c"),"collector":Color("#479d90"),"bag":Color("#b77d5a"),"speed":Color("#709db9"),"checkout":Color("#539d91"),"expand":Color("#7ca775"),"pier":Color("#709da5"),"lock":Color("#7c8ca5"),"alarm":Color("#cc8067"),"guard":Color("#6f88aa")}
	for kind in locations:
		var stall:=Node3D.new();stall.position=locations[kind];stall.name="Oficio: "+kind;add_child(stall)
		Art.place(stall,"booth_"+kind,Vector3(0,0,-1.15))
		navigation.add_obstacle(Rect2(stall.position.x-1.08,stall.position.z-2.02,2.16,1.48))
		var badge:=Sprite3D.new();badge.texture=_sign_texture(colors[kind]);badge.pixel_size=.007
		badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED;badge.position=Vector3(0,3.55,-1.15);badge.no_depth_test=true;stall.add_child(badge)
		var label:=make_label(stall,names[kind],Vector3(0,3.76,-.96),44)
		label.pixel_size=.0063;label.modulate=Color("#314c4c");label.outline_size=0;label.no_depth_test=true;label.render_priority=6
		var price:=make_label(stall,"",Vector3(0,3.37,-.92),39)
		price.pixel_size=.007;price.modulate=Color("#765c3a");price.outline_size=0;price.no_depth_test=true;price.render_priority=7
		var face:=shape(stall,"box",Vector3(0,.09,.10),Vector3(1.65,.10,.65),Color("#dbceaa"),"Escalón de compra")
		upgrade_pads[kind]={"node":stall,"face":face,"label":label,"price":price,"board":badge,"short":names[kind],"afford":false}

func update_upgrade_pads(upgrades: Dictionary, coins: int, recommended: String) -> void:
	for kind in upgrade_pads:
		var pad: Dictionary=upgrade_pads[kind]
		var upgrade: Dictionary=upgrades[kind]
		var afford: bool=coins>=upgrade["price"] and not upgrade["locked"] and not upgrade["done"]
		pad["node"].visible=true
		pad["afford"]=afford
		pad["face"].material_override=material(Color("#e4c27d") if afford else Color("#d2c9ac"))
		pad["label"].text=pad["short"]
		pad["price"].text=("NIVEL 4" if kind=="guard" else "NIVEL 3") if upgrade["locked"] else ("LISTO ✓" if upgrade["done"] else "●  %d" % upgrade["price"])
		pad["price"].modulate=Color("#a57637") if afford else Color("#697c75")

func focus_upgrade_labels(player_pos: Vector3, building: bool, recommended: String) -> void:
	var nearest:=""
	var best:=5.0
	for kind in upgrade_pads:
		var distance: float=player_pos.distance_to(upgrade_pads[kind]["node"].position)
		if distance<best:best=distance;nearest=kind
	for kind in upgrade_pads:
		var pad: Dictionary=upgrade_pads[kind]
		var distance: float=player_pos.distance_to(pad["node"].position)
		var show_label: bool=not building and distance>2.1 and (kind==nearest or kind==recommended and distance<10)
		pad["label"].visible=show_label;pad["price"].visible=show_label;pad["board"].visible=show_label

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
	update_crop_visual(crop)
	return crop["kind"]

func _process(delta: float) -> void:
	clock+=delta
	for pad in upgrade_pads.values():
		var bob: float=sin(clock*3.1)*.055 if pad["afford"] else 0.0
		pad["board"].position.y=3.55+bob
		pad["label"].position.y=3.76+bob
		pad["price"].position.y=3.37+bob
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
			update_crop_visual(crop)
	for data in dynamic_animals:
		var animal: Node3D = data["node"]
		var phase: float = data["phase"]
		animal.position=data["base"]+Vector3(sin(clock*.9+phase)*.36,0,cos(clock*.75+phase)*.3)
		animal.rotation.y=sin(clock+phase)*.30

func build_security() -> void:
	navigation.add_obstacle(Rect2(-2.15,-15.6,4.3,2.8))
	premium_root=Node3D.new(); premium_root.position=Vector3(0,0,-14.2); add_child(premium_root)
	Art.place(premium_root,"premium",Vector3.ZERO,Vector3(.78,.82,.75))
	premium_label=make_label(premium_root,"PEDIDO PREMIUM ×2",Vector3(0,4.2,.6),43)
	premium_label.pixel_size=.010
	premium_root.visible=false
	security_root=Node3D.new(); add_child(security_root)
	lock_root=Node3D.new(); security_root.add_child(lock_root)
	Art.place(lock_root,"treasury",Vector3(6,0,1.3),Vector3.ONE*.80)
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
	if point.distance_to(Vector2(4,2.5))<1.48:height=.19
	for pad in upgrade_pads.values():
		if pad["node"].visible and point.distance_to(Vector2(pad["node"].position.x,pad["node"].position.z))<.78:height=maxf(height,.16)
	for bed in farm_root.get_children():
		if absf(at.x-bed.position.x)<2.75 and absf(at.z-bed.position.z)<2.2:height=maxf(height,.335)
	return height
