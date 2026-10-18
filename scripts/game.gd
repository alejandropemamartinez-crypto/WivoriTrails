extends Node3D

const ActorScript = preload("res://scripts/actor.gd")
const WorldScript = preload("res://scripts/world.gd")
const HudScript = preload("res://scripts/hud.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const DirectorScript = preload("res://scripts/market_director.gd")
const TrailScript = preload("res://scripts/trail_guide.gd")
const RunScript = preload("res://scripts/market_run.gd")
const SAVE_PATH = "user://wivori_trails_save.json"
const MAX_HELPERS := 12
const BASE_SPEED := 6.8
const MAX_SPEED := 14.3
const PAD_RADIUS := 1.85
const UPGRADE_POS = {"helper":Vector3(-2.6,0,6.3),"bag":Vector3(-3,0,11),"speed":Vector3(3.5,0,10),
	"checkout":Vector3(9,0,-3),"expand":Vector3(10,0,-10),"pier":Vector3(16,0,12),
	"lock":Vector3(7,0,-6.5),"alarm":Vector3(12,0,9.8),"guard":Vector3(7.5,0,11)}
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
var player_speed := BASE_SPEED
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
var checkout_level := 0
var director
var run
var manual_delivered := 0
var marker_time := 0.0
var trail
var active_pad := ""
var guide_override := {}
var save_path := SAVE_PATH
var save_error_shown := false
var hud

func _ready() -> void:
	_engine_world()
	world = WorldScript.new()
	world.name = "Wivori Trails"
	add_child(world)
	player = ActorScript.new()
	player.ground_sampler=Callable(world,"ground_height")
	player.name = "Personaje controlable"
	player.setup("player",Color("#338f8b"),"dog")
	add_child(player)
	player.position = Vector3(0,0,4)
	world.shape(player,"cylinder",Vector3(0,.06,0),Vector3(1.05,.025,1.05),Color("#328c87"),"Tu personaje")
	world.shape(player,"cylinder",Vector3(0,.08,0),Vector3(.78,.025,.78),Color("#d5eadb"))
	cashier=ActorScript.new()
	cashier.ground_sampler=Callable(world,"ground_height")
	cashier.setup("vendor",Color("#b66242"),"dog")
	cashier.name="Vendedor del mercado"
	add_child(cashier)
	cashier.position=Vector3(4,0,-3.1)
	camera_follow = player.position
	_setup_camera()
	_setup_destination_marker()
	_setup_sounds()
	director=DirectorScript.new(self)
	run=RunScript.new(self)
	_load_progress()
	camera_follow=player.position
	_update_camera(1.0)
	_setup_hud()
	trail=TrailScript.new(); trail.g=self; add_child(trail)
	for i in range(worker_count):
		_spawn_worker(i, saved_helpers[i] if i < saved_helpers.size() and saved_helpers[i] is Dictionary else {})
	_refresh_ui()

func _engine_world() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "WivoriEnvironment"
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("#b8dce1")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("#c8ddca")
	sky.ambient_light_energy = .25
	sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	sky.tonemap_exposure = 0.88
	environment.environment = sky
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-37,0)
	sun.light_color = Color("#ffe8cc")
	sun.light_energy = .66
	sun.shadow_enabled = true
	add_child(sun)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Cámara suave que sigue al jugador"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = 48.0
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

func _setup_hud() -> void:
	hud=HudScript.new()
	add_child(hud)
	hud.build(self)

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
	if hud == null: return
	world.update_market_stock(counter)
	world.update_security(run)
	_update_active_pad()
	var upgrades := {}
	for kind in UPGRADE_POS:upgrades[kind]=_upgrade(kind)
	world.update_upgrade_pads(upgrades,coins,director.recommended())
	hud.refresh()
	if trail!=null:trail.update_route(hud.objective)

