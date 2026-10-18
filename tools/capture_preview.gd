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
	review_save="user://wivori_visual_v013_%d.json" % OS.get_process_id();clear_review_save()
	seed(20261018)
	game=load("res://Main.tscn").instantiate();game.save_path=review_save;root.add_child(game)
	game.set_process(false);game.world.set_process(false)
	camera_reset();await shot("start")

	game.hud.root.visible=false;game.player.visible=false
	var gallery: Array[MarketActor]=[]
	for i in range(3):
		var actor: MarketActor=game.ActorScript.new();actor.setup("customer",[Color("#4c9992"),Color("#d49f68"),Color("#70899b")][i],["scottie","rabbit","raccoon"][i]);game.add_child(actor)
		actor.position=Vector3((i-1)*1.65,0,20);gallery.append(actor)
	game.camera.position=Vector3(0,3.25,27);game.camera.fov=42;game.camera.look_at(Vector3(0,1.30,20))
	await shot("faces")
	for actor in gallery:actor.queue_free()
	game.player.visible=true;game.player.position=Vector3(0,0,18);game.player.facing=-.13;game.player.rotation.y=-.13
	game.camera.position=Vector3(.30,2.5,23.5);game.camera.fov=34;game.camera.look_at(Vector3(0,1.22,18))
	await frames(14);await shot("scottish_terrier_closeup")
	game.hud.root.visible=true;game.camera.fov=43;game.player.position=Vector3(0,0,4);camera_reset()
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
	await frames(20);await shot("rabbit_robbery_alert")
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
	game.queue_free();await process_frame;clear_review_save();quit(0)
