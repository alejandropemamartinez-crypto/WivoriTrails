extends SceneTree

func _initialize() -> void:call_deferred("render_models")

func render_models() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name()=="headless":quit(1);return
	var game=load("res://Main.tscn").instantiate()
	game.save_path="user://wivori_art_gallery_transient.json"
	root.add_child(game)
	game.set_process(false)
	game.hud.root.visible=false
	game.player.visible=false
	for i in range(3):
		var actor=game.ActorScript.new()
		actor.setup("customer",Color("#509b96"),["scottie","rabbit","raccoon"][i])
		game.add_child(actor)
		actor.position=Vector3((i-1)*1.65,0,20)
		actor.rotation.y=-.16
		actor.facing=-.16
	game.camera.position=Vector3(0,3.4,26.8)
	game.camera.fov=42
	game.camera.look_at(Vector3(0,1.25,20))
	for frame in range(20):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0])
	game.queue_free()
	await process_frame
	quit()
