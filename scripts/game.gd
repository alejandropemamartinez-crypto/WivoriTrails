extends Node3D

const ActorScript = preload("res://scripts/actor.gd")
const WorldScript = preload("res://scripts/world.gd")
const JoystickScript = preload("res://scripts/joystick.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const SAVE_PATH = "user://wivori_trails_save.json"
const MAX_HELPERS := 12
const SHIPMENT_SIZE := 6
const SHIPMENT_RESERVE := 3
const SHIPMENT_DURATION := 30.0
const SELL_VALUE = {"tomato":6,"carrot":7,"berry":9,"apple":14}
const CROP_NAMES = {"tomato":"tomates","carrot":"zanahorias","berry":"arándanos","apple":"manzanas"}

var world: MarketWorld
var player: MarketActor
var cashier: MarketActor
var camera: Camera3D
var camera_follow := Vector3.ZERO
var camera_distance := 1.0
var camera_yaw := 0.0
var camera_lead := Vector3.ZERO
var tap_destination := Vector3.ZERO
var has_tap_destination := false
var last_player_heading := Vector3(0,0,-1)
var destination_marker: MeshInstance3D
var input_stick: MarketJoystick
var coins := 50
var earned := 0
var sold := 0
var delivered := 0
var worker_count := 0
var player_speed := 4.5
var boost_active := false
var max_capacity := 12
var harvest_wait := 0.0
var drop_wait := 0.0
var cash_sfx: AudioStreamPlayer
var harvest_sfx: AudioStreamPlayer
var stash := {"tomato":0,"carrot":0,"berry":0,"apple":0}
var counter := {"tomato":0,"carrot":0,"berry":0,"apple":0}
var helpers: Array[Dictionary] = []
var customers: Array[Dictionary] = []
var customers_timer := 2.0
var anim_timer := 0.0
var save_timer := 8.0
var display_timer := 0.0
var camera_shake := 0.0
var event_label: Label
var event_fade := 0.0
var total_label: Label
var backpack_label: Label
var mission_label: Label
var stock_label: Label
var shipping_label: Label
var hint_label: Label
var shop_panel: PanelContainer
var shop_button: Button
var store_buttons := {}
var quest_level := 1
var total_buyers := 0
var helper_cost := 80
var speed_cost := 95
var bag_cost := 70
var expand_cost := 300
var orchard_owned := false
var pier_owned := false
var shipment := {"kind":"", "amount":0, "remaining":0.0}
var shipments_completed := 0
var saved_helpers: Array = []
var save_path := SAVE_PATH
var save_error_shown := false

func _ready() -> void:
	_engine_world()
	world = WorldScript.new()
	world.name = "Wivori Trails"
	add_child(world)
	player = ActorScript.new()
	player.name = "Personaje controlable"
	player.setup("player",Color("#398a9b"))
	add_child(player)
	player.position = Vector3(0,0,4)
	cashier=ActorScript.new()
	cashier.setup("vendor",Color("#b66242"),"dog")
	cashier.name="Vendedor del mercado"
	add_child(cashier)
	cashier.position=Vector3(4,0,-3.1)
	camera_follow = player.position
	_setup_camera()
	_setup_destination_marker()
	_setup_sounds()
	_load_progress()
	_setup_hud()
	for i in range(worker_count):
		_spawn_worker(i, saved_helpers[i] if i < saved_helpers.size() and saved_helpers[i] is Dictionary else {})
	_refresh_ui()

func _engine_world() -> void:
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("#b4dcf0")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("#f5e5bf")
	sky.ambient_light_energy = .86
	sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = sky
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-37,0)
	sun.light_color = Color("#fff2cf")
	sun.light_energy = 1.22
	sun.shadow_enabled = true
	add_child(sun)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Cámara suave que sigue al jugador"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 49.0
	camera.near = .1
	camera.far = 110.0
	camera.current = true
	add_child(camera)
	_update_camera(1.0)

func _setup_destination_marker() -> void:
	# Visible cursor when tapping the 3D terrain to navigate. Hidden for joystick movement.
	destination_marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = .47
	ring.outer_radius = .64
	destination_marker.mesh = ring
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#ffe987")
	mat.emission_enabled = true
	mat.emission = Color("#dd9939")
	mat.emission_energy_multiplier = .8
	destination_marker.material_override = mat
	destination_marker.position = Vector3(0,.15,0)
	destination_marker.visible = false
	add_child(destination_marker)