func _upgrade(kind: String) -> Dictionary:
	var definitions := {
		"helper":{"name":"Ayudante automático","short":"AYUDANTE","price":helper_cost,"benefit":"Cosecha y entrega por vos.","done":worker_count>=MAX_HELPERS},
		"checkout":{"name":"Caja rápida","short":"CAJA RÁPIDA","price":140+checkout_level*180,"benefit":"Atiende casi al doble de velocidad.","done":checkout_level>=3},
		"bag":{"name":"Mochila más grande","short":"MOCHILA","price":bag_cost,"benefit":"Llevá %d productos por viaje." % mini(300,max_capacity+6),"done":max_capacity>=300},
		"speed":{"name":"Zapatillas turbo","short":"VELOCIDAD","price":speed_cost,"benefit":"Más velocidad en todos tus viajes.","done":player_speed>=MAX_SPEED},
		"expand":{"name":"Huerto de manzanas","short":"HUERTO","price":expand_cost,"benefit":"9 cultivos nuevos. Cada manzana vale 14.","done":orchard_owned},
		"pier":{"name":"Muelle automático","short":"MUELLE","price":550,"benefit":"Exporta excedentes con 50% de ganancia extra.","done":pier_owned},
		"lock":{"name":"Almacén seguro","short":"CERROJO","price":120+run.lock_level*130,"benefit":"Demora el robo: %d → %d segundos." % [4+run.lock_level*4,mini(16,8+run.lock_level*4)],"done":run.lock_level>=3},
		"alarm":{"name":"Alarma de vigilancia","short":"ALARMA","price":160+run.alarm_level*140,"benefit":"Avisa antes y frena mapaches cerca del puesto.","done":run.alarm_level>=3},
		"guard":{"name":"Guardia del mercado","short":"GUARDIA","price":260+run.guard_level*180,"benefit":"Patrulla e intercepta. Descansa entre intervenciones.","done":run.guard_level>=3}}
	if not definitions.has(kind):return {}
	var upgrade: Dictionary=definitions[kind]
	upgrade["target"]=UPGRADE_POS[kind]
	upgrade["locked"]=(kind in ["lock","alarm"] and run.level<3) or (kind=="guard" and run.level<4)
	return upgrade

func _harvest_target() -> Vector3:
	# The first lesson stays predictable. Later trips point to a ready nearby field.
	if delivered==0:return Vector3(-8,0,0)
	var nearest := Vector3(-8,0,0)
	var distance := INF
	for crop in world.crop_spots:
		if not crop["enabled"] or not crop["ready"]:continue
		var at: Vector3=crop["node"].global_position
		var d := player.position.distance_squared_to(at)
		if d<distance:distance=d; nearest=at
	return nearest

func _update_active_pad() -> void:
	active_pad=""
	if shop_panel!=null and shop_panel.visible:return
	var closest := PAD_RADIUS
	for kind in UPGRADE_POS:
		if _upgrade(kind)["done"] or _upgrade(kind)["locked"]:continue
		var distance: float=player.position.distance_to(UPGRADE_POS[kind])
		if distance<closest:closest=distance; active_pad=kind

func _purchase_nearby() -> void:
	_update_active_pad()
	if active_pad.is_empty():return
	_buy(active_pad)

func _follow_alert() -> void:
	var alert: Dictionary=director.alert()
	if alert.is_empty():return
	guide_override={"id":alert["id"],"target":alert["target"],"tag":"TU MERCADO NECESITA ATENCIÓN",
		"title":alert["title"],"detail":alert["detail"],"goal":1,"value":1,"button":"SEÑALAR"}
	_set_world_goal(alert["target"])
	_refresh_ui()

func _current_objective() -> Dictionary:
	if not guide_override.is_empty():
		var alert: Dictionary=director.alert()
		if alert.get("id","")==guide_override["id"] and player.position.distance_to(guide_override["target"])>PAD_RADIUS:
			if alert["id"]=="raid":guide_override["target"]=alert["target"]
			return guide_override
		guide_override={}
	return director.objective()

func _follow_objective() -> void:
	var objective := _current_objective()
	if objective.get("upgrade","")=="level":run.advance(); return
	if objective.has("target"):
		var kind: String=objective.get("upgrade","")
		if not kind.is_empty() and player.position.distance_to(objective["target"])<=PAD_RADIUS:_buy(kind)
		else:_set_world_goal(objective["target"])
	else:_toggle_shop()

func _intercept() -> void:
	run.intercept()
	_refresh_ui()

func _harvest_kind(kind: String) -> Vector3:
	var target:=Vector3(-8,0,0)
	var closest:=INF
	for crop in world.crop_spots:
		if crop["kind"]!=kind or not crop["enabled"]:continue
		var d: float=player.position.distance_squared_to(crop["node"].global_position)+(0 if crop["ready"] else 100)
		if d<closest:closest=d; target=crop["node"].global_position
	return target

