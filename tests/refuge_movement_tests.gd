extends SceneTree

# Exercise the same press / drag / release events as a phone. Do not assign
# joystick.axis: that bypassed the disabled control in the previous tests.
var viewport: SubViewport
var game: Node3D
var checks:=0
var failures:=0
var output:=""
var path: String="user://refuge_movement_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)
func frames(count: int=3) -> void:
	for index in range(count):await process_frame
func touch(point: Vector2,down: bool,index: int=2,canceled: bool=false) -> void:
	var event:=InputEventScreenTouch.new();event.position=point;event.index=index;event.pressed=down;event.canceled=canceled
	viewport.push_input(event,true);await process_frame
func drag(point: Vector2,index: int=2) -> void:
	var event:=InputEventScreenDrag.new();event.position=point;event.index=index;viewport.push_input(event,true);await process_frame
func stick_point(axis: Vector2=Vector2.ZERO,extent: float=65) -> Vector2:
	return game.stick.get_global_transform_with_canvas()*(game.stick.size*.5+axis*extent)
func hold(axis: Vector2,index: int=2,extent: float=65) -> void:
	await touch(stick_point(),true,index);await drag(stick_point(axis,extent),index)
func release(index: int=2,canceled: bool=false) -> void:await touch(stick_point(),false,index,canceled)
func advance(seconds: float) -> void:
	var remaining:=seconds
	while remaining>.0001:
		var step: float=minf(.05,remaining);game._process(step);remaining-=step
	game.set_process(false);await frames(2)
func tap(button: Control,index: int=7) -> void:
	var at: Vector2=button.get_global_transform_with_canvas()*(button.size*.5)
	await touch(at,true,index);await touch(at,false,index);await frames(2)
func visible_button(text: String) -> Button:
	for node in game.ui.root.find_children("*","Button",true,false):
		if node.text==text and node.is_visible_in_tree():return node
	return null
