extends Node3D

const State=preload("res://scripts/refuge_state.gd")
const Art=preload("res://scripts/refuge_art.gd")
const UI=preload("res://scripts/refuge_ui.gd")
const Actor=preload("res://scripts/actor.gd")
const Nav=preload("res://scripts/navigation.gd")
const Store=preload("res://scripts/save_store.gd")
const Market=preload("res://scripts/refuge_market.gd")
const MarketWorld=preload("res://scripts/refuge_market_world.gd")
const SAVE_PATH="user://wivori_refuge_save.json"
const WALK_SPEED=6.8
const RUN_SPEED=8.6
var save_path:=SAVE_PATH
var state=State.new()
var market=Market.new()
var market_world: Node3D
var working:=false
var work_cooldown:=0.0
var ui=UI.new()
var camera: Camera3D
var scenery: Node3D
var models: Dictionary={}
var navigation=Nav.new()
var ground: ShaderMaterial
var snow: CPUParticles3D
var core_light: OmniLight3D
var sun: DirectionalLight3D
var environment: Environment
var hero: MarketActor
var residents: Array[Dictionary]=[]
var focus:=Vector3(0,0,1.8)
var camera_follow:=Vector3(0,0,1.8)
var zoom:=26.0
var follow_zoom:=26.0
var camera_detached:=false
var camera_overview:=false
var sprinting:=false
var stick: MarketJoystick
var input_active:=false
var drag_origin:=Vector2.ZERO
var drag_previous:=Vector2.ZERO
var drag_distance:=0.0
var fingers: Dictionary={}
var elapsed:=0.0
var hud_clock:=0.0
var save_clock:=5.0
var saving_enabled:=true
var last_lit:=false
var last_city:=0
var suspended:=false
var world_city:=-1
var player_positions: Array[Vector3]=[]

func _ready() -> void:
	var saved: Dictionary=Store.load_data(save_path)
	_restore_player_positions(saved);state.restore(saved)
	_restore_market(saved)
	_lighting();_build_world();ui.build(self);_make_stick()
	market_world=MarketWorld.new();scenery.add_child(market_world);market_world.build(self)
	_connect_state()
	last_lit=state.lit;last_city=state.city
	if not state.offline_gains.is_empty():ui.notice("Tus habitantes trabajaron: +"+state.cost_text(state.offline_gains))
	if market.offline_coins>0:ui.notice("Tu red vendió mientras no estabas: +%d monedas." % market.offline_coins)
	# Commit the offline settlement before the player can close/reopen it.
	save();_camera(1);ui.refresh(0)

func _connect_state() -> void:
	state.built.connect(_on_built);state.opened.connect(_on_opened);state.message.connect(ui.notice)
	state.changed.connect(func():save_clock=minf(save_clock,.25))
	market.changed.connect(func():save_clock=minf(save_clock,.25))

func _restore_market(saved: Dictionary) -> void:
	var timestamp: float=Time.get_unix_time_from_system()
	var offline: float=clampf(timestamp-Store.number(saved,"last_saved",timestamp,0,4102444800),0,7200)
	market.restore(saved.get("market",{}),offline,state.unlocked)

func _lighting() -> void:
	var world_environment:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("#99b1c1")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("#c3d7e8");settings.ambient_light_energy=.42
	settings.tonemap_mode=Environment.TONE_MAPPER_AGX;settings.tonemap_exposure=.83
	environment=settings;world_environment.environment=settings;add_child(world_environment)
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-54,-28,0);sun.light_color=Color("#fff0d7");sun.light_energy=.68
	sun.shadow_enabled=true;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;sun.directional_shadow_max_distance=70;sun.shadow_blur=2.0;add_child(sun)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.size=zoom;camera.far=220;add_child(camera);camera.current=true

