extends Node3D
class_name WivoriVillageFacade

# Authored low-weight visual identity for the eleven existing village
# construction sites. Only visuals belong here: no new unlocks, costs,
# collision, money, inventory, save keys or auto-movement.
const Art=preload("res://scripts/art_library.gd")
const WOOD=Color("#a47850")
const CREAM=Color("#f4e1b9")
const GRAIN=Color("#d9b465")
const MILK=Color("#e3eadd")
const SKY=Color("#72b6bf")
const OCEAN=Color("#54879a")
const CORAL=Color("#c87568")
const LEAF=Color("#7b9e73")
const INK=Color("#435d5e")
var world: MarketWorld
var project_id: String=""
var moving: Array[Dictionary]=[]
var visual_pieces:=0
var seconds:=0.0

func configure(source: MarketWorld, identifier: String) -> void:
	world=source
	project_id=identifier

func _ready() -> void:
	if world==null:return
	name="Identidad de pueblo · "+project_id
	match project_id:
		"grain":_fields()
		"grainmill":_mill()
		"breadshop":_bread()
		"henhouse":_hens()
		"cowbarn":_cows()
		"dairy":_cheese()
		"pigpen":_piglets()
		"butcher":_cold_store()
		"harbor_depot":_harbor()
		"cannery":_provisions()
		"route_watch":_signal_tower()
		"beacon":_beacon()
	set_process(not moving.is_empty())

func _p(kind: String, at: Vector3, dimensions: Vector3, color_: Color, title: String) -> MeshInstance3D:
	var node:=world.shape(self,kind,at,dimensions,color_,title)
	visual_pieces+=1
	if dimensions.length_squared()<1.1:node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func _model(kind: String, at: Vector3, size_: float=.7) -> Node3D:
	var prop:=Art.place(self,kind,at,Vector3.ONE*size_)
	visual_pieces+=1
	return prop

func _pivot(title: String, at: Vector3) -> Node3D:
	var pivot:=Node3D.new()
	pivot.name=title
	pivot.position=at
	add_child(pivot)
	return pivot

func _canopy(primary: Color, alternate: Color) -> void:
	# Frontal textile awning, not another floating text label.
	for i in range(6):
		var x:float=-1.59+float(i)*.63
		var strip:=_p("box",Vector3(x,2.68,1.91),Vector3(.63,.075,1.02),primary if i%2==0 else alternate,"Toldo textil de franjas")
		strip.rotation.x=-.17
	for x in [-1.94,1.94]:
		_p("cylinder",Vector3(x,1.54,2.32),Vector3(.10,2.76,.10),WOOD,"Pilar tallado del toldo")

func _display_cart(goods: String, at: Vector3, count: int) -> void:
	_p("box",at+Vector3(0,.39,0),Vector3(1.75,.20,.70),WOOD,"Mesa de producto")
	for i in range(count):
		var x:float=(float(i)-float(count-1)*.5)*.37
		_model("goods_"+goods,at+Vector3(x,.75,0),.39)

func _flag(color_: Color, at: Vector3, phase: float) -> void:
	_p("cylinder",at+Vector3(0,-.62,0),Vector3(.09,1.48,.09),WOOD,"Mástil corto")
	var cloth:=_pivot("Banderín móvil",at)
	_p_in(cloth,"box",Vector3(.39,-.04,0),Vector3(.78,.42,.045),color_,"Bandera tejida")
	moving.append({"node":cloth,"base":cloth.position,"type":"flag","phase":phase})

func _p_in(parent: Node3D, kind: String, at: Vector3, dimensions: Vector3, color_: Color, title: String) -> MeshInstance3D:
	var item:=world.shape(parent,kind,at,dimensions,color_,title)
	visual_pieces+=1
	if dimensions.length_squared()<1.1:item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return item

