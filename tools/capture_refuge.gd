extends SceneTree

# Prepared states show the real running 3D scene. Economy progression is
# verified separately by refuge_economy_tests, without these visual fixtures.
var game: Node3D
var output: String
var path: String="user://refuge_capture_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func frames(count: int) -> void:
	for index in range(count):await process_frame
func shot(name_: String) -> void:
	game.ui.refresh(0);game._camera(1);game._placards();await frames(4);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name_+".png"))
	print("REFUGE_CAPTURE: ",name_," · draws ",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
func run() -> void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().is_empty():quit(1);return
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Refuge.tscn").instantiate();game.save_path=path;root.add_child(game);game.set_process(false)
	await frames(6);await shot("01_nuevo_refugio")
	game.state.ignite();game._replace_model("core");game.ground.set_shader_parameter("warmth",1.0);game.core_light.visible=true;game.ui.toast_time=0
	await shot("02_encender")
	game.ui.show_building("lumber");await shot("03_aserradero")
	game.ui.close();game.state.resources={"wood":480.0,"food":225.0,"coal":165.0,"iron":90.0}
	for id in ["core","shelter","lumber","kitchen","coal","mine","clinic","watch"]:game.state.town()["levels"][id]=3
	game.state.town()["levels"]["core"]=5;game.state.town()["people"]=12
	for id in ["lumber","kitchen","coal","mine"]:game.state.town()["workers"][id]=2
	game.state.town()["storms"]=1;game._build_world();game.ground.set_shader_parameter("warm_radius",11.3);game.ground.set_shader_parameter("warmth",1.0)
	game.show_overview();await shot("04_pueblo")
	game.ui.show_team();await shot("05_equipo")
	game.ui.show_route();await shot("06_siguiente_refugio")
	game.ui.close();game.state.unlocked=4;game.state.city=4
	for id in game.state.BUILDINGS:game.state.town()["levels"][id]=3
	game.state.town()["levels"]["core"]=7;game.state.town()["people"]=16
	game._build_world();game.ground.set_shader_parameter("warm_radius",13.3);game.ground.set_shader_parameter("warmth",1.0);game.show_overview();await shot("07_distrito_forja")
	game.state.town()["storm_clock"]=130;game.ui.show_building("core");await shot("08_calefaccion")
	game.ui.close();game.ui.show_fleet();await shot("09_expediciones")
	game.queue_free();await frames(2);await create_timer(.08).timeout
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	quit()