func shot(name_: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await frames();await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(output.path_join(name_+".png"))==OK,"Native movement capture: "+name_)
func ground_point() -> Vector2:
	for y in range(300,660,40):
		for x in range(250,550,40):
			var point:=Vector2(x,y);var blocked:=false
			for node in game.ui.root.find_children("*","Control",true,false):
				if node.is_visible_in_tree() and node.mouse_filter==Control.MOUSE_FILTER_STOP and node.get_global_rect().has_point(point):blocked=true;break
			if not blocked:return point
	return Vector2(360,300)
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	viewport=SubViewport.new();viewport.size=Vector2i(720,1280);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	game=load("res://Refuge.tscn").instantiate();game.save_path=path;game.saving_enabled=false;viewport.add_child(game);game.set_process(false)
	await frames(5)
	check(game.stick.is_visible_in_tree(),"A fresh install exposes movement without opening a menu")
	var before: Vector3=game.hero.position
	await hold(Vector2.RIGHT);await advance(.4);await release()
	check(game.hero.position.distance_to(before)>1.8,"A real first-launch thumb gesture moves the protagonist")
	# Stop the old build here: the remaining cases require the corrected
	# controls, rather than enabling its hidden optional mode in the test.
	if failures>0:await finish();return
	await shot("01_joystick_visible")
	for height in [1280,1600]:
		viewport.size=Vector2i(720,height);await frames(4)
		game.ui.close();game.center_camera();game.ui.refresh(0);await frames(3)
		check(not game.stick.get_global_rect().intersects(game.ui.task_card.get_global_rect()),"Joystick and objective have separate touch areas at height "+str(height))
		check(not game.stick.get_global_rect().intersects(game.ui.route_button.get_global_rect()),"The route button never covers the joystick at height "+str(height))
		for axis in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2(1,1).normalized(),Vector2(1,-1).normalized(),Vector2(-1,1).normalized(),Vector2(-1,-1).normalized()]:
			game.hero.position=Vector3(0,0,5.2);game.center_camera();game._camera(1);before=game.hero.position
			await hold(axis);await advance(.25)
			check(game.hero.position.distance_to(before)>1.4,"Thumb drag moves consistently in direction %s at height %d" % [axis,height])
			await release();before=game.hero.position;await advance(.2)
			check(game.hero.position==before and game.stick.axis==Vector2.ZERO,"Releasing the actual finger stops movement immediately")
	game.hero.position=Vector3(0,0,5.2);game.center_camera();game._camera(1)
	await hold(Vector2.RIGHT,2,34);before=game.hero.position;await advance(.2);await release()
	check(game.hero.position.distance_to(before)>.2 and game.hero.position.distance_to(before)<.9,"A short thumb displacement gives controlled analog walking")
	await hold(Vector2.RIGHT);await touch(Vector2(5,5),true,9);await touch(Vector2(5,5),false,9)
	check(game.stick.active_finger==2 and game.stick.axis.length()>.9,"Another finger's release cannot cancel the movement finger")
	await release(2,true);before=game.hero.position;await advance(.2)
	check(game.hero.position==before and game.stick.active_finger==-1,"A canceled Android touch releases movement cleanly")
	await hold(Vector2.RIGHT,2,240);before=game.hero.position;await advance(.2);await release()
	check(game.hero.position.distance_to(before)>1,"A held joystick keeps its finger when dragged outside the visible pad")
	await hold(Vector2.RIGHT);before=game.hero.position;await advance(.2);var normal_distance: float=game.hero.position.distance_to(before);await release()
	game.hero.position=Vector3(0,0,5.2);game.center_camera()
	await hold(Vector2.RIGHT);var run_point: Vector2=game.ui.run_button.get_global_transform_with_canvas()*(game.ui.run_button.size*.5)
	await touch(run_point,true,8);before=game.hero.position;await advance(.2)
	check(game.hero.position.distance_to(before)>normal_distance*1.15 and game.sprinting,"A second finger can hold RUN while the first steers")
	await touch(run_point,false,8);check(not game.sprinting and game.stick.active_finger==2,"Releasing RUN preserves steering and returns to normal speed")
	await release()
	# Open and close a sheet while the first finger remains physically held.
	await hold(Vector2.RIGHT);await tap(game.ui.nav_buttons["team"]);before=game.hero.position;await advance(.2)
	check(game.ui.modal.visible and not game.stick.visible and game.stick.axis==Vector2.ZERO,"Opening a panel suspends and hides movement controls immediately")
	check(game.hero.position==before,"The character cannot walk underneath an open sheet")
	await tap(visible_button("×"));before=game.hero.position;await advance(.2)
	check(game.stick.visible and game.hero.position==before,"Closing a panel restores the joystick without reviving an old held finger")
	await release();await hold(Vector2.DOWN);before=game.hero.position;await advance(.2);await release()
	check(game.hero.position.distance_to(before)>1,"Movement works again on the very next fresh gesture")
	# Ground dragging changes only the camera; walking returns it to the hero.
	var point: Vector2=ground_point();before=game.hero.position;var old_focus: Vector3=game.focus
	await touch(point,true,5);await drag(point+Vector2(90,65),5);await touch(point+Vector2(90,65),false,5);await advance(.2)
	check(game.focus.distance_to(old_focus)>2 and game.camera_detached,"Dragging the terrain pans the camera from the normal play view")
	check(game.hero.position==before,"Panning the camera never sends the hero to a destination")
	# A pinch must not become a tap, or jump when only one finger remains.
	point=ground_point();var second: Vector2=point+Vector2(70,0);var previous_zoom: float=game.zoom
	await touch(point,true,5);await touch(second,true,6);await drag(second+Vector2(45,0),6)
	check(game.zoom<previous_zoom and not game.ui.modal.visible,"Two world fingers zoom the camera without opening a building")
	await touch(point,false,5);old_focus=game.focus
	await drag(second+Vector2(46,0),6)
	check(game.focus.distance_to(old_focus)<.15,"Lifting one pinch finger does not make the remaining finger jump the camera")
	await touch(Vector2(5,5),false,11)
	check(game.fingers.has(6),"A release from an unrelated finger cannot cancel the camera gesture")
	await touch(second+Vector2(46,0),false,6)
	check(not game.ui.modal.visible and game.hero.position==before,"Finishing a pinch does not activate a hidden tap or move the protagonist")
	await hold(Vector2.DOWN);await advance(.2);await release()
	check(not game.camera_detached and game.focus.distance_to(game.hero.position)<2,"Starting to walk returns the camera to the moving hero")
	before=game.hero.position;await tap(game.ui.camera_button);await advance(.2)
	check(game.camera_overview and game.stick.visible and game.hero.position==before,"The town overview keeps the movement control available")
	await hold(Vector2.LEFT);await advance(.2);await release()
	check(not game.camera_overview and not game.camera_detached,"Walking exits the overview automatically without an extra mode switch")
	await tap(game.ui.nav_buttons["home"]);check(game.stick.visible,"The visible center button never disables movement")
	# Canvas transforms stand in for the viewport stretch used by real phones.
	viewport.canvas_transform=Transform2D.IDENTITY.scaled(Vector2(.85,.85));await frames(3)
	before=game.hero.position;await hold(Vector2.DOWN);await advance(.2);await release()
	check(game.hero.position.distance_to(before)>1,"Screen-space touch coordinates still steer correctly under canvas scaling")
	viewport.canvas_transform=Transform2D.IDENTITY;await frames(3)
	# Collision and recovery use the actual pad and the live navigation mesh.
	game.hero.position=Vector3(0,0,2.8);game.center_camera();game._camera(1)
	var right: Vector3=game.camera.global_basis.x;right.y=0;right=right.normalized()
	var forward: Vector3=game.camera.global_basis.z;forward.y=0;forward=forward.normalized()
	var toward:=Vector3(0,0,-1);var screen_axis:=Vector2(toward.dot(right),toward.dot(forward))
	await hold(screen_axis);await advance(.8);await release()
	check(game.navigation.is_walkable(game.hero.position,.25) and game.hero.position.z>2.20,"A held stick cannot walk through the central building")
	before=game.hero.position;await hold(-screen_axis);await advance(.3);await release()
	check(game.hero.position.distance_to(before)>1.6,"The hero can immediately move away after colliding with a wall")
	await shot("02_movimiento_manual")
	game.state.unlocked=5
	for area in range(6):
		if area!=game.state.city:game.travel(area)
		await frames(3);before=game.hero.position
		await hold(Vector2.RIGHT);await advance(.25);await release()
		check(game.stick.visible and game.hero.position.distance_to(before)>1.4,"Manual movement remains available in "+game.state.NAMES[area])
	# Pausing saves the actual player position and clears every active finger.
	game.saving_enabled=true;before=game.hero.position
	await hold(Vector2.DOWN);game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.stick.axis==Vector2.ZERO and not game.sprinting,"Android pause clears movement and run state immediately")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED);game.set_process(false);await frames(3)
	check(game.stick.visible and game.hero.position.distance_to(before)<.05,"Android resume restores the player's position with the joystick available")
	await release();await hold(Vector2.LEFT);before=game.hero.position;await advance(.2);await release()
	check(game.hero.position.distance_to(before)>1,"The first fresh touch after Android resume moves normally")
	await shot("03_despues_de_reanudar")
	await finish()
func finish() -> void:
	game.queue_free();await frames(2);viewport.queue_free();await frames(2);await create_timer(.1).timeout
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d refuge movement checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