func _build_world(capture_position: bool=true) -> void:
	if capture_position:_capture_player_position()
	models.clear();residents.clear()
	if scenery!=null:remove_child(scenery);scenery.queue_free()
	scenery=Node3D.new();scenery.name="Refugio nevado · "+state.NAMES[state.city];add_child(scenery)
	var plane:=MeshInstance3D.new();var mesh:=PlaneMesh.new();mesh.size=Vector2(180,180);plane.mesh=mesh;plane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground=ShaderMaterial.new();ground.shader=preload("res://scripts/refuge_ground.gdshader")
	ground.set_shader_parameter("snow_tint",[Color("#a5bece"),Color("#b9c6bf"),Color("#98bdce"),Color("#9db0c1"),Color("#a0b9c4"),Color("#a4b9d2")][state.city]);plane.material_override=ground;scenery.add_child(plane)
	ground.set_shader_parameter("warm_radius",6.3+float(state.level("core")));ground.set_shader_parameter("warmth",1.0 if state.lit else .12)
	navigation=Nav.new();navigation.land_radius=Vector2(30,34)
	for id in state.BUILDINGS:
		var at: Vector3=state.BUILDINGS[id]["at"]
		navigation.add_obstacle(Rect2(Vector2(at.x-2.6,at.z-2.0),Vector2(5.2,4.0)))
		_replace_model(id)
	for product in Market.PRODUCTS:
		var at: Vector3=Market.SHOP_POSITIONS[product]
		navigation.add_obstacle(Rect2(Vector2(at.x-2.4,at.z-1.1),Vector2(4.8,2.4)))
	navigation.add_obstacle(Rect2(Vector2(-17.2,14.9),Vector2(4.4,2.6)))
	navigation.build()
	_trees();_mountains();_details();_weather()
	core_light=OmniLight3D.new();core_light.position=Vector3(0,2.1,0);core_light.light_color=Color("#ffb362");core_light.light_energy=1.2;core_light.omni_range=9.0;core_light.shadow_enabled=false;core_light.visible=state.lit;scenery.add_child(core_light)
	hero=Actor.new();hero.setup("player",Color("#3c827b"),"dog");scenery.add_child(hero)
	hero.position=navigation.nearest_free(player_positions[state.city]);hero.last_position=hero.position;world_city=state.city
	var ring:=MeshInstance3D.new();var halo:=TorusMesh.new();halo.inner_radius=.44;halo.outer_radius=.49;halo.rings=24;halo.ring_segments=6
	var gold:=StandardMaterial3D.new();gold.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;gold.albedo_color=Color("#efbe71")
	ring.mesh=halo;ring.material_override=gold;ring.position.y=.035;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;hero.add_child(ring)
	var count: int=mini(14,int(state.town()["people"]))
	for index in range(count):_spawn_resident(index)
	camera_detached=false;camera_overview=false;zoom=follow_zoom;focus=hero.position+Vector3(0,0,-1.5);camera_follow=focus
	if ui.root!=null:
		market_world=MarketWorld.new();scenery.add_child(market_world);market_world.build(self)

func _spawn_resident(index: int,arriving: bool=false) -> void:
	var actor:=Actor.new();actor.setup("worker",[Color("#a57651"),Color("#527a86"),Color("#657b66"),Color("#9a6f60")][index%4],["rabbit","fox","duck","pig"][index%4]);scenery.add_child(actor)
	var angle: float=float(index)*2.39996
	var at:=Vector3(cos(angle)*(5.6+float(index%3)*.6),0,sin(angle)*(5.6+float(index%3)*.6))
	actor.position=navigation.nearest_free(Vector3(0,0,17.0+float(index%2)) if arriving else at);actor.last_position=actor.position;actor.scale=Vector3.ONE*.84
	var cargo:=Node3D.new();actor.add_child(cargo);cargo.position=Vector3(0,.9,.44);cargo.visible=false
	residents.append({"actor":actor,"wait":float(index%4)*.7,"path":navigation.find_path(actor.position,at) if arriving else PackedVector3Array(),"visit":0,"cargo":cargo,"cargo_key":""})

