extends SceneTree

func _initialize() -> void:call_deferred("render_cards")

func render_cards() -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	var viewport:=SubViewport.new();viewport.size=Vector2i(300,260);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var environment:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color(0,0,0,0)
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("#d8e3e8");settings.ambient_light_energy=.60
	environment.environment=settings;viewport.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-32,0);sun.light_energy=.52;sun.light_color=Color("#fff3e5");viewport.add_child(sun)
	var camera:=Camera3D.new();viewport.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=8.2;camera.position=Vector3(7,6,10);camera.look_at(Vector3(0,1.7,0));camera.current=true
	DirAccess.make_dir_recursive_absolute("res://assets/ui/buildings")
	for kind in ["house","cafe","depot","bakery","greenhouse","workshop","park","watchtower","mill"]:
		var stage:=Node3D.new();viewport.add_child(stage)
		var model=preload("res://scripts/art_library.gd").place(stage,kind)
		for frame in range(8):await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://assets/ui/buildings/"+kind+".png")
		stage.queue_free();await process_frame
	print("THUMBNAILS: nine actual model renders")
	viewport.queue_free();await process_frame;quit()