func _toggle_camera_view() -> void:
	camera_distance=1.0 if camera_distance>1.15 else 1.38

func _notice(message: String, time_: float = 1.45) -> void:
	if event_label == null: return
	event_label.text=message
	event_label.visible=true
	event_label.modulate.a=1.0
	event_fade=time_

func _buy(kind: String) -> void:
	var upgrade := _upgrade(kind)
	if upgrade.is_empty() or upgrade["done"] or upgrade["locked"]:return
	var price: int=upgrade["price"]
	if coins<price:
		_notice("TE FALTAN %d MONEDAS" % (price-coins),1.6)
		return
	coins-=price
	director.pinned_kind=""
	match kind:
		"helper":
			worker_count+=1
			_spawn_worker(worker_count-1)
			helper_cost=int(ceil(float(helper_cost)*1.70))
			_notice("¡AYUDANTE CONTRATADO!\nYa cosecha y abastece por vos.",2.8)
		"checkout":
			var previous_time := _checkout_duration()
			checkout_level+=1
			for customer in customers:
				if customer["stage"]=="buying":customer["wait"]*=(_checkout_duration()/previous_time)
			_notice("¡CAJA MÁS RÁPIDA!\nAhora los clientes esperan menos.",2.5)
		"lock":
			run.lock_level+=1
			for raid in run.raiders:
				if raid["state"]=="tamper":raid["remaining"]=minf(16,raid["remaining"]+4)
			_notice("¡ALMACÉN ASEGURADO!\nAhora tardan más en llevarse productos.",2.5)
		"alarm":
			run.alarm_level+=1
			_notice("¡ALARMA INSTALADA!\nMás aviso y mapaches más lentos cerca del puesto.",2.5)
		"guard":
			run.guard_level+=1
			_notice("¡GUARDIA CONTRATADO!\nPatrulla; vos atendé pedidos e interceptá al resto.",2.5)
		"speed":
			player_speed=minf(MAX_SPEED,player_speed+.65)
			speed_cost+=55
			_notice("¡ZAPATILLAS TURBO!",1.8)
		"bag":
			max_capacity=mini(300,max_capacity+6)
			bag_cost+=65
			_notice("¡MOCHILA AMPLIADA!",1.8)
		"expand":
			orchard_owned=true
			world.open_orchard()
			_notice("¡HUERTO ABIERTO!\nLas manzanas ya están listas.",2.5)
		"pier":
			pier_owned=true
			world.open_pier()
			_notice("¡MUELLE AUTOMÁTICO!\nExportá excedentes con +50%.",2.5)
	# Walking over a pad never spends coins. Only an explicit button does.
	guide_override={}
	world.celebrate_upgrade(kind)
	_save_progress()
	_refresh_ui()

func _spawn_worker(index: int, saved: Dictionary = {}) -> void:
	var actor: MarketActor=ActorScript.new()
	actor.ground_sampler=Callable(world,"ground_height")
	actor.setup("helper",[Color("#db9d4c"),Color("#aa7bc5"),Color("#70a368")][index%3],["dog","cat","rabbit"][index%3])
	add_child(actor)
	actor.position=world.navigation.nearest_free(SaveStore.position(saved.get("position"), UPGRADE_POS["helper"]+Vector3(float(index%3)*.95,0,1.3+float(index/3)*.8)))
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

func _queue_count() -> int:
	var count := 0
	for customer in customers:
		if customer["stage"]!="leaving":count+=1
	return count

func _waiting_count() -> int:
	var count := 0
	for customer in customers:
		if customer["stage"] in ["waiting","buying"]:count+=1
	return count

func _checkout_duration() -> float:
	return [4.6,2.6,1.55,.95][checkout_level]

func _queue_position(index: int) -> Vector3:
	return Vector3(8.3,0,.6) if index==0 else Vector3(9.5+(.55 if index%2==0 else 0),0,.8+float(index)*1.4)