func _setup_sounds() -> void:
	cash_sfx=AudioStreamPlayer.new(); harvest_sfx=AudioStreamPlayer.new()
	add_child(cash_sfx); add_child(harvest_sfx)
	cash_sfx.stream=load("res://assets/coin.wav")
	harvest_sfx.stream=load("res://assets/harvest.wav")
	cash_sfx.volume_db = -9
	harvest_sfx.volume_db = -15

func _soft_button(name_: String, color_: Color, font_size_: int=25) -> Button:
	var b := Button.new()
	b.text=name_
	b.add_theme_font_size_override("font_size",font_size_)
	b.add_theme_color_override("font_color",Color.WHITE)
	b.add_theme_color_override("font_hover_color",Color.WHITE)
	b.add_theme_color_override("font_pressed_color",Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = color_
	style.corner_radius_top_left=22; style.corner_radius_top_right=22
	style.corner_radius_bottom_left=22; style.corner_radius_bottom_right=22
	style.content_margin_left=16; style.content_margin_right=16
	style.content_margin_top=15; style.content_margin_bottom=15
	style.border_color=color_.lightened(.22)
	style.set_border_width_all(2)
	b.add_theme_stylebox_override("normal",style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color=color_.lightened(.13)
	b.add_theme_stylebox_override("hover",hover)
	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color=color_.darkened(.18)
	b.add_theme_stylebox_override("pressed",pressed_style)
	return b

func _panel(color_: Color, radius_: int=22) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color=color_
	style.corner_radius_top_left=radius_; style.corner_radius_top_right=radius_
	style.corner_radius_bottom_left=radius_; style.corner_radius_bottom_right=radius_
	style.content_margin_left=16; style.content_margin_right=16
	style.content_margin_top=12; style.content_margin_bottom=12
	p.add_theme_stylebox_override("panel",style)
	return p

func _plain(text_: String, size_: int=25, color_: Color=Color.WHITE) -> Label:
	var l := Label.new()
	l.text=text_
	l.add_theme_font_size_override("font_size",size_)
	l.add_theme_color_override("font_color",color_)
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return l

func _setup_hud() -> void:
	var layer := CanvasLayer.new(); layer.name="Interfaz y controles tactiles"; add_child(layer)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(root)
	var top := _panel(Color(.10,.18,.20,.91),26)
	top.position=Vector2(14,14); top.size=Vector2(692,98); root.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation",14)
	top.add_child(top_row)
	total_label=_plain("MONEDAS 50",27,Color("#ffdf8a"));total_label.custom_minimum_size=Vector2(190,49)
	top_row.add_child(total_label)
	backpack_label=_plain("BOLSA 0/12",23,Color("#e8f5e6"));backpack_label.custom_minimum_size=Vector2(190,49)
	top_row.add_child(backpack_label)
	shop_button=_soft_button("MEJORAS",Color("#288b75"),22)
	shop_button.custom_minimum_size=Vector2(200,60)
	shop_button.pressed.connect(_toggle_shop)
	top_row.add_child(shop_button)
	var mission := _panel(Color(.12,.29,.27,.82),18)
	mission.position=Vector2(18,132); mission.size=Vector2(390,88); mission.mouse_filter=Control.MOUSE_FILTER_IGNORE; root.add_child(mission)
	mission_label=_plain("MISIÓN: Vende 20 productos",20,Color("#fff6d3"))
	mission_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	mission_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission.add_child(mission_label)
	var stock_p := _panel(Color(.09,.22,.25,.78),20)
	stock_p.position=Vector2(18,227);stock_p.size=Vector2(330,66);stock_p.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(stock_p)
	stock_label=_plain("PUESTO: 0 productos",20)
	stock_p.add_child(stock_label)
	stock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shipping_panel := _panel(Color(.09,.22,.25,.88),18)
	shipping_panel.position=Vector2(18,305); shipping_panel.size=Vector2(390,76)
	shipping_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; root.add_child(shipping_panel)
	shipping_label=_plain("",18,Color("#ffe59b")); shipping_panel.add_child(shipping_label)
	shipping_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shipping_panel.visible=false
	# Overworld notice near centre, only visible on meaningful actions.
	event_label=_plain("",32,Color("#ffed9d"))
	event_label.position=Vector2(65,340);event_label.size=Vector2(590,110)
	event_label.visible=false
	event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_label.add_theme_color_override("font_shadow_color",Color(.03,.10,.10,.80))
	event_label.add_theme_constant_override("shadow_offset_x",2)
	event_label.add_theme_constant_override("shadow_offset_y",3)
	root.add_child(event_label)
	input_stick=JoystickScript.new()
	input_stick.anchor_top=1.0; input_stick.anchor_bottom=1.0
	input_stick.offset_left=17; input_stick.offset_right=222
	input_stick.offset_top=-250; input_stick.offset_bottom=-35
	root.add_child(input_stick)
	var side := VBoxContainer.new()
	side.anchor_left=1.0; side.anchor_right=1.0
	side.anchor_top=1.0; side.anchor_bottom=1.0
	side.offset_left=-230;side.offset_right=-14;side.offset_top=-250;side.offset_bottom=-58
	side.add_theme_constant_override("separation",13);root.add_child(side)
	var dash := _soft_button("CORRER",Color("#dd9b41"),25)
	dash.custom_minimum_size=Vector2(204,73)
	dash.button_down.connect(func(): boost_active=true)
	dash.button_up.connect(func(): boost_active=false)
	side.add_child(dash)
	var improve := _soft_button("TIENDA",Color("#278e77"),25)
	improve.custom_minimum_size=Vector2(204,72)
	improve.pressed.connect(_toggle_shop)
	side.add_child(improve)
	hint_label=_plain("Mueve el joystick o toca el camino.",19,Color("#ffefc4"))
	hint_label.anchor_left=.18; hint_label.anchor_right=.92
	hint_label.anchor_top=1.0; hint_label.anchor_bottom=1.0
	hint_label.offset_left=0;hint_label.offset_right=0
	hint_label.offset_top=-44;hint_label.offset_bottom=-7
	root.add_child(hint_label)
	# Purchases remain out of sight unless requested. No giant overlay during play.
	shop_panel = _panel(Color(.06,.17,.18,.97),26)
	shop_panel.anchor_left=.5;shop_panel.anchor_right=.5
	shop_panel.anchor_top=.5;shop_panel.anchor_bottom=.5
	shop_panel.offset_left=-287;shop_panel.offset_right=287
	shop_panel.offset_top=-300;shop_panel.offset_bottom=300
	shop_panel.visible=false;root.add_child(shop_panel)
	var column := VBoxContainer.new();column.add_theme_constant_override("separation",14)
	shop_panel.add_child(column)
	column.add_child(_plain("MEJORA TU MERCADO",30,Color("#ffe59b")))
	column.add_child(_plain("Contrata, automatiza y crece",19,Color("#d5e6dc")))
	for key in ["helper","speed","bag","expand","pier"]:
		var b := _soft_button("",Color("#318b68"),24)
		b.custom_minimum_size=Vector2(520,74)
		b.pressed.connect(_buy.bind(key))
		column.add_child(b)
		store_buttons[key] = b
	var close := _soft_button("VOLVER AL JUEGO",Color("#995e46"),21)
	close.pressed.connect(_toggle_shop)
	column.add_child(close)

func _toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		has_tap_destination = false
		destination_marker.visible = false
		boost_active = false
		input_stick._clear()
	_refresh_ui()

func _total_bag() -> int:
	var sum := 0
	for v in stash.values(): sum += int(v)
	return sum

func _total_stock() -> int:
	var sum := 0
	for v in counter.values(): sum += int(v)
	return sum

func _refresh_ui() -> void:
	if total_label == null: return
	total_label.text="MONEDAS  %d" % coins
	backpack_label.text="BOLSA  %d/%d" % [_total_bag(),max_capacity]
	stock_label.text="PUESTO: %d productos" % _total_stock()
	if world != null: world.update_market_stock(counter)
	shipping_label.get_parent().visible=pier_owned
	if pier_owned:
		if shipment["kind"] == "":
			shipping_label.text="MUELLE AUTO · venta +50%\nJuntá 9 iguales: salen 6 y quedan 3"
		else:
			shipping_label.text="BARCO: %d %s · %ds\nGanancia al llegar: %d monedas" % [shipment["amount"], CROP_NAMES[shipment["kind"]], ceili(shipment["remaining"]), _shipment_income()]
	var goal := quest_level*20
	mission_label.text="MISIÓN   Vende %d productos\nProgreso: %d/%d" % [goal,mini(sold,goal),goal]
	var texts := {
		"helper":"AYUDANTE AUTO    %d monedas"%helper_cost,
		"speed":"CAMINAR MÁS RÁPIDO    %d monedas"%speed_cost,
		"bag":"MOCHILA MÁS GRANDE    %d monedas"%bag_cost,
		"expand":"ABRIR HUERTO    %d monedas"%expand_cost,
		"pier":"MUELLE AUTO (+50%)    550 monedas"
	}
	if orchard_owned: texts["expand"]="HUERTO DESBLOQUEADO"
	if pier_owned: texts["pier"]="MUELLE DESBLOQUEADO"
	if worker_count >= MAX_HELPERS: texts["helper"]="EQUIPO COMPLETO · 12 AYUDANTES"
	for key in texts.keys():
		if store_buttons.has(key):
			store_buttons[key].text=texts[key]
	store_buttons["expand"].disabled=orchard_owned
	store_buttons["pier"].disabled=pier_owned
	store_buttons["helper"].disabled=worker_count>=MAX_HELPERS or coins<helper_cost
	store_buttons["speed"].disabled=player_speed>=12.0 or coins<speed_cost
	store_buttons["bag"].disabled=max_capacity>=300 or coins<bag_cost

func _notice(message: String, time_: float = 1.45) -> void:
	if event_label == null: return
	event_label.text=message
	event_label.visible=true
	event_label.modulate.a=1.0
	event_fade=time_

func _buy(kind: String) -> void:
	var price := 0
	match kind:
		"helper": price=helper_cost
		"speed": price=speed_cost
		"bag": price=bag_cost
		"expand": price=expand_cost
		"pier": price=550
		_: return
	if (kind == "expand" and orchard_owned) or (kind == "pier" and pier_owned):return
	if kind == "helper" and worker_count >= MAX_HELPERS: return
	if kind == "speed" and player_speed >= 12.0: return
	if kind == "bag" and max_capacity >= 300: return
	if coins < price:
		_notice("NECESITÁS %d MONEDAS" % price,1.5)
		return
	coins-=price
	match kind:
		"helper":
			worker_count+=1
			_spawn_worker(worker_count-1)
			helper_cost=int(ceil(float(helper_cost)*1.70))
			_notice("¡NUEVO AYUDANTE TRABAJANDO!",1.9)
		"speed":
			player_speed=minf(12.0,player_speed+.46)
			speed_cost+=55
			_notice("¡MÁS VELOCIDAD!",1.7)
		"bag":
			max_capacity=mini(300,max_capacity+6)
			bag_cost+=65
			_notice("¡MOCHILA AMPLIADA!",1.7)
		"expand":
			orchard_owned=true
			world.open_orchard()
			_notice("¡EL HUERTO ESTÁ ABIERTO!",2.2)
		"pier":
			pier_owned=true
			world.open_pier()
			_notice("¡MUELLE AUTO! EXPORTÁ CON +50%",2.5)
	_save_progress()
	_refresh_ui()

func _spawn_worker(index: int, saved: Dictionary = {}) -> void:
	var actor: MarketActor=ActorScript.new()
	actor.setup("helper",[Color("#db9d4c"),Color("#aa7bc5"),Color("#70a368")][index%3])
	add_child(actor)
	actor.position=world.navigation.nearest_free(SaveStore.position(saved.get("position"), Vector3(2.0-float(index)*.6,0,4.0)))
	var helper := {"actor":actor,"state":"search","crop":{},"cargo":"", "cargo_amount":0,"timer":0.0}
	var cargo: Variant=saved.get("cargo", "")
	if cargo is String and SELL_VALUE.has(cargo):
		helper["cargo"]=cargo
		helper["cargo_amount"]=int(SaveStore.number(saved,"cargo_amount",3,1,3))
		helper["state"]="to_store"
		actor.set_carry(helper["cargo_amount"])
	else:
		var crop_index := int(SaveStore.number(saved,"crop_index",-1,-1,world.crop_spots.size()-1))
		if crop_index >= 0 and saved.get("state", "") in ["to_crop", "collect"]:
			helper["crop"]=world.crop_spots[crop_index]
			helper["state"]=saved["state"]
			helper["timer"]=SaveStore.number(saved,"timer",.45,0,.45)
	helpers.append(helper)

func _spawn_customer() -> void:
	if customers.size() >= 6: return
	var a: MarketActor=ActorScript.new()
	var species_: String = ["cat","pig","rabbit","fox"][randi()%4]
	a.setup("customer",{"cat":Color("#498f83"),"pig":Color("#b872ad"),"rabbit":Color("#8c94bf"),"fox":Color("#e2aa56")}[species_],species_)
	add_child(a)
	var used_lanes: Array = []
	for customer in customers: used_lanes.append(customer["lane"])
	var lane := 0.0
	while lane in used_lanes: lane += .75
	a.position=Vector3(17,0,-6.5+lane)
	customers.append({"actor":a,"stage":"coming","wait":0.0,"lane":lane})

func _move_actor(actor: MarketActor, destination: Vector3, step: float, delta: float) -> bool:
	if not actor.has_meta("route_goal") or actor.get_meta("route_goal").distance_to(destination) > .05 or actor.get_meta("route_revision", -1) != world.navigation.revision:
		actor.set_meta("route_goal", destination)
		actor.set_meta("route", world.navigation.find_path(actor.position,destination))
		actor.set_meta("route_index",0)
		actor.set_meta("route_revision",world.navigation.revision)
	var route: PackedVector3Array=actor.get_meta("route")
	var index: int=actor.get_meta("route_index")
	if route.is_empty():
		actor.walk_amount=0.0
		return false
	var budget := step*delta
	var previous := actor.position
	while index < route.size():
		var difference := route[index]-actor.position
		if difference.length() < .02:
			index+=1
			continue
		if budget <= 0: break
		var distance := minf(budget,difference.length())
		actor.position=world.navigation.slide(actor.position,difference.normalized()*distance)
		budget-=distance
		if actor.position.distance_to(previous)<.0001: break
	actor.set_meta("route_index",index)
	var movement := actor.position-previous
	if movement.length()>.0001: actor.walk_to(movement.normalized(),step)
	else: actor.walk_amount=0.0
	return index>=route.size()

func _process_helpers(delta: float) -> void:
	for h in helpers:
		var a: MarketActor=h["actor"]
		match h["state"]:
			"search":
				var target: Dictionary=world.pick_any()
				if not target.is_empty():
					h["crop"]=target
					h["state"]="to_crop"
			"to_crop":
				var target: Dictionary=h["crop"]
				if target.is_empty() or not target["ready"]:
					h["state"]="search"
				elif _move_actor(a,target["node"].global_position,2.8,delta):
					h["state"]="collect"
					h["timer"]=.45
			"collect":
				h["timer"]=float(h["timer"])-delta
				if h["timer"]<=0:
					h["cargo"]=world.harvest(h["crop"])
					if h["cargo"]!="":
						h["cargo_amount"]=3
						a.set_carry(3)
						h["state"]="to_store"
					else:
						h["state"]="search"
			"to_store":
				if _move_actor(a,Vector3(4,0,3.3),2.8,delta):
					var kind: String=h["cargo"]
					if kind!="":
						counter[kind]+=int(h["cargo_amount"])
						delivered+=int(h["cargo_amount"])
					h["cargo"]=""
					h["cargo_amount"]=0
					a.set_carry(0)
					h["state"]="search"

func _process_customers(delta: float) -> void:
	for c in customers.duplicate():
		var a: MarketActor=c["actor"]
		var lane: float=c["lane"]
		match c["stage"]:
			"coming":
				if _move_actor(a,Vector3(4.0+lane,0,1.45+lane*.24),2.0,delta):
					c["stage"]="buying";c["wait"]=1.0
			"buying":
				c["wait"]-=delta
				if c["wait"]<=0:
					var kind := _first_stocked()
					if kind != "":
						var count := mini(3,int(counter[kind]))
						counter[kind]-=count
						var income: int=int(SELL_VALUE[kind])*count
						_record_sale(count,income)
						total_buyers+=1
						_cash_sound()
						cashier.walk_amount=.55
						_notice("+%d MONEDAS" % income,.85)
						c["stage"]="leaving"
			"leaving":
				if _move_actor(a,Vector3(17,0,-9+lane),2.35,delta):
					customers.erase(c)
					a.queue_free()

func _first_stocked() -> String:
	var choices := ["tomato","carrot","berry","apple"]
	choices.shuffle()
	for kind in choices:
		if counter[kind] > 0:return kind
	return ""

func _record_sale(amount: int, income: int) -> void:
	coins+=income
	earned+=income
	sold+=amount
	while sold >= quest_level*20:
		quest_level+=1
		coins+=70
		_notice("¡MISIÓN SUPERADA!  +70",2.1)

func _shipment_income() -> int:
	return int(SELL_VALUE.get(shipment["kind"],0))*int(shipment["amount"])*3/2

func _process_shipping(delta: float) -> void:
	if not pier_owned: return
	if shipment["kind"] != "":
		shipment["remaining"]=maxf(0,float(shipment["remaining"])-delta)
		if shipment["remaining"]<=0:
			var income := _shipment_income()
			_record_sale(int(shipment["amount"]),income)
			shipments_completed+=1
			shipment={"kind":"","amount":0,"remaining":0.0}
			_cash_sound()
			_notice("¡EXPORTACIÓN ENTREGADA! +%d" % income,2.2)
			_save_progress()
	else:
		# Keep three products of each kind available for local shoppers.
		# Prioritize the largest surplus, so exports relieve a real bottleneck.
		var chosen := ""
		var largest := SHIPMENT_SIZE+SHIPMENT_RESERVE-1
		for kind in counter:
			if int(counter[kind])>largest:
				chosen=kind
				largest=int(counter[kind])
		if chosen!="":
			counter[chosen]-=SHIPMENT_SIZE
			shipment={"kind":chosen,"amount":SHIPMENT_SIZE,"remaining":SHIPMENT_DURATION}
			_notice("¡BARCO CARGADO! VENTA +50%",1.8)
			_save_progress()
	world.update_pier_shipment(shipment["kind"],shipment["amount"],shipment["remaining"],SHIPMENT_DURATION)

func _process_player(delta: float) -> void:
	var pad := input_stick.axis
	var keyboard := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): keyboard.x-=1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): keyboard.x+=1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): keyboard.y-=1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): keyboard.y+=1
	var joy := (pad+keyboard).limit_length(1.0)
	if joy.length() > .12:
		has_tap_destination = false
		destination_marker.visible = false
	var world_motion := Vector3.ZERO
	if has_tap_destination and joy.length() <= .12 and not shop_panel.visible:
		var previous := player.position
		if _move_actor(player,tap_destination,player_speed*(1.50 if boost_active else 1.0),delta):
			has_tap_destination = false
			destination_marker.visible = false
		if player.position.distance_to(previous)>.001:
			last_player_heading=(player.position-previous).normalized()
	else:
		# Joystick movement remains screen-relative even if the camera was rotated.
		world_motion = Vector3(joy.x,0,joy.y).rotated(Vector3.UP,camera_yaw)
	if shop_panel.visible: world_motion = Vector3.ZERO
	var velocity := world_motion * player_speed * (1.50 if boost_active else 1.0)
	if velocity.length()>.05:
		player.position=world.navigation.slide(player.position,velocity*delta)
		if player.has_meta("route_goal"): player.remove_meta("route_goal")
		last_player_heading = velocity.normalized()
		player.walk_to(velocity.normalized(),velocity.length())
	harvest_wait-=delta
	drop_wait-=delta
	if harvest_wait<=0 and _total_bag()<max_capacity:
		var crop := world.pick_closest(player.position)
		if not crop.is_empty():
			var resource := world.harvest(crop)
			if resource!="":
				stash[resource]+=1
				player.set_carry(_total_bag())
				harvest_wait=.39
				if harvest_sfx.stream:harvest_sfx.play()
				_spawn_pickup_fx(crop["node"].global_position,resource)
				_notice("+1 %s" % CROP_NAMES[resource],.45)
	if drop_wait<=0 and _total_bag()>0 and player.position.distance_to(Vector3(4,0,2.5))<2.5:
		for resource in stash.keys():
			delivered+=stash[resource]
			counter[resource]+=stash[resource]
			stash[resource]=0
		player.set_carry(0)
		_notice("¡PUESTO ABASTECIDO!",1.1)
		drop_wait=.6
	if _total_bag()>=max_capacity:
		hint_label.text="Bolsa llena: acercate al puesto dorado."
	elif player.position.distance_to(Vector3(4,0,2.5))<4:
		hint_label.text="ENTREGA: pasa sobre el círculo amarillo."
	elif _total_stock()<3:
		hint_label.text="Acercate a los cultivos y recogerás automáticamente."
	else:
		hint_label.text="¡Seguí cosechando! Los clientes están comprando."

