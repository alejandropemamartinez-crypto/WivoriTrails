extends SceneTree
var game: Node3D
var output: String
var save_path: String="user://wivori_polish_capture_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("capture")
func frames(n: int) -> void:
	for i in range(n):await process_frame
func shot(name_: String) -> void:
	await frames(5);await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(name_+".png"))!=OK:quit(1);return
	print("PREVIEW: ",name_)
func camera(at: Vector3) -> void:
	game.player.position=at;game.camera_follow=at;game.camera_lead=Vector3.ZERO;game._update_camera(1);game._refresh_ui()
func capture() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name()=="headless":quit(1);return
	output=args[0];DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Main.tscn").instantiate();game.save_path=save_path;root.add_child(game);game.set_process(false);game.world.set_process(false)
	camera(Vector3(0,0,4));game.milestone.announce("review:journal","Tu red de pueblos","Las novedades se abren solamente cuando tocás NOVEDADES en el mapa.");game.milestone.show_next();await shot("01_diario_voluntario")
	game.milestone.dismiss();game.milestone.pending.clear();await shot("02_mercado_carteles")
	game.cash.pending[0]=180;game.cash._refresh_register(0);camera(Vector3(5,0,3));await shot("03_caja_entregar")
	camera(Vector3(-3,0,10));await shot("04_tesoreria_avenida")
	game.hud.root.visible=false;game.player.visible=false
	var cast: Array[MarketActor]=[]
	for i in range(5):
		var a: MarketActor=game.ActorScript.new();a.setup("customer",[Color("#549d99"),Color("#d79968"),Color("#779cae")][i%3],["fox","pig","duck","rabbit","raccoon"][i]);game.add_child(a);a.position=Vector3((i-2)*1.25,0,45);cast.append(a)
	game.camera.position=Vector3(0,3.3,55);game.camera.fov=47;game.camera.look_at(Vector3(0,1.4,45));await shot("05_npc_distintos")
	for a in cast:a.queue_free()
	game.player.visible=true;game.player.position=Vector3(0,0,45);game.player.facing=-.14;game.player.rotation.y=-.14
	game.camera.position=Vector3(.35,2.55,50.2);game.camera.fov=34;game.camera.look_at(Vector3(0,1.23,45));await shot("00_hero_closeup")
	game.hud.root.visible=true;game.camera.fov=43
	game.coins=20000;game.run.level=6;game.pier_owned=true;game.world.open_pier();game.route.ferry=true
	camera(game.route.HOME_DOCK+Vector3(-2,0,-1));await shot("06_barco_wivori")
	game.route.open_board();await shot("07_mapa_ruta");game.route.close_board()
	game.route._arrive(1);game.milestone.pending.clear();game.milestone.cover.visible=false
	for i in range(4):
		var p: Dictionary=game.route.PROJECTS[i];game.route.built.append(p["id"]);game.route._place_project(p,false)
	game.route.stage=4;game.route._make_wheat();game.route._update_project_marker()
	camera(Vector3(-10,0,-8));await shot("08_campos_trigo")
	camera(Vector3(1,0,-5));await shot("09_panaderia_gallinas")
	game.route.jobs["bread"]={"remaining":0.0,"ready":4};game.route.employees["bread"]=true;game.route._spawn_operator("bread");game.route.tick(.01)
	camera(game.route.station("bread")+Vector3(0,0,2));await shot("10_pan_listo")
	game.route.board_tab=1;game.route.open_board();await shot("11_recetas_carga");game.route.close_board()
	game.route.stage=9;game.route.built.clear()
	for i in range(9):game.route.built.append(game.route.PROJECTS[i]["id"])
	game.route._arrive(2);camera(Vector3(-7,0,-5));await shot("12_granja_vacas")
	camera(Vector3(8,0,-5));await shot("13_queseria_cerdos")
	game.route.stage=14;game.route.built.clear()
	for i in range(14):game.route.built.append(game.route.PROJECTS[i]["id"])
	game.route._arrive(3);camera(Vector3(1,0,11));await shot("14_faro_final")
	game.route.stage=15;game.route.built.append("festival");game.milestone.pending.clear()
	game.milestone.announce("capture:finish","¡La Ruta del Faro está completa!","Wivori, Villa Miga, Puerto Nata y Bahía Farol vuelven a estar conectados. Tus pueblos quedan abiertos para mejorar talleres y comerciar.","boat","","¡LO LOGRASTE!");game.milestone.show_next();await shot("15_ruta_completada")
	game.queue_free();await frames(2)
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	quit()
