extends SceneTree
var game: Node3D
var checks:=0
var failures:=0
var path: String="user://wivori_polish_tests_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func go(region: int) -> void:
	game.player.position=game.route.DOCK if game.route.away() else game.route.HOME_DOCK
	check(game.route.travel(region),"Manual dock travel starts")
	game.route.tick(1.4)
func run() -> void:
	game=load("res://Main.tscn").instantiate();game.save_path=path;root.add_child(game);game.set_process(false);game.world.set_process(false);await process_frame
	var r=game.route
	r.open_board()
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=game.input_stick.get_global_rect().get_center()+Vector2(55,0)
	game.input_stick._input(touch)
	check(game.input_stick.axis==Vector2.ZERO and game.input_stick.active_finger==-1,"The joystick cannot steal a touch through an open menu")
	r.close_board()
	game.run.level=6;game.pier_owned=true;r.ferry=true;r.stage=15
	for p in r.PROJECTS:r.built.append(p["id"])
	var home_boat: Vector3=r.home_ferry.position
	go(1)
	check(not r.home_harbor.is_visible_in_tree(),"The original harbor does not render through another town")
	check(not game.world.navigation.is_walkable(Vector3(27,0,23),.25),"Island sea corners are not walkable")
	check(game.world.navigation.is_walkable(r.DOCK,.25),"The pier remains walkable")
	check(is_equal_approx(r.ground_height(r.DOCK),.44),"Standing on the pier uses its top surface")
	r.bag["wheat"]=2;r._update_cargo();game.player.position=r.DOCK
	check(r.deposit(),"A carried batch deposits at the pier")
	r._update_cargo()
	check(game.player.carrying==game._total_bag(),"Depositing clears the empty-handed carry animation")
	r.inventory["wheat"]=99999;r.bag["wheat"]=3
	check(r.deposit(),"Warehouse accepts the portion that fits")
	check(r.inventory["wheat"]==100000 and r.bag["wheat"]==2,"Warehouse overflow remains carried instead of disappearing")
	r.inventory["wheat"]=0;r.bag["wheat"]=0;r.wheat[0]["remaining"]=7.0
	go(2);r.tick(.5)
	check(r.crop_timers.size()==16 and r.crop_timers[0]>4.0,"Harvest regrowth survives a visit to another island")
	go(1)
	check(r.wheat[0]["remaining"]>0,"Returning cannot instantly reset a harvested field")
	go(0)
	check(r.home_harbor.is_visible_in_tree(),"Returning restores the original harbor")
	check(r.home_ferry.position.distance_to(home_boat)<.01,"The home ferry returns to its berth")
	game.queue_free();await process_frame;await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d polish regression checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
