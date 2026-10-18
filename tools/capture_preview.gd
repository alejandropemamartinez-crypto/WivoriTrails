extends SceneTree

# Run with a real rendering driver (for example xvfb-run), never --headless.
# Preview scenes use their own save file, outside the player's normal progress.
var game: Node3D
var output := ""

func _initialize() -> void:
	call_deferred("capture")

func shot(name_: String) -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(output.path_join(name_ + ".png"))
	if result != OK:
		push_error("Could not capture " + name_)
		quit(1)
	print("PREVIEW: ",name_)

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Pass an output directory and use a rendering display server")
		quit(1)
		return
	output=args[0]
	DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Main.tscn").instantiate()
	game.save_path="user://wivori_visual_preview.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path+suffix))
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	for i in range(8): game._update_camera(1.0)
	await shot("start")
	game.coins=80
	game.director.tick(.2)
	game._refresh_ui()
	await shot("affordable")
	game._follow_objective()
	for i in range(100):
		game._process_player(.05); game._update_camera(.05)
	game._refresh_ui()
	game.event_label.visible=false
	await shot("hire_here")
	game._purchase_nearby()
	for i in range(60):game._process_helpers(.1)
	game.coins=200
	game.player.position=Vector3(7,0,5)
	for i in range(6):game._spawn_customer()
	for i in range(100):game._process_customers(.1)
	game.camera_follow=game.player.position
	for i in range(8):game._update_camera(1.0)
	game._refresh_ui(); game.event_label.visible=false
	await shot("empty_queue")
	game.counter["tomato"]=60
	game._refresh_ui()
	await shot("busy_queue")
	game._toggle_shop()
	await shot("upgrades")
	game._toggle_shop()
	game.coins=2000
	game._buy("helper")
	game._buy("checkout")
	game._buy("expand")
	game._buy("pier")
	game.counter["tomato"]=18
	game.counter["apple"]=9
	game._process_shipping(1)
	game.player.position=Vector3(0,0,4)
	game.camera_follow=game.player.position
	for i in range(8):game._update_camera(1.0)
	game._refresh_ui()
	game.event_label.visible=false
	await shot("expanded")
	game.queue_free()
	await process_frame
	quit(0)
