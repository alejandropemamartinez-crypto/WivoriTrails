extends Node3D
class_name WivoriTown

# An independent, playable village layer. Player agency is preserved:
# selecting a plot never moves the character or spends coins.
const Art=preload("res://scripts/art_library.gd")
const DISTRICT_LEVELS=[1,1,2,3,3,4,4,5,5]
const BUILDING_LEVELS={"house":1,"cafe":2,"depot":2,"bakery":3,"greenhouse":4,"workshop":3,"park":2,"watchtower":4,"mill":5}
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
var focus_kind:=""
var move_source: int=-1
var building_nodes: Dictionary={}
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
	move_source=-1
	if in_build_mode:
		camera_center=g.player.position
		var closest:=INF
		for i in range(LOCATIONS.size()):
			if not constructed[i].is_empty() or not is_plot_open(i):continue
			var distance: float=g.player.position.distance_squared_to(LOCATIONS[i])
			if distance<closest:closest=distance;selected=i;camera_center=LOCATIONS[i]
		g.boost_active=false
		g.input_stick._clear()
		g.has_tap_destination=false
		g.destination_marker.visible=false
	_refresh_plots()
	g._refresh_ui()

func _refresh_plots() -> void:
	for i in range(plot_nodes.size()):
		var active: bool=in_build_mode and constructed[i].is_empty()
		plot_signs[i].text="SOLAR %d" % (i+1) if is_plot_open(i) else "BARRIO · NIVEL %d" % DISTRICT_LEVELS[i]
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
	if move_source>=0 and choice!=move_source:
		return move_building(choice)
	selected=choice
	camera_center=camera_center.lerp(LOCATIONS[selected],.12)
	_refresh_plots()
	g._refresh_ui()
	return true

func selection_description() -> String:
	if move_source>=0:return "Tocá un solar vacío para trasladar el edificio."
	var result: String="Solar %d / %d" % [selected+1,LOCATIONS.size()]
	if not is_plot_open(selected):return result+" · Disponible en nivel %d" % DISTRICT_LEVELS[selected]
	if not constructed[selected].is_empty():
		return result+" · "+TYPES[constructed[selected]]["name"]+" construido"
	return result+" · vacío. Tocá un edificio para construirlo."

func build(kind: String) -> bool:
	if not in_build_mode or not TYPES.has(kind):
		return false
	if not constructed[selected].is_empty():
		return false
	if has_building(kind) or not can_build(kind):
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
	g.player.position=g.world.navigation.nearest_free(g.player.position)
	g._notice("¡NUEVA CONSTRUCCIÓN!\n%s" % TYPES[kind]["name"],2.5)
	_refresh_plots()
	g._save_progress()
	g._refresh_ui()
	return true

func _part(root: Node3D,kind: String,at: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
	return g.world.shape(root,kind,at,size,color)

func _make_building(plot: Node3D, kind: String, animated: bool) -> void:
	var building:=Art.place(plot,kind)
	building.name=TYPES[kind]["name"]
	building_nodes[plot_nodes.find(plot)]=building
	if kind=="mill":
		var rotor:=building.find_child("WindmillRotor",true,false)
		if rotor!=null:
			var spin:=create_tween().set_loops()
			spin.tween_property(rotor,"rotation:z",TAU,14.0).from(0.0)
	if animated:
		building.scale=Vector3(.98,.02,.98)
		var tween:=create_tween()
		tween.tween_interval(.65)
		tween.tween_property(building,"scale",Vector3(1.02,1.02,1.02),1.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(building,"scale",Vector3.ONE,.20)
		_construction_effect(plot)
		var builder: MarketActor=g.ActorScript.new()
		builder.setup("helper",Color("#d8ad64"),"rabbit")
		g.add_child(builder)
		builder.position=plot.global_position+Vector3(-2.6,0,2.4)
		builder.act("build")
		var work:=create_tween()
		work.tween_interval(1.1)
		work.tween_callback(func():
			if is_instance_valid(builder):builder.act("build"))
		work.tween_interval(1.3)
		work.tween_callback(builder.queue_free)
		g.player.act("build")

func is_plot_open(index: int) -> bool:
	return not constructed[index].is_empty() or g.run.level>=DISTRICT_LEVELS[index]

func can_build(kind: String) -> bool:
	return TYPES.has(kind) and g.run.level>=BUILDING_LEVELS[kind] and is_plot_open(selected)

func begin_move() -> bool:
	if not in_build_mode or constructed[selected].is_empty():return false
	move_source=selected
	g._refresh_ui()
	return true

func move_building(destination: int) -> bool:
	if move_source<0 or destination==move_source or not constructed[destination].is_empty() or not is_plot_open(destination):return false
	var source:=move_source
	var kind: String=constructed[source]
	var before:=Rect2(Vector2(LOCATIONS[source].x-2.2,LOCATIONS[source].z-1.9),Vector2(4.4,3.8))
	g.world.navigation.remove_obstacle(before)
	constructed[source]=""
	constructed[destination]=kind
	var building: Node3D=building_nodes[source]
	building.reparent(plot_nodes[destination])
	var tween:=create_tween()
	tween.tween_property(building,"position",Vector3.ZERO,.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	building_nodes.erase(source)
	building_nodes[destination]=building
	g.world.navigation.add_obstacle(Rect2(Vector2(LOCATIONS[destination].x-2.2,LOCATIONS[destination].z-1.9),Vector2(4.4,3.8)))
	g.player.position=g.world.navigation.nearest_free(g.player.position)
	selected=destination
	move_source=-1
	_refresh_plots()
	g._save_progress()
	g._refresh_ui()
	return true

func _construction_effect(plot: Node3D) -> void:
	# Temporary work-site timber and supplies disappear as the final model rises.
	var scaffold:=Node3D.new();plot.add_child(scaffold)
	for x in [-2.40,2.40]:
		for z in [-1.98,1.98]:g.world.shape(scaffold,"box",Vector3(x,1.55,z),Vector3(.13,3.1,.13),Color("#a67e53"))
	for z in [-1.98,1.98]:
		for y in [.72,1.62,2.56]:g.world.shape(scaffold,"box",Vector3(0,y,z),Vector3(4.9,.13,.14),Color("#c29a6b"))
	var clear:=create_tween();clear.tween_interval(2.25);clear.tween_callback(scaffold.queue_free)
	# Work-site dust scatters and fades.
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
			g.world.navigation.add_obstacle(Rect2(Vector2(LOCATIONS[i].x-2.2,LOCATIONS[i].z-1.9),Vector2(4.4,3.8)))
	_refresh_plots()
