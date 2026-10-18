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
	game._toggle_shop()
	await shot("upgrades")
	game._toggle_shop()
	game.coins=2000
	game._buy("helper")
	game._buy("helper")
	game._buy("expand")
	game._buy("pier")
	game.counter["tomato"]=18
	game.counter["apple"]=9
	game._process_shipping(1)
	game._refresh_ui()
	game.event_label.visible=false
	await shot("expanded")
	game.queue_free()
	await process_frame
	quit(0)