func _replace_model(id: String,animate: bool=false) -> void:
	if models.has(id):scenery.remove_child(models[id]);models[id].queue_free()
	var tier: int=state.level(id)
	var model: Node3D=Art.make(scenery,"site" if tier==0 else id,0 if id=="core" and not state.lit else tier,state.BUILDINGS[id]["at"])
	if id=="core":model.active=state.lit
	model.visible=tier>0 or int(state.BUILDINGS[id]["unlock"])<=state.level("core")+1
	models[id]=model
	if animate:
		model.scale=Vector3.ONE*.85
		var tween:=create_tween();tween.tween_property(model,"scale",Vector3.ONE,.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _batch(mesh: Mesh,transforms: Array[Transform3D],parent: Node3D) -> void:
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=mesh;batch.instance_count=transforms.size()
	for index in range(transforms.size()):batch.set_instance_transform(index,transforms[index])
	var draw:=MultiMeshInstance3D.new();draw.multimesh=batch;parent.add_child(draw)

func _trees() -> void:
	var source=Art.make(scenery,"tree");var mesh: Mesh=source.draw.mesh;var transforms: Array[Transform3D]=[]
	for index in range(68):
		var angle: float=float(index)*2.399963
		var radius: float=20.0+float(index%5)*1.3
		var at:=Vector3(cos(angle)*radius,0,sin(angle)*radius*.83-1.0)
		# The front gate and route landmarks remain visible between trees.
		if at.z>14 and absf(at.x)<22:continue
		var scale_: float=.75+float(index%7)*.095
		transforms.append(Transform3D(Basis(Vector3.UP,float(index)*.7).scaled(Vector3.ONE*scale_),at))
	_batch(mesh,transforms,scenery);scenery.remove_child(source);source.queue_free()

func _mountains() -> void:
	for index in range(7):
		var angle: float=PI+float(index)*PI/6.0
		var mountain=Art.make(scenery,"mountain",1,Vector3(cos(angle)*63,0,sin(angle)*55-22));mountain.scale=Vector3.ONE*(.6+float(index%3)*.13)
	var source=Art.make(scenery,"rock");var transforms: Array[Transform3D]=[]
	for index in range(22):
		var angle: float=float(index)*2.1
		if sin(angle)*20.0>15:continue
		transforms.append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*(.5+float(index%3)*.22)),Vector3(cos(angle)*18.3,0,sin(angle)*20.0)))
	_batch(source.draw.mesh,transforms,scenery);scenery.remove_child(source);source.queue_free()

func _details() -> void:
	for at in [Vector3(-3.5,0,-2),Vector3(3.5,0,2),Vector3(-5,0,9),Vector3(4.0,0,-8)]:Art.make(scenery,"lamp",1,at)
	# Shared copper heat pipes are a visual connection to the central heart.
	var pipe_mesh:=CylinderMesh.new();pipe_mesh.top_radius=.075;pipe_mesh.bottom_radius=.075;pipe_mesh.height=1;pipe_mesh.radial_segments=6
	var material:=StandardMaterial3D.new();material.albedo_color=Color("#a7794f");material.roughness=.6;pipe_mesh.material=material
	var transforms: Array[Transform3D]=[]
	for side in [-1.0,1.0]:
		for z in range(10):transforms.append(Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(side*2.1,.10,-7.0+z)))
	_batch(pipe_mesh,transforms,scenery)
	if state.city in [2,5]:
		var water:=MeshInstance3D.new();var surface:=PlaneMesh.new();surface.size=Vector2(14,22);water.mesh=surface;water.position=Vector3(-28,-.05,7)
		preload("res://scripts/scene_finish.gd").water(water);scenery.add_child(water)
		preload("res://scripts/art_library.gd").place(scenery,"route_ferry",Vector3(-24,.05,7),Vector3.ONE*.8)
	if state.city==1:
		for at in [Vector3(-16,0,0),Vector3(-16,0,7)]:Art.make(scenery,"kitchen",2,at)
	if state.city==3:
		for at in [Vector3(16,0,-3),Vector3(17,0,-9)]:Art.make(scenery,"rock",1,at).scale=Vector3.ONE*2.0
	if state.city in [4,5]:
		var plant=Art.make(scenery,"factory",3,Vector3(-15,0,12));plant.scale=Vector3.ONE*.8

func _weather() -> void:
	snow=CPUParticles3D.new();snow.name="Nieve del refugio";snow.position=Vector3(0,16,0);snow.amount=100;snow.lifetime=10.0;snow.preprocess=4.0
	snow.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;snow.emission_box_extents=Vector3(23,1,27);snow.direction=Vector3(.17,-1,.1)
	snow.spread=10;snow.initial_velocity_min=1.2;snow.initial_velocity_max=2.2;snow.gravity=Vector3(.08,-.05,0)
	var flake:=SphereMesh.new();flake.radius=.035;flake.height=.07;flake.radial_segments=4;flake.rings=2
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color("#e6f0f3");flake.material=material;snow.mesh=flake;scenery.add_child(snow)