func _spawn_customer() -> void:
	if _queue_count()>=6:return
	var a: MarketActor=ActorScript.new()
	a.ground_sampler=Callable(world,"ground_height")
	var species_: String=["cat","pig","rabbit","fox"][randi()%4]
	a.setup("customer",{"cat":Color("#498f83"),"pig":Color("#b872ad"),"rabbit":Color("#8c94bf"),"fox":Color("#e2aa56")}[species_],species_)
	add_child(a)
	var lane := float(_queue_count())*.4
	a.position=Vector3(19,0,-5.5+lane)
	var bubble: Label3D=world.make_label(a,"",Vector3(0,3.0,0),30)
	bubble.visible=false
	customers.append({"actor":a,"stage":"coming","wait":0.0,"lane":lane,"age":0.0,"bubble":bubble})

func _move_actor(actor: MarketActor, destination: Vector3, step: float, delta: float) -> bool:
	if not actor.has_meta("route_goal") or actor.get_meta("route_goal").distance_to(destination) > (.5 if actor.character_role=="guard" else .05) or actor.get_meta("route_revision", -1) != world.navigation.revision:
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

func _helper_crop(actor: MarketActor) -> Dictionary:
	var chosen := {}
	var best := INF
	for crop in world.crop_spots:
		if not crop["enabled"] or not crop["ready"]:continue
		var reserved := false
		for other in helpers:
			if other["actor"]!=actor and other["state"] in ["to_crop","collect"] and other["crop"]==crop:
				reserved=true; break
		if reserved:continue
		var score: float=actor.position.distance_to(crop["node"].global_position)+float(counter[crop["kind"]])*.22
		if score<best:best=score; chosen=crop
	return chosen

func _process_helpers(delta: float) -> void:
	for h in helpers:
		var a: MarketActor=h["actor"]
		match h["state"]:
			"search":
				var target: Dictionary=_helper_crop(a)
				if not target.is_empty():
					h["crop"]=target
					h["state"]="to_crop"
			"to_crop":
				var target: Dictionary=h["crop"]
				if target.is_empty() or not target["ready"]:
					h["state"]="search"
				elif _move_actor(a,target["node"].global_position,4.2,delta):
					h["state"]="collect"
					h["timer"]=.30
			"collect":
				h["timer"]=float(h["timer"])-delta
				if h["timer"]<=0:
					h["cargo"]=world.harvest(h["crop"])
					a.act("harvest")
					if h["cargo"]!="":
						h["cargo_amount"]=3
						a.set_carry(3)
						h["state"]="to_store"
					else:
						h["state"]="search"
			"to_store":
				if _move_actor(a,Vector3(4,0,3.3),4.2,delta):
					var kind: String=h["cargo"]
					if kind!="":
						counter[kind]+=int(h["cargo_amount"])
						delivered+=int(h["cargo_amount"])
					h["cargo"]=""
					h["cargo_amount"]=0
					a.set_carry(0)
					h["state"]="search"