func _spawn_pickup_fx(at: Vector3, kind: String) -> void:
	# Rising pickup is world-space, rather than a change in an inventory counter only.
	var item := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 6
	item.mesh = mesh
	item.scale = Vector3.ONE*.28
	var mat := StandardMaterial3D.new()
	mat.albedo_color = {"tomato":Color("#e65a46"),"carrot":Color("#f3ad39"),"berry":Color("#7356be"),"apple":Color("#e14c40")}.get(kind,Color.WHITE)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = .4
	item.material_override = mat
	item.position = at+Vector3(0,.55,0)
	add_child(item)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(item,"position",player.position+Vector3(0,2.15,0),.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(item,"scale",Vector3.ONE*.08,.45)
	tween.chain().tween_callback(item.queue_free)

func _update_camera(delta: float) -> void:
	# Follow the player's actual movement. Lead in the walk direction, never drift off screen.
	var smooth := 1.0-exp(-6.0*delta)
	var desired_lead := last_player_heading * 1.25 if player.walk_amount > .12 else Vector3.ZERO
	camera_lead = camera_lead.lerp(desired_lead,1.0-exp(-2.6*delta))
	camera_follow=camera_follow.lerp(player.position + camera_lead,smooth)
	var camera_offset := Vector3(0,13.7,13.6).rotated(Vector3.UP,camera_yaw)*camera_distance
	var goal := camera_follow+camera_offset
	camera.position=camera.position.lerp(goal,1.0-exp(-7.7*delta))
	camera.look_at(camera_follow+Vector3(0,1.0,0),Vector3.UP)
	if destination_marker != null and destination_marker.visible:
		destination_marker.rotation.y += delta*1.8

func _process(delta: float) -> void:
	anim_timer+=delta
	_process_player(delta)
	_process_helpers(delta)
	_process_customers(delta)
	_process_shipping(delta)
	_update_camera(delta)
	customers_timer-=delta
	if customers_timer<=0:
		_spawn_customer()
		customers_timer=4.6
	display_timer-=delta
	if display_timer<=0:
		_refresh_ui()
		display_timer=.20
	if event_fade>0:
		event_fade-=delta
		event_label.modulate.a=minf(1.0,event_fade/.35)
		if event_fade<=0:event_label.visible=false
	save_timer-=delta
	if save_timer<0:
		_save_progress()
		save_timer=8.0

func _cash_sound() -> void:
	if cash_sfx.stream: cash_sfx.play()

func _unhandled_input(event: InputEvent) -> void:
	if shop_panel != null and shop_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: _toggle_shop()
		return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance=minf(camera_distance+.09,1.33)
		elif event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance=maxf(camera_distance-.09,.78)
		elif event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			_set_tap_goal(event.position)
	if event is InputEventScreenTouch and event.pressed:
		if event.position.x > get_viewport().get_visible_rect().size.x*.25:
			_set_tap_goal(event.position)
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if shop_panel.visible:_toggle_shop()

func _set_tap_goal(screen_position: Vector2) -> void:
	# Project the finger's ray onto the flat terrain at y=0.
	var origin := camera.project_ray_origin(screen_position)
	var ray := camera.project_ray_normal(screen_position)
	if ray.y > -.001:return
	var t := -origin.y / ray.y
	if t < 0 or t > 150:return
	var destination := origin + ray*t
	destination.x = clampf(destination.x,-23,23)
	destination.z = clampf(destination.z,-23,23)
	_set_world_goal(destination)

func _set_world_goal(destination: Vector3) -> void:
	var goal: Vector3=world.navigation.nearest_free(destination)
	if world.navigation.find_path(player.position,goal).is_empty(): return
	tap_destination=goal
	if player.has_meta("route_goal"): player.remove_meta("route_goal")
	has_tap_destination=true
	destination_marker.position=goal+Vector3(0,.12,0)
	destination_marker.visible=true

func _save_data() -> Dictionary:
	var workers: Array = []
	for helper in helpers:
		var actor: MarketActor=helper["actor"]
		workers.append({"position":[actor.position.x,actor.position.z],"state":helper["state"],
			"cargo":helper["cargo"],"cargo_amount":helper["cargo_amount"],"timer":helper["timer"],
			"crop_index":world.crop_spots.find(helper["crop"])})
	var crops: Array = []
	for crop in world.crop_spots:
		crops.append({"regrow":crop["regrow"] if not crop["ready"] else 0.0})
	return {"version":2,"coins":coins,"earned":earned,"sold":sold,"delivered":delivered,
		"worker_count":worker_count,"player_speed":player_speed,"max_capacity":max_capacity,
		"stash":stash,"counter":counter,"quest_level":quest_level,"total_buyers":total_buyers,
		"helper_cost":helper_cost,"speed_cost":speed_cost,"bag_cost":bag_cost,"orchard_owned":orchard_owned,
		"pier_owned":pier_owned,"player_pos":[player.position.x,player.position.z],"helpers":workers,
		"crops":crops,"shipment":shipment,"shipments_completed":shipments_completed}

func _save_progress() -> bool:
	var success := SaveStore.write_data(save_path,_save_data())
	if not success and not save_error_shown:
		save_error_shown=true
		_notice("No se pudo guardar. Revisá el espacio libre.",3)
	return success

func _load_progress() -> void:
	var data := SaveStore.load_data(save_path)
	if data.is_empty():return
	coins=int(SaveStore.number(data,"coins",50,0,2000000000))
	earned=int(SaveStore.number(data,"earned",0,0,2000000000))
	sold=int(SaveStore.number(data,"sold",0,0,10000000))
	delivered=int(SaveStore.number(data,"delivered",0,0,10000000))
	worker_count=int(SaveStore.number(data,"worker_count",0,0,MAX_HELPERS))
	player_speed=SaveStore.number(data,"player_speed",4.5,4.5,12)
	max_capacity=int(SaveStore.number(data,"max_capacity",12,12,300))
	quest_level=int(SaveStore.number(data,"quest_level",1,1,500001))
	quest_level=maxi(quest_level,int(sold/20)+1)
	total_buyers=int(SaveStore.number(data,"total_buyers",0,0,10000000))
	helper_cost=int(SaveStore.number(data,"helper_cost",80,80,2000000000))
	speed_cost=int(SaveStore.number(data,"speed_cost",95,95,2000000000))
	bag_cost=int(SaveStore.number(data,"bag_cost",70,70,2000000000))
	orchard_owned=data.get("orchard_owned",false)==true
	pier_owned=data.get("pier_owned",false)==true
	var bag_data: Dictionary=data["stash"] if data.get("stash") is Dictionary else {}
	var stock_data: Dictionary=data["counter"] if data.get("counter") is Dictionary else {}
	var available := max_capacity
	for key in stash.keys():
		stash[key]=int(SaveStore.number(bag_data,key,0,0,available))
		available-=int(stash[key])
		counter[key]=int(SaveStore.number(stock_data,key,0,0,1000000))
	player.position=world.navigation.nearest_free(SaveStore.position(data.get("player_pos"),player.position))
	if orchard_owned:world.open_orchard()
	if pier_owned:world.open_pier()
	saved_helpers=data["helpers"] if data.get("helpers") is Array else []
	var saved_crops: Array=data["crops"] if data.get("crops") is Array else []
	for i in range(mini(saved_crops.size(),world.crop_spots.size())):
		if not saved_crops[i] is Dictionary: continue
		var regrow := SaveStore.number(saved_crops[i],"regrow",0,0,3)
		world.crop_spots[i]["regrow"]=regrow
		world.crop_spots[i]["ready"]=regrow<=0
		world.crop_spots[i]["node"].scale=Vector3.ONE*maxf(.12,1-regrow/3.0)
	var saved_shipment: Dictionary=data["shipment"] if data.get("shipment") is Dictionary else {}
	var kind: Variant=saved_shipment.get("kind", "")
	if pier_owned and kind is String and SELL_VALUE.has(kind):
		shipment={"kind":kind,"amount":int(SaveStore.number(saved_shipment,"amount",SHIPMENT_SIZE,1,SHIPMENT_SIZE)),
			"remaining":SaveStore.number(saved_shipment,"remaining",SHIPMENT_DURATION,0,SHIPMENT_DURATION)}
	shipments_completed=int(SaveStore.number(data,"shipments_completed",0,0,10000000))
	world.update_pier_shipment(shipment["kind"],shipment["amount"],shipment["remaining"],SHIPMENT_DURATION)
	player.set_carry(_total_bag())

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT] and player != null:
		boost_active=false
		has_tap_destination=false
		if destination_marker != null: destination_marker.visible=false
		if input_stick != null: input_stick._clear()
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED] and player != null:
		_save_progress()
