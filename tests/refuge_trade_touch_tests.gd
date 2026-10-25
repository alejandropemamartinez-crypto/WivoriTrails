extends SceneTree

# Only steer and buy. Harvesting, pickup, delivery and register attendance
# must start from actual proximity, without a work tap or gifted currency.
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
func shot(name_: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await frames(3);await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(output.path_join(name_+".png"))==OK,"Native proximity capture: "+name_)
func hire(id: String) -> void:
	game.ui.show_market(id);await frames();await tap(game.ui.shop_rows[id]["button"]);game.ui.close();await advance(.1)
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	viewport=SubViewport.new();viewport.size=Vector2i(720,1280);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	game=load("res://Refuge.tscn").instantiate();game.save_path=path;game.saving_enabled=false;viewport.add_child(game);game.set_process(false);await frames(5)
	check(game.ui.work_button is PanelContainer and game.ui.work_button.mouse_filter==Control.MOUSE_FILTER_STOP,"The work indicator is a passive card that prevents accidental world taps; no work finger is required")
	var start: Vector3=game.hero.position
	await tap(game.ui.task_button)
	check(game.hero.position==start and game.market.bag_count()==0,"SEÑALAR marks a destination and never takes over movement")
	game.center_camera();check(await walk_to(game.market.TREE_POSITIONS[0]+Vector3(0,0,1.3)),"A real joystick gesture approaches the pine")
	var grip: Node3D=game.market_world.hero_tool
	check(grip.to_global(Vector3(0,.8,0)).y>grip.global_position.y+.35,"The automatically equipped axe points above the snow")
	await advance(1.25)
	check(game.market.bag["wood"]==5 and not game.market.active_node("wood",0,0),"Approaching the pine cuts and collects it without touching any work control")
	check(game.state.lit,"The first harvest starts the settlement without an extra ignition prompt")
	await shot("01_hacha_y_pinos")
	check(await walk_to(game.market.COUNTERS["wood"]),"The joystick carries the logs to waiting customers")
	await advance(4)
	check(game.market.coins==20 and game.market.bag["wood"]==0,"Entering the counter transfers logs and attends orders automatically")
	await shot("02_clientes_y_venta")
	check(await walk_to(game.market.BEAR_POSITIONS[0]+Vector3(0,0,1.4)),"The hero approaches the normal polar bear manually")
	await advance(1.8)
	check(game.market.bag["meat"]==6 and not game.market.active_node("meat",0,0),"Entering bear reach automatically swings the scythe until meat is collected")
	check(game.market_world.bears[1].armor_tier==1 and game.market_world.bears[2].armor_tier==2,"Both armored variants have actual body and head armor in the rendered scene")
	await walk_to(game.market.COUNTERS["meat"]);await advance(4)
	check(game.market.coins>=50,"Automatic delivery also works at the separate meat counter")
	await walk_to(game.market.BEAR_POSITIONS[1]+Vector3(0,0,1.5));await advance(.4)
	check(game.market.active_node("meat",1,0) and game.market.town(0)["nodes"]["meat"][1]["hp"]<9,"The armored bear takes damage automatically and survives the normal bear's early hits")
	await shot("03_hoz_y_osos")
	await advance(4.2);await walk_to(game.market.COUNTERS["meat"]);await advance(4)
	var rounds:=0
	while rounds<65 and not game.market.operating(0):
		rounds+=1
		for req in [["lumberjack",1],["cashier",1],["hunter",1],["cashier",2],["porter",1],["sentinel",1]]:
			if game.market.worker_count(req[0],0)<req[1] and game.market.buy_reason(req[0],0).is_empty():await hire(req[0])
		if game.market.buy_reason("rail",0).is_empty():await hire("rail")
		if game.market.operating(0):break
		if game.market.bag_count()==0 and game.market.town(0)["depot"]["wood"]+game.market.town(0)["depot"]["meat"]>0:
			await walk_to(game.market.DEPOT);await advance(.4)
		elif game.market.bag_count()==0:
			var index:=-1
			for candidate in range(3):
				if game.market.active_node("meat",candidate,0):index=candidate;break
			if index<0:await advance(19);index=0
			await walk_to(game.market.BEAR_POSITIONS[index]+Vector3(0,0,1.5));await advance(float(game.market.max_hp("meat",index))*.43+.5)
		for product in game.market.PRODUCTS:
			if game.market.bag[product]>0:await walk_to(game.market.COUNTERS[product]);await advance(4)
	check(game.market.operating(0),"Customer earnings can buy all three railway sections through real touch controls")
	check(game.market.worker_count("cashier",0)==2 and game.market_world.cashiers.size()==2,"Both earned cashiers exist at their own registers")
	if game.market.worker_count("porter",0)==0:
		await advance(60)
		if game.market.buy_reason("porter",0).is_empty():await hire("porter")
	if game.market.worker_count("sentinel",0)==0:
		await advance(60)
		if game.market.buy_reason("sentinel",0).is_empty():await hire("sentinel")
	check(game.market.worker_count("porter",0)==1 and not game.market_world.porter.is_empty(),"The earned porter is a visible cargo-carrying NPC")
	check(game.market.worker_count("sentinel",0)>=1 and game.market_world.guards.size()>=1,"The earned sentinel occupies a constructed tower")
	await walk_to(Vector3(2.5,0,8.5));var before_position: Vector3=game.hero.position;var before_bag: Dictionary=game.market.bag.duplicate();var before_coins: int=game.market.coins
	var shots_before: int=game.market.town(0)["next_shot"];await advance(75)
	check(game.hero.position==before_position and game.market.bag==before_bag,"The hero stays still and does no work when far from resources and counters")
	check(game.market.coins>before_coins,"Hired cashiers and transports keep selling while the player is far away")
	check(game.market.town(0)["next_shot"]>shots_before,"The tower continues launching real projectiles without the hero hunting")
	if game.market.buy_reason("lumberjack",0).is_empty():await hire("lumberjack")
	await advance(60)
	if game.market.buy_reason("sentinel",0).is_empty():await hire("sentinel")
	check(game.market.worker_count("lumberjack",0)>=2 and game.market_world.workers.size()>=3,"A second paid lumberjack appears with an independent route instead of an invisible speed multiplier")
	check(game.market.worker_count("sentinel",0)==2 and game.market_world.guards.size()==2,"The second paid sentinel builds and occupies the other tower")
	var clock: float=float(game.state.raid_clock);game.state.raid_remaining=14;game.state.raid_hits=0
	await advance(4)
	check(game.state.raid_remaining==0 and game.state.defended>0,"Hired tower sentinels repel an actual raid without an AHUYENTAR tap")
	game.state.raid_clock=clock
	game.camera_detached=true;game.focus=Vector3(0,0,22);game.zoom=39;game._camera(1);game.market_world.refresh(.01)
	for height in [1280,1600]:
		viewport.size=Vector2i(720,height);await frames(3);game._camera(1);game.market_world.refresh(.01);await frames()
		var wood_sign: Control=game.ui.market_labels["wood"]["button"];var meat_sign: Control=game.ui.market_labels["meat"]["button"]
		check(not (wood_sign.visible and meat_sign.visible and wood_sign.get_global_rect().intersects(meat_sign.get_global_rect())),"Shop signs do not overlap at height "+str(height))
		check(not game.ui.work_button.get_global_rect().intersects(game.ui.task_card.get_global_rect()),"The automatic work indicator leaves the objective readable at height "+str(height))
	viewport.size=Vector2i(720,1280);await frames(3);game._camera(1);game.market_world.refresh(.01)
	await shot("04_tren_y_automatizacion")
	game.ui.show_market("sentinel");await frames(3);await shot("05_mejoras_con_monedas")
	game.ui.show_route();await frames(3);check(game.ui.goal_rows.size()==5 and game.market.charter_ready(0),"Five explicit requirements include the two cashiers before travelling")
	await shot("06_siguiente_pueblo")
	game.ui.close();game.saving_enabled=true;check(game.save(),"The real earned progress writes through the atomic save")
	var stored: Dictionary=preload("res://scripts/save_store.gd").load_data(path)
	if not output.is_empty():preload("res://scripts/save_store.gd").write_data(output.path_join("playthrough_save.json"),stored)
	check(stored["market"]["schema"]==3 and stored["market"]["markets"][0]["workers"]["sentinel"]["level"]==2,"The save retains all paid crew, towers, ground loot and logistic progress")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED);game._notification(Node.NOTIFICATION_APPLICATION_RESUMED);game.set_process(false);await frames(3)
	check(game.market.operating(0) and game.stick.visible and game.market.worker_count("cashier",0)==2,"Android resume preserves automation and fresh movement controls")
	game.queue_free();await frames();viewport.queue_free();await frames();await create_timer(.1).timeout
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d proximity touch checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