func _process_customers(delta: float) -> void:
	# Exactly one customer owns the checkout. Others advance to distinct queue
	# spots; service pauses without stock and never charges twice.
	var queue: Array[Dictionary]=[]
	for customer in customers:
		if customer["stage"]!="leaving":queue.append(customer)
	for c in customers.duplicate():
		var a: MarketActor=c["actor"]
		var bubble: Label3D=c["bubble"]
		if c["stage"]=="leaving":
			bubble.visible=false
			if _move_actor(a,Vector3(19,0,-8+float(c["lane"])),3.4,delta):
				customers.erase(c); a.queue_free()
			continue
		var index := queue.find(c)
		var at_front: bool=index==0
		var reached := _move_actor(a,_queue_position(index),2.9,delta)
		if not reached:
			c["stage"]="coming"; bubble.visible=false
			continue
		c["age"]+=delta
		if c["stage"]=="coming":c["stage"]="waiting"
		bubble.visible=at_front or float(c["age"])>8
		bubble.text="..." if not at_front else ("¡STOCK!" if _total_stock()==0 else "COMPRANDO")
		bubble.modulate=Color("#ffdc9a") if _total_stock()==0 else Color("#fff6d8")
		if not at_front or _total_stock()==0:continue
		if c["stage"]!="buying":
			c["stage"]="buying"; c["wait"]=_checkout_duration()
		c["wait"]-=delta
		if c["wait"]>0:continue
		var kind := _first_stocked()
		if kind.is_empty():continue
		var count := mini(3,int(counter[kind]))
		counter[kind]-=count
		var income: int=int(SELL_VALUE[kind])*count
		_record_sale(count,income)
		total_buyers+=1
		_cash_sound(); cashier.walk_amount=.55
		# A quiet floating receipt leaves tutorial/upgrade announcements readable.
		world.sale_receipt(a.position,income)
		c["stage"]="leaving"

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
	quest_level=maxi(quest_level,int(sold/20)+1)

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
	# Player travel is exclusively manual. Guides and terrain taps only mark.
	var world_motion := Vector3(joy.x,0,joy.y).rotated(Vector3.UP,camera_yaw)
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
				player.act("harvest")
				harvest_wait=.23
				if harvest_sfx.stream:harvest_sfx.play()
				_spawn_pickup_fx(crop["node"].global_position,resource)

	if drop_wait<=0 and run.deliver_contract()>0:drop_wait=.6
	if drop_wait<=0 and _total_bag()>0 and player.position.distance_to(Vector3(4,0,2.5))<2.5:
		for resource in stash.keys():
			manual_delivered+=stash[resource]
			delivered+=stash[resource]
			counter[resource]+=stash[resource]
			stash[resource]=0
		player.set_carry(0)
		player.act("deliver")
		_notice("¡PUESTO ABASTECIDO!",1.1)
		drop_wait=.6
	if _total_bag()>=max_capacity:
		hint_label.text="Bolsa llena · llevá tu cosecha al puesto"
	elif player.position.distance_to(Vector3(4,0,2.5))<4:
		hint_label.text="Círculo dorado · entrega automática"
	elif _total_stock()<3:
		hint_label.text="Acercate a un cultivo para cosechar"
	else:
		hint_label.text="Tu puesto vende automáticamente"

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
	marker_time-=delta
	if marker_time<=0:destination_marker.visible=false
	_process_player(delta)
	_process_helpers(delta)
	_process_customers(delta)
	_process_shipping(delta)
	if not shop_panel.visible:run.tick(delta)
	director.tick(delta)
	_update_camera(delta)
	customers_timer-=delta
	if customers_timer<=0:
		_spawn_customer()
		customers_timer=maxf(2.7,3.4-float(quest_level-1)*.08)
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
			camera_distance=minf(camera_distance+.09,1.5)
		elif event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance=maxf(camera_distance-.09,.86)
		elif event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			_set_tap_goal(event.position)
	if event is InputEventScreenTouch and event.pressed:
		if event.position.x > get_viewport().get_visible_rect().size.x*.25:
			_set_tap_goal(event.position)
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if shop_panel.visible:_toggle_shop()

func _set_tap_goal(screen_position: Vector2) -> void:
	guide_override={}
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
	# Mark the destination; never create a player movement route.
	tap_destination=goal
	has_tap_destination=false
	marker_time=4.0
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
	return {"version":4,"coins":coins,"earned":earned,"sold":sold,"delivered":delivered,
		"worker_count":worker_count,"player_speed":player_speed,"max_capacity":max_capacity,
		"stash":stash,"counter":counter,"quest_level":quest_level,"total_buyers":total_buyers,
		"helper_cost":helper_cost,"speed_cost":speed_cost,"bag_cost":bag_cost,"orchard_owned":orchard_owned,
		"pier_owned":pier_owned,"player_pos":[player.position.x,player.position.z],"helpers":workers,
		"crops":crops,"shipment":shipment,"shipments_completed":shipments_completed,"camera_distance":camera_distance,
		"checkout_level":checkout_level,"announced_upgrades":director.announced.keys(),
		"manual_delivered":manual_delivered,"run":run.save_state()}

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
	if int(data.get("version",1))<3:
		# Preserve every previously purchased speed bonus on the new faster base.
		player_speed=SaveStore.number(data,"player_speed",4.5,4.5,12)+(BASE_SPEED-4.5)
	else:
		player_speed=SaveStore.number(data,"player_speed",BASE_SPEED,BASE_SPEED,MAX_SPEED)
	checkout_level=int(SaveStore.number(data,"checkout_level",0,0,3))
	var announced: Variant=data.get("announced_upgrades",[])
	if announced is Array:
		for token in announced.slice(0,100):
			if token is String and token.length()<64:director.announced[token]=true
	camera_distance=SaveStore.number(data,"camera_distance",1.0,.86,1.5)
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
	manual_delivered=int(SaveStore.number(data,"manual_delivered",0,0,10000000))
	run.load_state(data["run"] if data.get("run") is Dictionary else {})
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