func _fields() -> void:
	# Garden plots already exist: only a reed-lined scarecrow and wheat
	# baskets appear once the first crop project is truly purchased.
	_p("cylinder",Vector3(-1.6,1.65,1.05),Vector3(.17,3.20,.17),WOOD,"Poste del espantapájaros")
	_p("box",Vector3(-1.6,2.60,1.05),Vector3(1.34,.15,.16),WOOD,"Brazos del espantapájaros")
	_p("cone",Vector3(-1.6,3.18,1.05),Vector3(.70,.45,.70),GRAIN,"Sombrero de paja")
	_p("sphere",Vector3(-1.6,2.82,1.05),Vector3(.40,.46,.38),CREAM,"Cabeza del espantapájaros")
	for x in [.65,1.55]:
		_p("cylinder",Vector3(x,.51,1.4),Vector3(.84,.54,.84),WOOD,"Cesta de trigo")
		_model("goods_wheat",Vector3(x,.91,1.4),.67)
	_flag(LEAF,Vector3(1.85,2.1,.60),.2)

func _mill() -> void:
	# Visually distinct ground-level milling process. Does not interfere
	# with the existing imported windmill rotor.
	_p("cylinder",Vector3(1.20,.59,1.72),Vector3(1.15,.45,1.15),Color("#b6a18c"),"Piedra de molienda")
	_p("cylinder",Vector3(1.20,.94,1.72),Vector3(.89,.18,.89),CREAM,"Disco de harina")
	_model("goods_flour",Vector3(.36,.73,1.82),.48)
	_model("goods_feed",Vector3(1.95,.73,1.82),.48)
	for x in [-1.8,-1.25,-.70]:
		_p("cylinder",Vector3(x,.56,1.7),Vector3(.23,.78,.23),GRAIN,"Saco de grano")
	_flag(GRAIN,Vector3(-1.8,2.75,.8),.4)

func _bread() -> void:
	_canopy(CORAL,CREAM)
	_display_cart("bread",Vector3(0,0,2.02),4)
	_p("cylinder",Vector3(1.90,.72,1.05),Vector3(.46,.92,.46),WOOD,"Horno auxiliar")
	_p("sphere",Vector3(1.90,1.30,1.05),Vector3(.38,.26,.38),Color("#edca83"),"Cúpula de horno")
	_flag(CORAL,Vector3(-2.02,3.5,.8),.0)

func _hens() -> void:
	# Natural coop frontage, eggs in actual nest bowls. No invented
	# livestock: purchased henhouse already spawns animated farm_hens.
	for x in [-1.54,1.54]:
		_p("cylinder",Vector3(x,.57,1.84),Vector3(.87,.27,.87),WOOD,"Nido de ponedoras")
		for i in range(2):
			_model("goods_egg",Vector3(x+(float(i)-.5)*.28,.76,1.82),.43)
	_p("box",Vector3(0,1.57,1.72),Vector3(2.35,.12,.22),CREAM,"Percha de gallinero")
	_flag(LEAF,Vector3(-2.1,2.92,.9),.5)

func _cows() -> void:
	# Milk jars and barn bell identify dairy production immediately.
	_canopy(LEAF,CREAM)
	for x in [-1.36,0,1.36]:
		_p("cylinder",Vector3(x,.45,1.65),Vector3(.60,.73,.60),MILK,"Lechera metálica")
		_p("cylinder",Vector3(x,.87,1.65),Vector3(.44,.12,.44),INK,"Tapa de lechera")
	_p("cone",Vector3(0,3.35,1.72),Vector3(.60,.66,.60),GRAIN,"Campana del establo")
	_p("sphere",Vector3(0,2.97,1.72),Vector3(.18,.18,.18),WOOD,"Badajo")

func _cheese() -> void:
	_canopy(SKY,CREAM)
	_display_cart("cheese",Vector3(0,0,1.97),3)
	for x in [-1.74,1.74]:
		_p("cylinder",Vector3(x,1.03,.90),Vector3(.32,1.12,.32),Color("#d5e5d6"),"Botella de leche")
	_p("cylinder",Vector3(0,2.12,1.15),Vector3(.40,.14,.40),GRAIN,"Medallón de quesería")
	_flag(SKY,Vector3(2.0,3.2,.7),1.2)

