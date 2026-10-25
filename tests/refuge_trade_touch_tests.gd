extends SceneTree

# Exercise the complete visible interaction, not direct axis assignments or
# currency grants: steer, hold a tool, deliver, get paid, hire, lay tracks.
var viewport: SubViewport
var game: Node3D
var checks:=0
var failures:=0
var output:=""
var path: String="user://refuge_trade_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)
func frames(count: int=2) -> void:
	for index in range(count):await process_frame
func touch(point: Vector2,down: bool,index: int=2,cancel: bool=false) -> void:
	var event:=InputEventScreenTouch.new();event.position=point;event.pressed=down;event.index=index;event.canceled=cancel;viewport.push_input(event,true);await process_frame
func drag(point: Vector2,index: int=2) -> void:
	var event:=InputEventScreenDrag.new();event.position=point;event.index=index;viewport.push_input(event,true)
func center(control: Control) -> Vector2:return control.get_global_transform_with_canvas()*(control.size*.5)
func advance(seconds: float) -> void:
	var remaining:=seconds
	while remaining>.001:
		var step: float=minf(.1,remaining);remaining-=step;game._process(step)
	game.set_process(false);game.ui.refresh(0);await frames()
func tap(control: Control,index: int=7) -> void:
	await touch(center(control),true,index);await touch(center(control),false,index);await frames()
func walk_to(at: Vector3) -> bool:
	var route: PackedVector3Array=game.navigation.find_path(game.hero.position,at)
	await touch(center(game.stick),true)
	for target in route:
		var attempts:=0
		while game.hero.position.distance_to(target)>.28 and attempts<180:
			attempts+=1
			var world: Vector3=(target-game.hero.position).normalized()
			var right: Vector3=game.camera.global_basis.x;right.y=0;right=right.normalized()
			var down: Vector3=game.camera.global_basis.z;down.y=0;down=down.normalized()
			var axis:=Vector2(world.dot(right),world.dot(down))
			drag(center(game.stick)+axis*65)
			game._process(minf(.1,game.hero.position.distance_to(target)/6.8));game.set_process(false)
		await process_frame
	await touch(center(game.stick),false);await frames()
	return game.hero.position.distance_to(at)<.6
func hold_work(seconds: float,index: int=8) -> void:
	game.ui.refresh(0);await frames();await touch(center(game.ui.work_button),true,index);await advance(seconds);await touch(center(game.ui.work_button),false,index)
