extends SceneTree
func _initialize() -> void:call_deferred("review")
func review() -> void:
	var game=load("res://Main.tscn").instantiate();game.save_path="user://wivori_light_review.json";root.add_child(game);game.set_process(false)
	var env: Environment=game.get_node("WivoriEnvironment").environment
	var sun: DirectionalLight3D
	for child in game.get_children():
		if child is DirectionalLight3D:sun=child
	var out:=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	for mode in [Environment.TONE_MAPPER_LINEAR,Environment.TONE_MAPPER_FILMIC,Environment.TONE_MAPPER_AGX]:
		env.tonemap_mode=mode
		for frame in range(6):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("mode_%d.png" % mode))
	game.queue_free();await process_frame;quit()