func _make_stick() -> void:
	stick=preload("res://scripts/joystick.gd").new();ui.root.add_child(stick);stick.anchor_top=1;stick.anchor_bottom=1
	stick.offset_left=22;stick.offset_right=212;stick.offset_top=-516;stick.offset_bottom=-326
	ui.root.move_child(stick,ui.modal.get_index())
	stick.input_allowed=controls_allowed
	sync_controls()

func controls_allowed() -> bool:return not suspended and ui.modal!=null and not ui.modal.visible
func clear_controls() -> void:
	input_active=false;fingers.clear();sprinting=false;working=false
	if stick!=null:stick._clear()
	if ui.run_button!=null:ui.run_button._release_touch()
	if ui.work_button!=null:ui.work_button._release_touch()
func sync_controls() -> void:
	var enabled: bool=controls_allowed()
	if stick!=null:stick.visible=enabled
	for node in [ui.camera_button,ui.run_button,ui.work_button,ui.work_hint,ui.move_hint]:
		if node!=null:node.visible=enabled
func begin_sprint() -> void:
	if controls_allowed():sprinting=true
func end_sprint() -> void:sprinting=false
func begin_work() -> void:
	if not controls_allowed():return
	working=true;_manual_work()
func end_work() -> void:working=false
func _manual_work() -> void:
	if not controls_allowed() or work_cooldown>0:return
	var result: Dictionary=market.use(hero.position,state.city)
	if result.is_empty():return
	work_cooldown=.48 if result["kind"]=="harvest" else .65
	hero.act("harvest" if result["kind"]=="harvest" else "deliver")
	var toward: Vector3=result["at"]-hero.position
	if toward.length_squared()>.01:hero.face_direction_yaw(atan2(toward.x,toward.z))
	if result["kind"]!="harvest":ui.notice("%d productos %s" % [result["quantity"],"en el puesto. Los clientes pagan al completar su pedido." if result["kind"]=="deliver" else "cargados. Llevalos a los puestos."])
	save_clock=minf(save_clock,.25)

func _restore_player_positions(saved: Dictionary) -> void:
	player_positions.clear()
	var positions: Array=saved.get("hero_positions",[]) if saved.get("hero_positions") is Array else []
	for area in range(state.NAMES.size()):player_positions.append(Store.position(positions[area] if area<positions.size() else null,Vector3(-1,0,23.0)))
func _capture_player_position() -> void:
	if is_instance_valid(hero) and world_city>=0 and world_city<player_positions.size():player_positions[world_city]=hero.position

func _process(delta: float) -> void:
	var step: float=minf(delta,.25);elapsed+=step;state.tick(step);market.tick(step,state.unlocked)
	work_cooldown=maxf(0,work_cooldown-step)
	if working and controls_allowed():_manual_work()
	if last_lit!=state.lit:
		last_lit=state.lit;_replace_model("core",true)
	ground.set_shader_parameter("warm_radius",6.3+float(state.level("core"))*1.0)
	ground.set_shader_parameter("warmth",1.0 if state.lit else .12)
	core_light.visible=state.lit
	var night: float=smoothstep(154,171,fposmod(float(state.town()["time"]),240.0))
	sun.light_energy=lerpf(sun.light_energy,lerpf(.68,.28,night)*(.8 if state.storm() else 1.0),step*2.0)
	environment.ambient_light_color=Color("#c3d7e8").lerp(Color("#7898c8"),night*.65)
	if snow!=null:snow.speed_scale=1.75 if state.storm() else 1.0
	if controls_allowed():
		var direction:=Vector3(stick.axis.x,0,stick.axis.y)
		var keyboard:=Vector3(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),0,float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		if keyboard.length_squared()>0:direction=keyboard.normalized()
		var right: Vector3=camera.global_basis.x;right.y=0;right=right.normalized()
		var forward: Vector3=camera.global_basis.z;forward.y=0;forward=forward.normalized()
		var move: Vector3=(right*direction.x+forward*direction.z)
		var speed: float=RUN_SPEED if sprinting else WALK_SPEED
		hero.position=navigation.slide(hero.position,move*speed*step)
		if move.length()>.03:
			hero.walk_to(move,move.length()*speed)
			if not input_active and fingers.is_empty():
				camera_detached=false
				if camera_overview:camera_overview=false;zoom=follow_zoom
		if not camera_detached:focus=hero.position+Vector3(0,0,-1.5)
	while residents.size()<mini(14,int(state.town()["people"])):_spawn_resident(residents.size(),true)
	_npc_tick(step);_camera(step);_placards()
	if is_instance_valid(market_world):market_world.refresh(step)
	hud_clock-=step
	if hud_clock<=0:hud_clock=.12;ui.refresh(.12)
	save_clock-=step
	if save_clock<=0:save();save_clock=5.0