func shot(name_: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await frames(3);await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(output.path_join(name_+".png"))==OK,"Native trade capture: "+name_)
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	viewport=SubViewport.new();viewport.size=Vector2i(720,1280);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	game=load("res://Refuge.tscn").instantiate();game.save_path=path;game.saving_enabled=false;viewport.add_child(game);game.set_process(false);await frames(5)
	await tap(game.ui.task_button);check(game.state.lit,"A real launch tap starts the manual trading objective")
	var start: Vector3=game.hero.position
	await tap(game.ui.task_button)
	check(game.hero.position==start and game.market.bag_count()==0,"SEÑALAR only marks the task and never walks or harvests for the hero")
	game.center_camera();check(await walk_to(game.market.TREE_POSITIONS[0]+Vector3(0,0,1.3)),"Real joystick gestures reach the first pine from spawn")
	check(game.ui.work_button.text.contains("HACHA") and not game.ui.work_button.disabled,"The nearby pine exposes an enabled, contextual axe button")
	await hold_work(1.15)
	check(game.market.bag["wood"]==5 and not game.market.active_node("wood",0,0),"Holding the axe with a real second finger cuts one pine into carried logs")
	check(not game.working and game.stick.axis==Vector2.ZERO,"Releasing the work finger stops the action without sticking the joystick")
	await shot("01_hacha_y_pinos")
	check(await walk_to(game.market.COUNTERS["wood"]),"The joystick reaches the waiting wood customers")
	await hold_work(.2);await advance(4)
	check(game.market.coins==20 and game.market.bag["wood"]==0,"A real delivery and completed customer orders pay the first twenty coins")
	await shot("02_clientes_y_venta")
	check(await walk_to(game.market.BEAR_POSITIONS[0]+Vector3(0,0,-1.6)),"The hero can manually reach the polar bear hunting area")
	check(game.ui.work_button.text.contains("HOZ"),"The hunting area equips a visible scythe rather than an axe")
	await hold_work(1.7)
	check(game.market.bag["meat"]==6 and not game.market.active_node("meat",0,0),"Holding the scythe actually defeats the polar bear and fills the meat inventory")
	await shot("03_hoz_y_osos")
	check(await walk_to(game.market.COUNTERS["meat"]),"The player can carry the meat back to its own stall")
	await hold_work(.2);await advance(4)
	check(game.market.coins>=50,"Meat customers pay from actual delivered goods")
	# Fund all unlocks through ordinary movement and work; no test currency.
	var loops:=0
	while loops<14 and not game.market.operating(0):
		loops+=1
		for id in ["lumberjack","hunter","rail"]:
			if id!="rail" and game.market.town(0)["workers"][id]["level"]>0:continue
			if not game.market.buy_reason(id,0).is_empty():continue
			game.ui.show_market(id);await frames();await tap(game.ui.shop_rows[id]["button"]);game.ui.close()
		if game.market.operating(0):break
		var product: String="meat"
		var target_index:=-1
		for index in range(game.market.positions(product).size()):
			if game.market.active_node(product,index,0):target_index=index;break
		if target_index<0:await advance(19);target_index=0
		await walk_to(game.market.positions(product)[target_index]+Vector3(0,0,-1.5));await hold_work(1.8)
		await walk_to(game.market.COUNTERS[product]);await hold_work(.2);await advance(4)
	check(game.market.town(0)["workers"]["lumberjack"]["level"]==1 and game.market.town(0)["workers"]["hunter"]["level"]==1,"Touch-purchased lumberjack and hunter are funded entirely by customer sales")
	# Let the two hired workers provide any remaining railway funds.
	while loops<40 and not game.market.operating(0):
		loops+=1;await advance(15)
		await walk_to(game.market.DEPOT);await hold_work(.2)
		for product in game.market.PRODUCTS:
			if game.market.bag[product]>0:await walk_to(game.market.COUNTERS[product]);await hold_work(.2)
		await advance(5)
		if game.market.buy_reason("rail",0).is_empty():
			game.ui.show_market("rail");await frames();await tap(game.ui.shop_rows["rail"]["button"]);game.ui.close()
	check(game.market.operating(0),"All three visible track sections can be bought through the actual touch shop without fabricated currency")
	var player_before: Vector3=game.hero.position;var before_coins: int=game.market.coins
	await advance(65)
	check(game.hero.position==player_before,"Fully hired automation never moves the protagonist")
	check(game.market.coins>before_coins and game.market.town(0)["train"]["laps"]>0,"Real workers and the completed train now fill customer orders without player deliveries")
	check(game.market_world.train.size()==3 and game.market_world.workers.size()==2,"The operating train, two cargo wagons and both working NPC species exist in the rendered world")
	game.camera_detached=true;game.focus=Vector3(0,0,22);game.zoom=39;game._camera(1);game.market_world.refresh(.01)
	for height in [1280,1600]:
		viewport.size=Vector2i(720,height);await frames(3);game._camera(1);game.market_world.refresh(.01);await frames()
		var wood_sign: Control=game.ui.market_labels["wood"]["button"];var meat_sign: Control=game.ui.market_labels["meat"]["button"]
		check(not (wood_sign.visible and meat_sign.visible and wood_sign.get_global_rect().intersects(meat_sign.get_global_rect())),"The two shop signs stay readable without overlapping at height "+str(height))
		check(not game.ui.work_button.get_global_rect().intersects(game.ui.task_card.get_global_rect()),"The manual work button stays clear of the objective at height "+str(height))
	viewport.size=Vector2i(720,1280);await frames(3);game._camera(1);game.market_world.refresh(.01)
	await shot("04_tren_y_automatizacion")
	game.ui.show_market("train");await frames(3);await shot("05_mejoras_con_monedas")
	game.ui.show_route();await frames(3);check(game.ui.goal_rows.size()==4 and game.market.charter_ready(0),"The route screen shows four achieved requirements instead of an unexplained map lock")
	await shot("06_siguiente_pueblo")
	game.ui.close();game.saving_enabled=true;check(game.save(),"The completed commercial loop writes through the existing atomic save")
	var stored: Dictionary=preload("res://scripts/save_store.gd").load_data(path)
	if not output.is_empty():preload("res://scripts/save_store.gd").write_data(output.path_join("playthrough_save.json"),stored)
	check(stored["market"]["coins"]==game.market.coins and stored["market"]["markets"][0]["rails"]==3,"The save contains the real wallet, employees, railway and stock")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED);game._notification(Node.NOTIFICATION_APPLICATION_RESUMED);game.set_process(false);await frames(3)
	check(game.market.operating(0) and game.stick.visible and not game.working,"Android resume preserves automation and restores fresh manual controls")
	game.queue_free();await frames();viewport.queue_free();await frames();await create_timer(.1).timeout
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d trade touch checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
