extends SceneTree

var game: Node3D
var output: String
func _initialize() -> void:call_deferred("capture")
func shot(name_: String) -> void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(name_+".png"))!=OK:quit(1); return
	print("PREVIEW: ",name_)
func camera_reset() -> void:
	game.camera_follow=game.player.position; game.camera_lead=Vector3.ZERO
	for i in range(8):game._update_camera(1)
func capture() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name()=="headless":quit(1); return
	output=args[0]; DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Main.tscn").instantiate(); game.save_path="user://wivori_visual_review7.json"
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path+suffix))
	root.add_child(game); game.set_process(false); game.world.set_process(false)
	camera_reset(); await shot("start")
	game.hud.root.visible=false
	var models: Array=[]
	game.player.visible=false
	for i in range(3):
		var actor: MarketActor=game.ActorScript.new(); actor.setup("customer",[Color("#3f9c99"),Color("#c391b1"),Color("#8191af")][i],["human","rabbit","raccoon"][i])
		game.add_child(actor); actor.position=Vector3((i-1)*1.65,0,2); models.append(actor)
	game.camera.position=Vector3(0,3.6,11); game.camera.fov=39; game.camera.look_at(Vector3(0,1.35,2),Vector3.UP)
	await shot("faces")
	for actor in models:actor.queue_free()
	game.player.visible=true; game.hud.root.visible=true; game.camera.fov=48
	game.player.set_process(false); game.player.position=Vector3(0,0,4); game.player.last_position=game.player.position; camera_reset()
	game.input_stick.axis=Vector2.RIGHT
	for frame in range(24):
		game._process_player(.016); game.player._process(.016); game._update_camera(.016)
		await process_frame
		if frame in [7,19]:await shot("walk_%d" % frame)
	game.input_stick._clear(); game.player.set_process(true)
	game.run.level=3; game.coins=2000
	game._buy("lock"); game._buy("alarm")
	game.player.position=Vector3(4,0,5); camera_reset()
	game.counter["tomato"]=8
	game.run._spawn_raider(Vector3(20,0,-9))
	var raid: Dictionary=game.run.raiders[0]
	raid["actor"].position=Vector3(4.8,0,4.6); raid["state"]="escape"; raid["cargo"]="tomato"; raid["amount"]=4; raid["actor"].set_carry(4)
	game._refresh_ui(); game.event_label.visible=false
	await shot("intercept")
	game._intercept(); await shot("recovered")
	for raid_ in game.run.raiders:raid_["actor"].queue_free()
	game.run.raiders.clear()
	game.run.level=4; game._buy("expand"); game._buy("guard")
	game.run._tick_guard(.1)
	game.stash["apple"]=6; game.player.set_carry(6); game.player.position=Vector3(0,0,-10)
	game._refresh_ui(); game.event_label.visible=false; camera_reset()
	await shot("premium")
	game._toggle_shop(); await shot("defenses")
	game.queue_free(); await process_frame; quit(0)
