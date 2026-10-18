extends Node3D
class_name WivoriTown

# An independent, playable village layer. Player agency is preserved:
# selecting a plot never moves the character or spends coins.
const TYPES = {
	"house":{"name":"CASA DE VECINOS","price":180,"benefit":"Llegan compradores 25 % más rápido."},
	"cafe":{"name":"CAFÉ DEL PUEBLO","price":340,"benefit":"Las ventas generan 20 % más monedas."},
	"depot":{"name":"ALMACÉN COMUNAL","price":480,"benefit":"Aumenta la mochila en 6."},
	"bakery":{"name":"PANADERÍA DE MIEL","price":560,"benefit":"+10 % de ingreso en ventas."},
	"greenhouse":{"name":"INVERNADERO","price":620,"benefit":"Cada 5 cosechas, una fruta extra."},
	"workshop":{"name":"TALLER DE CAMINOS","price":690,"benefit":"Caminás un 8 % más rápido."},
	"park":{"name":"PARQUE DE FLORES","price":420,"benefit":"Atrae nuevos compradores."},
	"watchtower":{"name":"TORRE VIGÍA","price":750,"benefit":"Alerta de robos con 4 s adicionales."},
	"mill":{"name":"MOLINO DEL VALLE","price":880,"benefit":"Exportaciones un 30 % más rápidas."}
}
const LOCATIONS=[
	Vector3(-18,0,-8),Vector3(-17,0,8),Vector3(14,0,21),
	Vector3(-29,0,-22),Vector3(-29,0,-4),Vector3(28,0,-20),
	Vector3(28,0,0),Vector3(-13,0,29),Vector3(8,0,29)
]
var g: Node3D
var in_build_mode:=false
var camera_center:=Vector3(-1,0,1)
var harvested_count:=0
var selected:=0
var constructed: Array[String]=["","","","","","","","",""]
var plot_nodes: Array[Node3D]=[]
var plot_signs: Array[Label3D]=[]
var plot_glows: Array[MeshInstance3D]=[]

func _ready() -> void:
	name="Pueblo construido por el jugador"
	for i in range(LOCATIONS.size()):
		var plot:=Node3D.new()
		plot.name="Solar %d" % (i+1)
		plot.position=LOCATIONS[i]
		add_child(plot)
		plot_nodes.append(plot)
		g.world.shape(plot,"box",Vector3(0,.045,0),Vector3(5.7,.09,5.5),Color("#e5d1a6"),"Solar de arena")
		for edge in [-2.65,2.65]:
			g.world.shape(plot,"box",Vector3(edge,.24,0),Vector3(.12,.32,5.5),Color("#b78f67"))
			g.world.shape(plot,"box",Vector3(0,.24,edge),Vector3(5.5,.32,.12),Color("#b78f67"))
		var ring: MeshInstance3D=g.world.shape(plot,"box",Vector3(0,.115,0),Vector3(4.75,.11,4.45),Color("#68b4a5"),"Solar seleccionado")
		plot_glows.append(ring)
		var label: Label3D=g.world.make_label(plot,"SOLAR %d" % (i+1),Vector3(0,1.1,0),42)
		label.pixel_size=.009
		label.modulate=Color("#315c58")
		plot_signs.append(label)
	_refresh_plots()

func has_building(kind: String) -> bool:
	return constructed.has(kind)

func income_bonus(income: int) -> int:
	var rate:=0.0
	if has_building("cafe"):rate+=.20
	if has_building("bakery"):rate+=.10
	return maxi(0,int(round(float(income)*rate)))

func customer_interval_factor() -> float:
	var multiplier:=1.0
	if has_building("house"):multiplier*=.75
	if has_building("park"):multiplier*=.90
	return multiplier

func bonus_harvest() -> bool:
	if not has_building("greenhouse"):return false
	harvested_count+=1
	return harvested_count%5==0

func player_speed_factor() -> float:
	return 1.08 if has_building("workshop") else 1.0

func warning_seconds() -> float:
	return 4.0 if has_building("watchtower") else 0.0

func shipment_speed_factor() -> float:
	return 1.30 if has_building("mill") else 1.0

func pan_camera(relative: Vector2) -> void:
	# Drag a map, rather than accidentally moving the player while building.
	var world_move:=Vector3(-relative.x*.085,0,-relative.y*.092)
	camera_center+=world_move
	camera_center.x=clampf(camera_center.x,-26,26)
	camera_center.z=clampf(camera_center.z,-26,26)

