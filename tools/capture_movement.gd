extends SceneTree

# Record actual running frames and touch gestures. Use --fixed-fps 12 to
# keep the movie's simulation and skeletal animation at the same timestep.
var game: Node3D
var output: String
var path: String="user://refuge_motion_capture_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func point(axis: Vector2=Vector2.ZERO) -> Vector2:return game.stick.get_global_transform_with_canvas()*(game.stick.size*.5+axis*65)
func press(at: Vector2,down: bool,index: int=2) -> void:
	var event:=InputEventScreenTouch.new();event.position=at;event.index=index;event.pressed=down;root.push_input(event,true)
func drag(axis: Vector2) -> void:
	var event:=InputEventScreenDrag.new();event.index=2;event.position=point(axis);root.push_input(event,true)
func run() -> void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().is_empty():quit(1);return
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Refuge.tscn").instantiate();game.save_path=path;game.saving_enabled=false;root.add_child(game)
	for index in range(6):await process_frame
	var action_at: Vector2=game.ui.task_button.get_global_transform_with_canvas()*(game.ui.task_button.size*.5)
	press(action_at,true,7);await process_frame;press(action_at,false,7);await process_frame
	game.center_camera();press(point(),true)
	var start: Vector3=game.hero.position;var distance:=0.0;var previous:=start
	for frame in range(48):
		match frame:
			8:drag(Vector2.DOWN)
			16:drag(Vector2.LEFT)
			24:drag(Vector2.UP)
			32:drag(Vector2.RIGHT)
			40:press(point(),false)
		await process_frame;await RenderingServer.frame_post_draw
		distance+=game.hero.position.distance_to(previous);previous=game.hero.position
		if root.get_texture().get_image().save_png(output.path_join("frame_%03d.png" % frame))!=OK:quit(1);return
	print("MOVEMENT RECORDING: ",distance," world metres from real touch gestures; start ",start,"; end ",game.hero.position)
	game.queue_free();await process_frame;await process_frame;await create_timer(.1).timeout
	quit()