func _piglets() -> void:
	# A feeding trough, rounded poles and non-violent farm identity.
	_p("box",Vector3(0,.48,1.78),Vector3(2.88,.50,.68),WOOD,"Comedero largo")
	_p("box",Vector3(0,.74,1.78),Vector3(2.45,.10,.48),Color("#b7c08c"),"Alimento del corral")
	for x in [-1.92,1.92]:
		_p("cylinder",Vector3(x,.78,1.69),Vector3(.22,1.56,.22),CORAL,"Poste de corral")
		_p("sphere",Vector3(x,1.59,1.69),Vector3(.27,.27,.27),CREAM,"Remate redondo")
	_flag(CORAL,Vector3(1.97,2.68,.8),.9)

func _cold_store() -> void:
	# A bright grocer's display: wrapped goods only, no sharp utensils
	# or violent visuals.
	_canopy(CORAL,Color("#f5eee3"))
	_display_cart("meat",Vector3(0,0,1.92),3)
	_p("box",Vector3(-1.75,.97,.87),Vector3(.42,1.05,.50),Color("#9ac4c5"),"Gabinete refrigerado")
	_p("box",Vector3(-1.75,1.55,.87),Vector3(.46,.12,.56),CREAM,"Techo de refrigerador")

func _harbor() -> void:
	# Original bay depot becomes maritime via signal lights and a
	# decorative pallet. Real cargo stock is represented elsewhere.
	_canopy(OCEAN,CREAM)
	for x in [-1.60,1.60]:
		_p("cylinder",Vector3(x,.85,1.82),Vector3(.22,1.70,.22),WOOD,"Bolardo de almacén")
		_p("cylinder",Vector3(x,1.72,1.82),Vector3(.44,.18,.44),GRAIN,"Tope de bolardo")
	_p("box",Vector3(0,.25,1.74),Vector3(1.90,.18,.76),WOOD,"Tarima de entrega")
	_flag(SKY,Vector3(-2.0,3.7,.9),.2)

func _provisions() -> void:
	_canopy(GRAIN,CREAM)
	_display_cart("provisions",Vector3(0,0,1.87),3)
	for x in [-1.48,1.48]:
		_p("cylinder",Vector3(x,1.08,1.10),Vector3(.68,1.10,.68),INK,"Olla de provisiones")
		_p("cylinder",Vector3(x,1.72,1.10),Vector3(.75,.16,.75),GRAIN,"Tapadera sellada")
		_p("sphere",Vector3(x,2.08,1.10),Vector3(.35,.34,.35),Color("#cfdfdc"),"Vapor ligero")

func _signal_tower() -> void:
	# A navigational semaphore distinguishes the bay watchtower
	# from the home-market security watchtower.
	_p("cylinder",Vector3(0,3.30,1.26),Vector3(.19,2.35,.19),INK,"Mástil de semáforo")
	for i in range(3):
		_flag([SKY,CORAL,CREAM][i],Vector3(-1.30+float(i)*1.30,4.48,1.35),float(i)*.8)
	_p("cylinder",Vector3(-1.88,1.65,1.74),Vector3(.16,3.30,.16),WOOD,"Poste de aviso portuario")
	_p("sphere",Vector3(-1.88,3.34,1.74),Vector3(.28,.30,.28),GRAIN,"Luz de vigía")

func _beacon() -> void:
	# Keep the original powerful rotating lighthouse beam; add only
	# the visible painted parapet and maritime details at its base.
	for i in range(8):
		var a:float=TAU*float(i)/8.0
		_p("cylinder",Vector3(1.52*cos(a),.30,1.52*sin(a)),Vector3(.26,.60,.26),CREAM,"Barrera pétrea del faro")
	for i in range(2):
		_p("sphere",Vector3(-1.0+float(i)*2.0,1.55,1.73),Vector3(.39,.46,.39),GRAIN,"Baliza costera")
	_flag(SKY,Vector3(-2.0,3.60,1.20),.3)

func _process(delta: float) -> void:
	seconds+=delta
	for info in moving:
		var node: Node3D=info["node"]
		if not is_instance_valid(node):continue
		node.rotation.z=.065*sin(seconds*1.33+float(info["phase"]))
