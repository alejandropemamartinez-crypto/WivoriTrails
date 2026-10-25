extends SceneTree

# Real running frames, fixed 12 Hz, with actual thumb events. The final clip
# restores the ordinary, earned save produced by refuge_trade_touch_tests.
# There are cuts between activities; no game currency or actors are granted.
var game: Node3D
var output: String
var checkpoint: String
var frame_number:=0
var path: String="user://trade_movie_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func touch(at: Vector2,down: bool,index: int=2) -> void:
	var event:=InputEventScreenTouch.new();event.position=at;event.pressed=down;event.index=index;root.push_input(event,true)
func drag(axis: Vector2) -> void:
	var event:=InputEventScreenDrag.new();event.position=center(game.stick)+axis*65;event.index=2;root.push_input(event,true)
func center(control: Control) -> Vector2:return control.get_global_transform_with_canvas()*(control.size*.5)
func frames(count: int,record: bool=false) -> void:
	for index in range(count):
		await process_frame
		if record:
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(output.path_join("frame_%03d.png" % frame_number))!=OK:quit(1);return
			frame_number+=1
func walk_to(at: Vector3) -> void:
	var path_: PackedVector3Array=game.navigation.find_path(game.hero.position,at)
	touch(center(game.stick),true)
	for target in path_:
		var remaining:=100
		while game.hero.position.distance_to(target)>.40 and remaining>0:
			remaining-=1
			var difference: Vector3=(target-game.hero.position).normalized()
			var right: Vector3=game.camera.global_basis.x;right.y=0;right=right.normalized()
			var down: Vector3=game.camera.global_basis.z;down.y=0;down=down.normalized()
			drag(Vector2(difference.dot(right),difference.dot(down)));await process_frame
	touch(center(game.stick),false);await frames(3)
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless" or args.size()<2:quit(1);return
	output=args[0];checkpoint=args[1];DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Refuge.tscn").instantiate();game.save_path=path;game.saving_enabled=false;root.add_child(game);await frames(5)
	touch(center(game.ui.task_button),true,7);await process_frame;touch(center(game.ui.task_button),false,7);await frames(2)
	await walk_to(game.market.TREE_POSITIONS[0]+Vector3(0,0,1.5))
	touch(center(game.ui.work_button),true,8);await frames(18,true);touch(center(game.ui.work_button),false,8)
	await walk_to(game.market.COUNTERS["wood"])
	touch(center(game.ui.work_button),true,8);await frames(24,true);touch(center(game.ui.work_button),false,8)
	await walk_to(game.market.BEAR_POSITIONS[0]+Vector3(0,0,-1.5))
	touch(center(game.ui.work_button),true,8);await frames(24,true);touch(center(game.ui.work_button),false,8)
	if game.market.bag["meat"]!=6 or game.market.coins<=0:push_error("The recorded manual harvest/sale did not complete");quit(1);return
	print("RECORDED MANUAL LOOP: ",game.market.coins," earned coins; ",game.market.bag["meat"]," carried meat")
	game.queue_free();await frames(3)
	game=load("res://Refuge.tscn").instantiate();game.save_path=checkpoint;game.saving_enabled=false;root.add_child(game);await frames(5)
	if not game.market.operating(0):push_error("The earned playthrough checkpoint has no running train");quit(1);return
	game.show_overview();await frames(10);await frames(72,true)
	print("RECORDED TRADE MOVIE: ",frame_number," unaltered native frames; automated playthrough checkpoint")
	game.queue_free();await frames(3);await create_timer(.1).timeout;quit()
