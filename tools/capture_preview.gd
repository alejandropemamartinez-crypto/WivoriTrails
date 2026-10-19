extends SceneTree

# Reproducible real-engine review of a prepared test save. No mock UI or concept
# images. Every shown prop, action, wallet and menu is the shipped game code.
var game: Node3D
var output: String
var review_save: String

func _initialize() -> void:call_deferred("capture")
func frames(count: int) -> void:
	for i in range(count):await process_frame
func shot(name_: String) -> void:
	await frames(5)
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(name_+".png"))!=OK:quit(1);return
	print("PREVIEW: ",name_)
func camera_reset() -> void:
	game.camera_follow=game.player.position;game.camera_lead=Vector3.ZERO
	for i in range(8):game._update_camera(1)
func remove_raiders() -> void:
	for raid in game.run.raiders:raid["actor"].queue_free()
	game.run.raiders.clear();game.run.warning=0
func clear_review_save() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(review_save+suffix))

func capture() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name()=="headless":quit(1);return
	output=args[0];DirAccess.make_dir_recursive_absolute(output)
	review_save="user://wivori_visual_v014_%d.json" % OS.get_process_id();clear_review_save()
	seed(20261018)
	game=load("res://Main.tscn").instantiate();game.save_path=review_save;root.add_child(game)
	game.set_process(false);game.world.set_process(false)
	camera_reset();await shot("start")

	# The old "hero closeup" had a market roof between the lens and
	# the protagonist. Build a REAL Godot character-review stage instead of
	# accidentally approving a screenshot of a building.
	game.hud.root.visible=false
	game.world.visible=false
	game.player.visible=false
	var hidden_scene: Array[Node3D]=[]
	for candidate in game.get_children():
		if candidate is Node3D and candidate!=game.player and candidate.visible:
			hidden_scene.append(candidate)
			candidate.visible=false
	var photo_stage:=Node3D.new()
	photo_stage.name="Character review stage (not shipped in gameplay)"
	game.add_child(photo_stage)
	var stage_floor:=MeshInstance3D.new()
	var stage_plane:=PlaneMesh.new();stage_plane.size=Vector2(18,18)
	stage_floor.mesh=stage_plane
	var stage_material:=StandardMaterial3D.new()
	stage_material.albedo_color=Color("#b9d0b4");stage_material.roughness=1.0
	stage_floor.material_override=stage_material
	photo_stage.add_child(stage_floor)
	# A dedicated warm key/fill pair prevents hidden-world lights from making
	# dark fur unreadable in the character review. Both are real engine lights.
	var key_light:=DirectionalLight3D.new()
	key_light.rotation_degrees=Vector3(-46,-32,0)
	key_light.light_energy=1.15
	key_light.light_color=Color("#fff1d6")
	photo_stage.add_child(key_light)
	var fill_light:=DirectionalLight3D.new()
	fill_light.rotation_degrees=Vector3(-18,145,0)
	fill_light.light_energy=.58
	fill_light.light_color=Color("#d9eefa")
	photo_stage.add_child(fill_light)
	var gallery: Array[MarketActor]=[]
	# Distinct NPC species; the hero remains the only Scottish Terrier.
	for i in range(3):
		var actor: MarketActor=game.ActorScript.new()
		actor.setup("customer",[Color("#4c9992"),Color("#d49f68"),Color("#70899b")][i],["fox","rabbit","pig"][i])
		game.add_child(actor)
		actor.position=Vector3((i-1)*1.13,0,0)
		gallery.append(actor)
	game.camera.position=Vector3(0,2.75,6.6);game.camera.fov=48
	game.camera.look_at(Vector3(0,1.37,0))
	await frames(12);await shot("faces")
	for actor in gallery:actor.queue_free()
	await frames(2)
	game.player.visible=true
	game.player.position=Vector3.ZERO
	game.player.facing=0;game.player.rotation.y=0
	game.camera.position=Vector3(0,2.35,5.5)
	game.camera.fov=32;game.camera.look_at(Vector3(0,1.43,0))
	await frames(16);await shot("hero_closeup")
	game.camera.position=Vector3(4.9,2.5,3.0)
	game.camera.look_at(Vector3(0,1.4,0))
	await frames(8);await shot("hero_profile")
	game.camera.position=Vector3(0,2.6,-5.4)
	game.camera.look_at(Vector3(0,1.4,0))
	await frames(8);await shot("hero_back")
	for hidden in hidden_scene:
		if is_instance_valid(hidden):
			hidden.visible=true
	game.world.visible=true
	photo_stage.queue_free()
	game.hud.root.visible=true
	game.camera.fov=43;game.player.position=Vector3(0,0,4);camera_reset()
	game.input_stick.axis=Vector2.LEFT
	for frame in range(22):
		game._process_player(.016);game._update_camera(.016);await process_frame
		if frame in [7,19]:await shot("walk_%d" % frame)
	game.input_stick._clear();game.move_velocity=Vector3.ZERO

	game.run.level=3;game.coins=3000;game._buy("lock");game._buy("alarm");game._buy("helper")
	game.counter["tomato"]=12;game.player.position=Vector3(4,0,5.5);camera_reset()
	game.run._spawn_raider(Vector3(20,0,-9))
	var raid: Dictionary=game.run.raiders[0]
	raid["actor"].position=Vector3(6.2,0,5);raid["actor"].facing=-1.0;raid["state"]="escape";raid["cargo"]="tomato";raid["amount"]=4;game.counter["tomato"]-=4
	raid["actor"].set_cargo_kind("tomato");raid["actor"].set_carry(4)
	game._refresh_ui();game.event_label.visible=false
	game.hud.rabbit_banner.lifetime=20;await frames(5);await shot("rabbit_robbery_alert")
	game._intercept();await frames(15);await shot("recovered")
	remove_raiders()

	game.coins=5000;game.run.level=5;game._buy("expand");game._buy("guard");game.run._tick_guard(.1)
	game.stash["apple"]=6;game.player.set_carry(6);game.player.position=Vector3(0,0,-10);camera_reset();game._refresh_ui();game.event_label.visible=false
	await shot("premium")
	game._toggle_shop();await shot("defenses");game._toggle_shop()

	game.player.position=Vector3(4,0,5);game.player.set_carry(0);camera_reset()
	game._buy("checkout");game.cash.pending[0]=180;game.cash.pending[1]=120
	game.cash._refresh_register(0);game.cash._refresh_register(1);game._refresh_ui();game.event_label.visible=false
	await shot("cash_money_stacks")
	game.player.position=game.cash.REGISTERS[0]+Vector3(0,0,1.5);game.player.facing=PI;camera_reset()
	game.cash.tick(.016);game._refresh_ui();await shot("cash_collection_flight")
	game.cash.tick(1.2);await shot("cash_collected")

	game.player.position=Vector3(0,0,18);game.cash.pending[0]=240;game.cash._refresh_register(0)
	game.cash.hire_collector();game.cash.collector.position=game.cash.REGISTERS[0]+Vector3(0,0,1)
	game.cash.tick(.016);game.cash.tick(.016);game.cash.tick(.9);game.cash.tick(.12)
	game.player.position=Vector3(4,0,5);camera_reset();game._refresh_ui();game.event_label.visible=false
	await frames(8);await shot("cash_rabbit_courier")

	game.coins=25000;game.run.level=5;game._toggle_build_mode()
	var buildings: Array=["house","cafe","depot","bakery","greenhouse","workshop","park","watchtower","mill"]
	for i in range(buildings.size()):
		game.town.select_at(game.town.LOCATIONS[i]);game.town.build(buildings[i])
	game.town.camera_center=Vector3(-16,0,2);game.town.select_at(game.town.LOCATIONS[0]);game._refresh_ui()
	for i in range(18):game._update_camera(.12);await process_frame
	await create_timer(2.6).timeout
	game.event_label.visible=false;await shot("town_overview")
	game.town.camera_center=Vector3(14,0,23)
	for i in range(20):game._update_camera(.12);await process_frame
	await shot("town_district")
	game._toggle_build_mode();game.player.position=Vector3(-2,0,7);camera_reset();game._refresh_ui();game.event_label.visible=false
	await shot("upgrade_stalls")
	game.run.level=7;game.run.activity_start={"orders":0,"rush":0,"patrol":0,"festival":0};game._refresh_ui()
	game.work.toggle_board();await shot("orders_board");game.work.close_board();game.work.accept("jam")
	game.counter["berry"]=3;game.counter["apple"]=2;game.player.position=game.work.station("jam");camera_reset()
	game.work.start_batch("jam");game.work.tick(12.1);game._refresh_ui();game.event_label.visible=false;await shot("production_ready")
	game.work.pickup("jam");game.player.position=game.work.DISPATCH+Vector3(.8,0,.8);camera_reset();game._refresh_ui();game.event_label.visible=false;await shot("crafted_delivery")
	game.work.deliver();game._refresh_ui();await shot("order_completed")
	game.queue_free();await process_frame;clear_review_save();quit(0)
