extends SceneTree

# Run the real scene's frame loop. Only joystick touch/drag/release events
# move the hero; no direct _process calls, hero teleports or work taps.
var game: Node3D
var checks:=0
var failures:=0
var hits:=0
var animation_restarts:=0
var last_animation_position:=-1.0
var output:=""
var path: String="user://refuge_auto_runtime_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)
func frames(count: int) -> void:
	for index in range(count):
		await process_frame
		if game.hero.current_clip=="harvest" and game.hero.animator!=null:
			var current: float=game.hero.animator.current_animation_position
			if last_animation_position>=0 and current+.02<last_animation_position:animation_restarts+=1
			last_animation_position=current
		else:last_animation_position=-1
func center(control: Control) -> Vector2:return control.get_global_transform_with_canvas()*(control.size*.5)
func advance(seconds: float) -> void:
	var deadline: float=game.elapsed+seconds
	while game.elapsed<deadline:await frames(1)
func touch(down: bool) -> void:
	var event:=InputEventScreenTouch.new();event.position=center(game.stick);event.pressed=down;event.index=2;root.push_input(event,true)
func steer(axis: Vector2) -> void:
	var event:=InputEventScreenDrag.new();event.position=center(game.stick)+axis*65;event.index=2;root.push_input(event,true)
func walk_to(at: Vector3) -> bool:
	var route: PackedVector3Array=game.navigation.find_path(game.hero.position,at)
	touch(true);await frames(1)
	for target in route:
		var attempts:=0
		while game.hero.position.distance_to(target)>.12 and attempts<600:
			attempts+=1
			var direction: Vector3=(target-game.hero.position).normalized()
			var right: Vector3=game.camera.global_basis.x;right.y=0;right=right.normalized()
			var down: Vector3=game.camera.global_basis.z;down.y=0;down=down.normalized()
			steer(Vector2(direction.dot(right),direction.dot(down))*minf(1,game.hero.position.distance_to(target)/.6));await frames(1)
	touch(false);await frames(2)
	return game.hero.position.distance_to(at)<.65
func shot(name_: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name_+".png"))==OK,"Captured real frame: "+name_)
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	game=load("res://Refuge.tscn").instantiate();game.save_path=path;game.saving_enabled=false;root.add_child(game);await frames(6)
	game.market.worked.connect(func(_area: int,_product: String,_index: int,_finished: bool):hits+=1)
	check(game.is_processing() and not game.ui.modal.visible,"The production scene runs automatically without a tutorial or ignition tap")
	check(await walk_to(game.market.TREE_POSITIONS[1]+Vector3(0,0,-1.5)),"A real joystick reaches a pine beside the empty depot")
	await advance(1.5)
	check(hits>=3 and game.market.bag["wood"]>=5,"The natural scene loop cuts and collects beside the depot without a work touch")
	await shot("01_hacha_sin_tocar")
	check(await walk_to(game.market.SHOP_POSITIONS["wood"]+Vector3(-3.1,0,0)),"The joystick reaches the visible wood stall's side")
	await advance(4)
	check(game.market.bag["wood"]==0 and game.market.town(0)["sold"]["wood"]>=5,"Side proximity delivers the logs and completes actual paid customer orders")
	await shot("02_entrega_por_el_lado")
	check(await walk_to(game.market.BEAR_POSITIONS[0]+Vector3(-3.0,0,0)),"The joystick approaches the bear without entering its body")
	await advance(1.9)
	check(not game.market.active_node("meat",0,0) and game.market.bag["meat"]>=6,"The natural frame loop starts automatic scythe hits at the outer reach")
	check(await walk_to(game.market.BEAR_POSITIONS[1]+Vector3(0,0,3.0)),"The joystick reaches the steel-armored bear")
	await advance(4.5)
	check(not game.market.active_node("meat",1,0) and game.market.bag["meat"]>=15,"Repeated automatic hits finish the armored bear and add its complete reward")
	check(animation_restarts>=3,"Successive automatic hits visibly replay the swing instead of freezing its final pose")
	await shot("03_oso_blindado_automatico")
	check(await walk_to(game.market.BEAR_POSITIONS[2]+Vector3(0,0,2.6)),"The joystick reaches the reinforced bear while the bag has less than a full reward of space")
	await advance(7.5)
	check(not game.market.active_node("meat",2,0) and game.market.bag_count()==16 and game.market.town(0)["field_meat"][2]>=11,"A nearly full bag does not stop combat; all excess meat stays on the ground")
	await shot("04_mochila_llena_sigue_golpeando")
	check(await walk_to(game.market.SHOP_POSITIONS["meat"]+Vector3(0,0,-1.7)),"The joystick reaches the back of the meat stall")
	await advance(7)
	check(game.market.bag["meat"]==0 and game.market.town(0)["sold"]["meat"]>=5,"Approaching the back of the stall also delivers and completes paid customer orders automatically")
	await shot("05_entrega_por_atras")
	await walk_to(Vector3(2.5,0,9));var before: Vector3=game.hero.position;var count: int=hits;await advance(2)
	check(game.hero.position==before and hits==count,"Releasing the joystick leaves the hero still; no remote attacks or automatic movement")
	game.ui.show_market();count=hits;await frames(20)
	check(hits==count and not game.working,"Opening a menu pauses the protagonist's proximity actions")
	game.queue_free();await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d automatic runtime checks, %d failures; %d swing restarts" % [checks,failures,animation_restarts]);quit(1 if failures else 0)