func _npc_tick(delta: float) -> void:
	var roles: Array[String]=[]
	for id in state.BUILDINGS:
		for count in range(state.worker_count(id)):roles.append(id)
	for index in range(residents.size()):
		var record: Dictionary=residents[index];var actor: MarketActor=record["actor"]
		if index>=int(state.town()["people"]):actor.visible=false;continue
		var path: PackedVector3Array=record["path"]
		if not path.is_empty():
			var difference: Vector3=path[0]-actor.position
			if difference.length()<.12:
				path.remove_at(0);record["path"]=path
				if path.is_empty() and record["cargo"].visible:record["cargo"].visible=false;actor.act("deliver")
			else:
				var direction:=difference.normalized();actor.position+=direction*minf(delta*1.55,difference.length());actor.walk_to(direction,1.55)
			continue
		record["wait"]-=delta
		if float(record["wait"])>0:continue
		record["wait"]=3.5+float(index%4)*.8
		var target: Vector3
		if index<roles.size():
			var id: String=roles[index]
			target=state.BUILDINGS[id]["at"]+Vector3(0,0,3.0) if int(record["visit"])%2==0 else Vector3(-1.8+float(index%3)*1.8,0,3.8)
			var key: String=state.BUILDINGS[id]["resource"]
			if record["cargo_key"]!=key:
				for child in record["cargo"].get_children():record["cargo"].remove_child(child);child.queue_free()
				Art.make(record["cargo"],"cargo_"+key);record["cargo_key"]=key
			record["cargo"].visible=int(record["visit"])%2==1 and state.production(id)>0
		else:
			record["cargo"].visible=false
			var angle: float=float(index)*1.8+float(record["visit"])*1.2
			target=Vector3(cos(angle)*5.7,0,sin(angle)*5.7)
		record["path"]=navigation.find_path(actor.position,target);record["visit"]+=1
		if int(record["visit"])%2==1:actor.act("deliver")

func _camera(delta: float) -> void:
	camera_follow=camera_follow.lerp(focus,1.0-exp(-delta*6.0));camera.size=lerpf(camera.size,zoom,1.0-exp(-delta*6.0))
	camera.position=camera_follow+Vector3(22,31,35);camera.look_at(camera_follow)

func _placards() -> void:
	var height: float=ui.root.size.y
	var task: Dictionary=current_task()
	for id in ui.placards:
		var button: Button=ui.placards[id]
		var discovered: bool=int(state.BUILDINGS[id]["unlock"])<=state.level("core")+1 or state.level(id)>0
		var at: Vector3=state.BUILDINGS[id]["at"]+Vector3(0,5.0 if state.level(id)>0 else .8,0)
		if id=="watch" and state.level(id)>0:at.y=6.3
		var point: Vector2=camera.unproject_position(at)-button.size*.5
		point.x=clampf(point.x,14,ui.root.size.x-button.size.x-14);button.position=point
		button.visible=not ui.modal.visible and discovered and point.y>278 and point.y+button.size.y<height-321 and point.x>-30 and point.x+button.size.x<ui.root.size.x+30
		for control in [stick,ui.camera_button,ui.run_button,ui.work_button,ui.move_hint]:
			if control!=null and control.visible and button.get_global_rect().intersects(control.get_global_rect().grow(8)):button.visible=false;break
		var building: bool=not state.construction.is_empty() and state.construction["id"]==id and int(state.construction["city"])==state.city
		button.text=("%s · %d s" % [state.BUILDINGS[id]["short"],ceili(float(state.construction["remaining"]))]) if building else ("%s · %d" % [state.BUILDINGS[id]["short"],state.level(id)]) if state.level(id)>0 else "+ "+state.BUILDINGS[id]["short"]
		button.self_modulate=Color("#ffe0a3") if id==task["id"] else Color.WHITE

