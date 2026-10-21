extends SceneTree

# Native, reproducible screenshots of prepared review saves. No mockups.
var game: Node3D
var output: String
var save_path: String="user://wivori_campaign_capture_%d.json" % OS.get_process_id()

func _initialize() -> void:call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):await process_frame
func shot(title: String) -> void:
	await frames(5);await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(title+".png"))!=OK:quit(1);return
	print("PREVIEW: ",title)
func camera(at: Vector3) -> void:
	game.player.position=at;game.camera_follow=at;game.camera_lead=Vector3.ZERO
	game._update_camera(1);game._refresh_ui()
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name()=="headless":quit(1);return
	output=args[0];DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Main.tscn").instantiate();game.save_path=save_path;root.add_child(game)
	game.set_process(false);game.world.set_process(false)
	camera(Vector3(0,0,4));await shot("01_mercado_control_manual")
	game.run.level=4;camera(Vector3(0,0,-9));game.world.update_security(game.run)
	await shot("02_pedidos_x2")
	game.coins=38000;game.run.level=12;game.route.ferry=true;game.route.access_floor=5
	game.route.stage=game.route.PROJECTS.size();game.route.industry_stage=game.route.INDUSTRY_PROJECTS.size()
	game.route.aurora_stage=game.route.AURORA_PROJECTS.size();game.route.industry_orders_done=6
	for project in game.route.PROJECTS+game.route.INDUSTRY_PROJECTS+game.route.AURORA_PROJECTS:
		game.route.built.append(project["id"])
	for key in game.route.RECIPES:game.route.employees[key]=false;game.route.mastery[key]=3
	for region in range(1,6):
		game.route._arrive(region)
		camera(Vector3(-5,0,-5) if region in [1,2] else Vector3(0,0,10) if region==3 else Vector3(0,0,-5))
		await shot("0%d_%s" % [region+2,["villa_miga","puerto_nata","bahia_farol","distrito_forja","puerto_aurora"][region-1]])
	game.route.board_tab=2;game.route.open_board();await shot("08_rutas_expedicion");game.route.close_board()
	game.route.inventory["kits"]=3;game.route.inventory["bread"]=6;game.player.position=game.route.MARKET
	game.route.start_expedition(0);game.route.tick(.1);camera(Vector3(10,0,12))
	await shot("09_astillero_en_viaje")
	game.route._arrive(0);game.hud.root.visible=false;game.player.set_process(false)
	game.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	game.player.position=Vector3(0,0,45);game.player.rotation.y=0
	# The review teleports a frozen actor; apply the new ground height rather
	# than preserving the previous island's smoothed vertical offset.
	game.player.ground_offset=game.world.ground_height(game.player.position)
	game.player.body_root.position.y=game.player.ground_offset
	game.player.contact_shadow.position.y=game.player.ground_offset+.025
	for view in [{"id":"10_hero_frente","at":Vector3(0,2.55,50.2)},{"id":"11_hero_perfil","at":Vector3(5.2,2.55,45)},{"id":"12_hero_espalda","at":Vector3(0,2.55,39.8)}]:
		game.camera.position=view["at"];game.camera.fov=34;game.camera.look_at(Vector3(0,1.23,45))
		await shot(view["id"])
	game.camera.position=Vector3(3,2.55,49.5);game.camera.look_at(Vector3(0,1.23,45))
	for clip in ["walk","run","carry","harvest","deliver","celebrate"]:
		game.player.animator.play(clip);game.player.animator.seek(.22,true)
		await shot("13_anim_"+clip)
	game.queue_free();await frames(2)
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	quit(0)
