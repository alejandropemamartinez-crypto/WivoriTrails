extends Node3D
class_name WivoriTown

# An independent, playable village layer. Player agency is preserved:
# selecting a plot never moves the character or spends coins.
const TYPES = {
	"house":{"name":"CASA DE VECINOS","price":180,"benefit":"Llegan compradores 25 % más rápido."},
	"cafe":{"name":"CAFÉ DEL PUEBLO","price":340,"benefit":"Las ventas generan 20 % más monedas."},
	"depot":{"name":"ALMACÉN COMUNAL","price":480,"benefit":"Aumenta la capacidad de la mochila en 6."}
}
const LOCATIONS=[Vector3(-18,0,-8),Vector3(-17,0,8),Vector3(14,0,21)]
var g: Node3D
var in_build_mode:=false
var selected:=0
var constructed: Array[String]=["","",""]
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
		g.world.shape(plot,"box",Vector3(0,.065,0),Vector3(5.6,.12,5.6),Color("#ddc69b"))
		var ring: MeshInstance3D=g.world.shape(plot,"cylinder",Vector3(0,.135,0),Vector3(4.7,.08,4.7),Color("#68b4a5"))
		plot_glows.append(ring)
		var label: Label3D=g.world.make_label(plot,"SOLAR %d" % (i+1),Vector3(0,1.1,0),42)
		label.pixel_size=.009
		label.modulate=Color("#315c58")
		plot_signs.append(label)
	_refresh_plots()

func has_building(kind: String) -> bool:
	return constructed.has(kind)

func income_bonus(income: int) -> int:
	return maxi(0,int(round(float(income)*.20))) if has_building("cafe") else 0

func customer_interval_factor() -> float:
	return .75 if has_building("house") else 1.0

func toggle_mode() -> void:
	in_build_mode=not in_build_mode
	if in_build_mode:
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
	var best:=3.5
	for i in range(LOCATIONS.size()):
		var distance:=point.distance_to(LOCATIONS[i])
		if distance<best:
			best=distance
			choice=i
	if choice<0:
		return false
	selected=choice
	_refresh_plots()
	g._refresh_ui()
	return true

func selection_description() -> String:
	var result: String="Solar %d de %d" % [selected+1,LOCATIONS.size()]
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
	if kind=="house":
		_part(building,"box",Vector3(0,1.55,0),Vector3(3.85,2.7,3.25),Color("#f5ddae"))
		for x in [-1.08,1.08]:
			var roof:=_part(building,"box",Vector3(x,3.00,0),Vector3(2.60,.30,3.78),Color("#b96552"))
			roof.rotation.z=(-.47 if x<0 else .47)
		_part(building,"box",Vector3(0,.96,1.67),Vector3(1.05,1.82,.16),Color("#688c83"))
		for x in [-1.20,1.20]:
			_part(building,"box",Vector3(x,1.95,1.68),Vector3(.63,.7,.10),Color("#95d6dc"))
	elif kind=="cafe":
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
	var sign: Label3D=g.world.make_label(building,TYPES[kind]["name"],Vector3(0,3.65,0),30)
	sign.pixel_size=.008
	sign.modulate=Color("#355952")
	if animated:
		building.scale=Vector3(.08,.02,.08)
		var tween:=create_tween()
		tween.tween_property(building,"scale",Vector3(1.08,1.08,1.08),.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(building,"scale",Vector3.ONE,.19)
		g.world.celebrate_upgrade("town")

func save_state() -> Dictionary:
	return {"buildings":constructed.duplicate()}

func load_state(data: Dictionary) -> void:
	var entries: Variant=data.get("buildings",[])
	if not entries is Array:
		return
	for i in range(mini(LOCATIONS.size(),entries.size())):
		var kind: Variant=entries[i]
		if kind is String and TYPES.has(kind) and not has_building(kind):
			constructed[i]=kind
			_make_building(plot_nodes[i],kind,false)
	_refresh_plots()