func focus_building(id: String) -> void:
	if not state.BUILDINGS.has(id):return
	camera_detached=true;camera_overview=false;focus=state.BUILDINGS[id]["at"]+Vector3(0,0,3.5)
func center_camera() -> void:
	clear_controls();camera_detached=false;camera_overview=false;zoom=follow_zoom
	if is_instance_valid(hero):focus=hero.position+Vector3(0,0,-1.5)
	sync_controls()
func show_overview() -> void:
	clear_controls();camera_detached=true;camera_overview=true;zoom=39 if hero.position.z>14 else 36;focus=Vector3(0,0,22 if hero.position.z>14 else 1.8);sync_controls()
func toggle_camera_view() -> void:
	if camera_detached:center_camera()
	else:show_overview()

func follow_task() -> void:
	var task: Dictionary=current_task()
	match task["action"]:
		"ignite":state.ignite();save();ui.notice("Cortá pinos y cazá osos. Usá las monedas de las ventas para contratar trabajadores.")
		"repel":state.repel();save()
		"building":ui.show_building(task["id"])
		"team":ui.show_team()
		"route":ui.show_route()
		"fleet":ui.show_fleet()
		"shop":ui.show_market(task.get("buy",""))
		"guide":
			clear_controls();camera_detached=true;camera_overview=false;focus=task["at"];zoom=follow_zoom
			ui.notice("Seguí los puntos dorados con el joystick. Tu personaje se mueve cuando vos lo dirigís.")

func current_task() -> Dictionary:
	if not state.lit:return state.next_task()
	if state.raid_remaining>0:return state.next_task()
	if state.city<state.unlocked:return {"id":"trade","title":state.NAMES[state.unlocked]+" está disponible","detail":"Entrá en RUTA y viajá cuando quieras. Este mercado sigue trabajando.","action":"route","button":"VIAJAR","at":Market.DEPOT}
	return market.next_task(state.city)
func focus_trade_counter(product: String) -> void:
	clear_controls();camera_detached=true;camera_overview=false;focus=Market.COUNTERS[product]
func route_can_open() -> bool:
	return state.city==state.unlocked and state.city<5 and ((market.charter_ready(state.city) and market.coins>=market.charter_price(state.city)) or (state.ready_next() and state.affordable(state.passage_cost())))
func open_trade_route() -> bool:
	if not route_can_open():return false
	if market.charter_ready(state.city) and market.coins>=market.charter_price(state.city):
		market.pay(market.charter_price(state.city));state.unlocked+=1;state.changed.emit();state.opened.emit(state.unlocked)
	else:state.open_next()
	save();return true
func buy_market(id: String) -> bool:
	if not market.buy(id,state.city):return false
	if id=="supplies":
		for key in {"wood":80,"food":50,"coal":30}:state.resources[key]+=float({"wood":80,"food":50,"coal":30}[key])
	ui.notice("Tramo construido · %d/3. El tren se activa al cerrar el circuito." % market.town(state.city)["rails"] if id=="rail" and not market.operating(state.city) else "¡Tren en marcha! Lleva la carga del depósito a los clientes." if id=="rail" else "Mejora comprada. La próxima tarea ya está señalada.")
	save();ui.refresh(0);return true

func _on_built(id: String,area: int) -> void:
	if area==state.city:
		_replace_model(id,true)
		for key in models:models[key].visible=state.level(key)>0 or int(state.BUILDINGS[key]["unlock"])<=state.level("core")+1
		ui.notice("%s · nivel %d completado" % [state.BUILDINGS[id]["name"],state.level(id)])
		if ui.view=="building" and ui.selected==id:ui.pending_building=id
	save()
func _on_opened(index: int) -> void:
	ui.notice("¡"+state.NAMES[index]+" disponible! Entrá a RUTA para viajar.");save()
func travel(destination: int) -> void:
	_capture_player_position()
	if state.travel(destination):
		ui.close();clear_controls();_build_world();sync_controls();save()
		ui.notice(state.NAMES[destination]+" · "+state.LESSONS[destination])
	else:ui.notice("Protegé el almacén antes de salir del refugio.")
func open_archipelago() -> void:
	save();get_tree().change_scene_to_file("res://Main.tscn")