func toggle_mode() -> void:
	in_build_mode=not in_build_mode
	if in_build_mode:
		camera_center=g.player.position
		g.boost_active=false
		g.input_stick._clear()
		g.has_tap_destination=false
		g.destination_marker.visible=false
	_refresh_plots()
	g._refresh_ui()

func _refresh_plots() -> void:
	for i in range(plot_nodes.size()):
		var active: bool=in_build_mode and constructed[i].is_empty()
		plot_signs[i].visible=active
		plot_glows[i].visible=active
		if active:
			plot_glows[i].material_override=g.world.material(Color("#efc660") if i==selected else Color("#8bbdb6"))

func select_at(point: Vector3) -> bool:
	var choice: int=-1
	var best:=4.2
	for i in range(LOCATIONS.size()):
		var distance:=point.distance_to(LOCATIONS[i])
		if distance<best:
			best=distance
			choice=i
	if choice<0:
		return false
	selected=choice
	camera_center=camera_center.lerp(LOCATIONS[selected],.12)
	_refresh_plots()
	g._refresh_ui()
	return true

func selection_description() -> String:
	var result: String="Solar %d / %d" % [selected+1,LOCATIONS.size()]
	if not constructed[selected].is_empty():
		return result+" · "+TYPES[constructed[selected]]["name"]+" construido"
	return result+" · vacío. Tocá un edificio para construirlo."

func build(kind: String) -> bool:
	if not in_build_mode or not TYPES.has(kind):
		return false
	if not constructed[selected].is_empty():
		return false
	if has_building(kind):
		return false
	var cost: int=TYPES[kind]["price"]
	if g.coins<cost:
		g._notice("Te faltan %d monedas" % (cost-g.coins),1.8)
		return false
	g.coins-=cost
	constructed[selected]=kind
	_make_building(plot_nodes[selected],kind,true)
	if kind=="depot":
		g.max_capacity=mini(300,g.max_capacity+6)
	g.world.navigation.add_obstacle(Rect2(
		Vector2(LOCATIONS[selected].x-2.2,LOCATIONS[selected].z-1.9),Vector2(4.4,3.8)))
	g.world.navigation.build()
	g._notice("¡NUEVA CONSTRUCCIÓN!\n%s" % TYPES[kind]["name"],2.5)
	_refresh_plots()
	g._save_progress()
	g._refresh_ui()
	return true

