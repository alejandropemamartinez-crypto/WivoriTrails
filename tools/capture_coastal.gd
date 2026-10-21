extends SceneTree

# Captures the running game, using an isolated save and the production camera.
# Optional second argument chooses the first shot; useful for quick iteration.
var game: Node3D
var output: String
var save_path: String="user://wivori_coastal_capture_%d.json" % OS.get_process_id()

func _initialize() -> void:call_deferred("capture")
func frames(count: int) -> void:
	for i in range(count):await process_frame
func camera(at: Vector3) -> void:
	game.player.position=at;game.player.last_position=at
	game.player.ground_offset=game.world.ground_height(at) if not game.route.away() else game.route.ground_height(at)
	game.player.body_root.position.y=game.player.ground_offset
	game.player.contact_shadow.position.y=game.player.ground_offset+.025
	game.camera_follow=at;game.camera_lead=Vector3.ZERO;game._update_camera(1);game._refresh_ui()
func shot(id_: String) -> void:
	await frames(4);await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(id_+".png"))!=OK:quit(1);return
	print("CAPTURE: ",id_)
	print("CAPTURE_DRAW_CALLS: ",id_," ",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
func capture() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name()=="headless":quit(1);return
	output=args[0];DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Main.tscn").instantiate();game.save_path=save_path;root.add_child(game)
	print("CAPTURE: scene instantiated")
	game.set_process(false);game.world.set_process(false)
	if args.size()>2 and args[2]=="ortho":game.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;game.camera.size=17.5
	await frames(4)
	print("CAPTURE: render warmup finished")
	camera(Vector3(0,0,4));await shot("01_mercado")
	if args.size()>1 and args[1]=="quick":await finish();return
	camera(Vector3(-8,0,-4));await shot("02_huertos")
	game.coins=213;game.run.level=3
	game.run._spawn_raider(Vector3(20,0,-9));game._refresh_ui();await shot("03_aviso_defensa")
	game.run.raiders[0]["actor"].queue_free();game.run.raiders.clear();game.run.warning=0
	game.hud.rabbit_banner._finish();game.event_label.visible=false
	camera(game.UPGRADE_POS["helper"]);await shot("04_contratar")
	game.coins=38000;game.run.level=12;game.route.ferry=true;game.route.access_floor=5
	game.route.stage=game.route.PROJECTS.size();game.route.industry_stage=game.route.INDUSTRY_PROJECTS.size();game.route.aurora_stage=game.route.AURORA_PROJECTS.size();game.route.industry_orders_done=6
	for project in game.route.PROJECTS+game.route.INDUSTRY_PROJECTS+game.route.AURORA_PROJECTS:game.route.built.append(project["id"])
	for key in game.route.RECIPES:game.route.employees[key]=false;game.route.mastery[key]=3
	for region in [1,2,4,5]:
		game.route._arrive(region);camera(Vector3(0,0,-5));await shot("0%d_%s" % [region+4,["","villa_miga","puerto_nata","","distrito_forja","puerto_aurora"][region]])
	await finish()
func finish() -> void:
	game.queue_free();await frames(2)
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	quit()