func save() -> bool:
	if not saving_enabled:return true
	_capture_player_position()
	var data: Dictionary=state.snapshot();var positions: Array=[]
	for at in player_positions:positions.append([at.x,at.z])
	data["hero_positions"]=positions
	data["market"]=market.snapshot()
	var ok: bool=Store.write_data(save_path,data)
	if not ok and ui.root!=null:ui.notice("No se pudo guardar. Revisá el espacio del dispositivo.")
	return ok
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_CLOSE_REQUEST]:
		if is_inside_tree():save()
		clear_controls()
		if what==NOTIFICATION_APPLICATION_PAUSED:suspended=true;set_process(false);sync_controls()
	elif what==NOTIFICATION_APPLICATION_RESUMED and suspended:
		suspended=false
		var saved: Dictionary=Store.load_data(save_path)
		var resumed=State.new();resumed.restore(saved);state=resumed;ui.state=resumed;_restore_player_positions(saved)
		market=Market.new();_restore_market(saved);_connect_state()
		ui.close();_build_world(false);center_camera();last_lit=state.lit;save();set_process(true)
		if market.offline_coins>0:ui.notice("Tu tren vendió durante tu ausencia: +%d monedas." % market.offline_coins)
		if not state.offline_gains.is_empty():ui.notice("Durante tu ausencia: +"+state.cost_text(state.offline_gains))
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if ui.modal!=null and ui.modal.visible:ui.close()
		else:ui.show_menu()

func _unhandled_input(event: InputEvent) -> void:
	if ui.modal.visible:return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			zoom=clampf(zoom*(.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),23,44)
			if not camera_overview:follow_zoom=zoom
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:input_active=true;drag_origin=event.position;drag_previous=event.position;drag_distance=0
			else:
				if input_active and drag_distance<14:_tap(event.position)
				input_active=false
	elif event is InputEventMouseMotion and input_active:_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			fingers[event.index]=event.position
			if fingers.size()==1:input_active=true;drag_origin=event.position;drag_previous=event.position;drag_distance=0
			else:input_active=false;drag_distance=100
		else:
			if not fingers.has(event.index):return
			var was_multi: bool=fingers.size()>1
			fingers.erase(event.index)
			if input_active and drag_distance<14 and fingers.is_empty() and not event.canceled:_tap(event.position)
			input_active=false
			if was_multi and fingers.size()==1:
				var remaining: Vector2=fingers.values()[0]
				drag_origin=remaining;drag_previous=remaining;drag_distance=100;input_active=true
	elif event is InputEventScreenDrag and fingers.has(event.index):
		if fingers.size()>=2:
			var points: Array=fingers.values();var old_distance: float=points[0].distance_to(points[1]);fingers[event.index]=event.position;points=fingers.values()
			var new_distance: float=points[0].distance_to(points[1])
			if new_distance>10:
				zoom=clampf(zoom*old_distance/new_distance,23,44)
				if not camera_overview:follow_zoom=zoom
			drag_distance=100;input_active=false
		else:fingers[event.index]=event.position;_drag(event.position)
func _drag(point: Vector2) -> void:
	drag_distance=maxf(drag_distance,point.distance_to(drag_origin))
	if drag_distance>=14:
		camera_detached=true
		var relative: Vector2=point-drag_previous
		var right: Vector3=camera.global_basis.x;right.y=0;right=right.normalized()
		var down: Vector3=camera.global_basis.z;down.y=0;down=down.normalized()
		focus-=(right*relative.x+down*relative.y)*zoom/maxf(1,ui.root.size.x)
		focus.x=clampf(focus.x,-14,14);focus.z=clampf(focus.z,-18,20)
	drag_previous=point
func _tap(point: Vector2) -> void:
	var origin: Vector3=camera.project_ray_origin(point);var direction: Vector3=camera.project_ray_normal(point)
	var hit: Variant=Plane(Vector3.UP,0).intersects_ray(origin,direction)
	if hit==null:return
	var nearest: String="";var distance:=INF
	for id in state.BUILDINGS:
		if not models[id].visible:continue
		var at: Vector3=state.BUILDINGS[id]["at"];var d: float=Vector2(at.x-hit.x,at.z-hit.z).length()
		if d<3.5 and d<distance:nearest=id;distance=d
	if not nearest.is_empty():ui.show_building(nearest)