func _part(root: Node3D,kind: String,at: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
	return g.world.shape(root,kind,at,size,color)

func _make_building(plot: Node3D, kind: String, animated: bool) -> void:
	var building:=Node3D.new()
	building.name=TYPES[kind]["name"]
	plot.add_child(building)
	_part(building,"box",Vector3(0,.20,0),Vector3(4.7,.30,4.2),Color("#ae9672"))
	if kind in ["house","park"]:
		_part(building,"box",Vector3(0,1.55,0),Vector3(3.85,2.7,3.25),Color("#f5ddae"))
		for x in [-1.08,1.08]:
			var roof:=_part(building,"box",Vector3(x,3.00,0),Vector3(2.60,.30,3.78),Color("#b96552"))
			roof.rotation.z=(-.47 if x<0 else .47)
		_part(building,"box",Vector3(0,.96,1.67),Vector3(1.05,1.82,.16),Color("#688c83"))
		for x in [-1.20,1.20]:
			_part(building,"box",Vector3(x,1.95,1.68),Vector3(.63,.7,.10),Color("#95d6dc"))
	elif kind in ["cafe","bakery"]:
		_part(building,"box",Vector3(0,1.24,0),Vector3(4.15,2.00,3.55),Color("#f0d0a0"))
		_part(building,"box",Vector3(0,2.45,0),Vector3(4.85,.45,4.2),Color("#ce765a"))
		_part(building,"box",Vector3(0,.95,1.81),Vector3(1.28,1.5,.12),Color("#477c74"))
		for x in [-1.40,1.40]:
			_part(building,"box",Vector3(x,1.53,1.81),Vector3(.90,1.0,.15),Color("#9edbd5"))
		for x in [-1.52,-.52,.52,1.52]:
			_part(building,"box",Vector3(x,2.14,1.97),Vector3(.91,.52,.44),Color("#fff0db") if absf(x)<1.0 else Color("#d27f60"))
	else:
		_part(building,"box",Vector3(0,1.40,0),Vector3(4.35,2.5,3.80),Color("#9eaa91"))
		_part(building,"box",Vector3(0,2.80,0),Vector3(4.9,.38,4.2),Color("#5c8782"))
		_part(building,"box",Vector3(0,1.02,1.96),Vector3(2.3,1.90,.12),Color("#b99565"))
		for x in [-1.3,1.3]:
			_part(building,"box",Vector3(x,1.9,1.98),Vector3(.42,.53,.08),Color("#ead6a9"))
	# The more advanced buildings get silhouette features and animated details.
	if kind=="greenhouse":
		for x in [-1.4,-.5,.5,1.4]:
			_part(building,"box",Vector3(x,1.1,2.03),Vector3(.17,1.85,.12),Color("#4d8270"))
		_part(building,"box",Vector3(0,2.65,0),Vector3(4.7,.24,4.1),Color("#a9d8ce"))
		for x in [-1.2,1.2]:
			for z in [-1.2,1.2]:
				_part(building,"sphere",Vector3(x,.39,z),Vector3(.8,.65,.75),Color("#7cae79"))
	if kind=="workshop":
		_part(building,"box",Vector3(1.55,2.0,1.92),Vector3(.63,.75,.34),Color("#ce8358"))
		for i in range(3):
			_part(building,"box",Vector3(-1.5+float(i)*.65,.56,2.00),Vector3(.43,.39,.41),Color("#b78957"))
	if kind=="mill":
		_part(building,"cylinder",Vector3(0,3.30,-.3),Vector3(1.4,3.5,1.4),Color("#f0d7b8"))
		_part(building,"cone",Vector3(0,5.30,-.3),Vector3(2.3,1.3,2.3),Color("#b66b54"))
		var wheel:=Node3D.new();wheel.name="Aspas giratorias"
		wheel.position=Vector3(0,3.7,1.1);building.add_child(wheel)
		for i in range(4):
			var blade:=_part(wheel,"box",Vector3(0,1.15,0),Vector3(.42,2.15,.18),Color("#e9e0c2"))
			blade.rotation.z=float(i)*PI*.5
	if kind=="watchtower":
		for x in [-1.6,1.6]:
			for z in [-1.3,1.3]:
				_part(building,"box",Vector3(x,2.9,z),Vector3(.26,5.6,.26),Color("#a87951"))
		_part(building,"box",Vector3(0,5.50,0),Vector3(4.7,.36,4.5),Color("#a3744e"))
		_part(building,"box",Vector3(0,6.02,0),Vector3(5.1,.36,4.9),Color("#dca873"))
	if kind=="park":
		for x in [-1.5,1.5]:
			for z in [-1.5,1.5]:
				_part(building,"sphere",Vector3(x,.40,z),Vector3(.65,.62,.61),Color("#629965"))
		_part(building,"cylinder",Vector3(0,.58,0),Vector3(1.45,.35,1.45),Color("#7baeb1"))
		_part(building,"sphere",Vector3(0,1.12,0),Vector3(.55,.52,.55),Color("#9ed7dc"))
	var sign: Label3D=g.world.make_label(building,TYPES[kind]["name"],Vector3(0,3.65,0),30)
	sign.pixel_size=.008
	sign.modulate=Color("#355952")
	if animated:
		building.scale=Vector3(.08,.02,.08)
		var tween:=create_tween()
		tween.tween_property(building,"scale",Vector3(1.08,1.08,1.08),.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(building,"scale",Vector3.ONE,.19)
		_construction_effect(plot)

func _construction_effect(plot: Node3D) -> void:
	# Build-site dust scatters and fades on real construction.
	for i in range(10):
		var angle:=TAU*float(i)/10.0
		var dust: MeshInstance3D=g.world.shape(plot,"sphere",Vector3(0,.6,0),Vector3(.2,.2,.2),Color("#efcf91"))
		var outward:=Vector3(cos(angle)*2.6,1.3,sin(angle)*2.6)
		var tween:=create_tween().set_parallel(true)
		tween.tween_property(dust,"position",outward,.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(dust,"scale",Vector3.ZERO,.72)
		tween.chain().tween_callback(dust.queue_free)

func save_state() -> Dictionary:
	return {"buildings":constructed.duplicate(),"harvested":harvested_count}

func load_state(data: Dictionary) -> void:
	harvested_count=clampi(int(data.get("harvested",0)),0,2000000000)
	var entries: Variant=data.get("buildings",[])
	if not entries is Array:
		return
	for i in range(mini(LOCATIONS.size(),entries.size())):
		var kind: Variant=entries[i]
		if kind is String and TYPES.has(kind) and not has_building(kind):
			constructed[i]=kind
			_make_building(plot_nodes[i],kind,false)
	_refresh_plots()
