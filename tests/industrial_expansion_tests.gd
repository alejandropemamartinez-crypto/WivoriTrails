extends SceneTree

# Industrial expansion regression tests. Intentionally not executed while
# this feature branch is under author review (no Godot import/build requested).
var game: Node3D
var failures:=0
var checks:=0
var path: String="user://wivori_industry_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run_tests")

func check(valid: bool, message: String) -> void:
	checks+=1
	if valid:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)

func clean() -> void:
	for ext in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+ext))

func start() -> void:
	game=load("res://Main.tscn").instantiate()
	game.save_path=path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame

func reload() -> void:
	game._save_progress()
	game.queue_free()
	await process_frame
	await process_frame
	await start()

func run_tests() -> void:
	clean()
	await start()
	var route=game.route
	check(route.stage==0 and route.industry_stage==0 and route.industry_orders_done==0,"Old-game route starts without fabricated industrial progress")
	check(route.market_money.size()==5 and route.NAMES.size()==5,"The fifth market has its own cashbox and destination slot")
	check(route.industry_project().is_empty() and not route.unlocked()==4,"New region remains locked before all fifteen original projects")
	check(route.goods_model("kits")=="goods_crate" and route.goods_model("packaging")=="goods_parcel","New recipes always resolve to bundled GLB models")
	route.ferry=true
	game.player.position=route.HOME_DOCK
	check(not route.travel(4),"Ferry cannot skip Faro progression to enter the industrial area")

	# A fixture representing a legitimate already-finished legacy save.
	route.stage=route.PROJECTS.size()
	for p in route.PROJECTS:route.built.append(p["id"])
	game.coins=150000
	check(route.project().is_empty() and route.industry_stage==0 and route.unlocked()==4,"Completing Faro retains its 15/15 finish while opening industry")
	game.player.position=route.HOME_DOCK
	check(route.travel(4),"Unlocked ferry offers physical travel to the fifth destination")
	route.tick(1.4)
	check(route.region==4 and route.region_identity!=null and game.world.navigation.is_walkable(game.player.position,.25),"Industrial arrival restores navigable, visually distinct scenery")

	for stage_index in range(route.INDUSTRY_PROJECTS.size()):
		var project: Dictionary=route.industry_project()
		check(not project.is_empty() and project["region"]==4,"Each industrial milestone belongs to its real factory map")
		for kind in project["needs"]:route.inventory[kind]=maxi(int(route.inventory[kind]),int(project["needs"][kind]))
		var price:int=game.coins
		game.player.position=project["at"]+Vector3(0,0,3.2)
		check(route.build_project() and game.coins==price-int(project["cost"]) and route.industry_stage==stage_index+1,"Construction consumes exact materials, cost and one industrial milestone")
		check(route.stage==15,"The legacy Faro milestone count never changes")
		if stage_index==0:
			await reload()
			route=game.route
			check(route.region==4 and route.industry_stage==1 and route.built.has("dockworks"),"First industrial project and fifth town survive reload")
		if stage_index==1:
			check(route.RECIPES.has("packaging") and route.processing_visuals.has("packaging"),"Packaging plant actually unlocks physical production")
			route.inventory["wheat"]=8
			route.inventory["flour"]=4
			game.player.position=route.station("packaging")
			check(route.start_batch("packaging") and not route.start_batch("packaging"),"A running factory batch cannot consume ingredients twice")
			route.tick(18.2)
			check(route.jobs["packaging"]["ready"]==3,"Real wheat and flour yield three visible packages")
			check(route.pickup("packaging") and route.bag["packaging"]>=3,"Factory output enters the real backpack exactly once")
			game.player.position=route.DOCK
			check(route.deposit() and route.inventory["packaging"]>=3,"Industrial cargo can be physically moved to ship storage")

	check(route.industry_project().is_empty() and route.industry_order().size()>0,"Completing five factories opens industrial trade contracts")
	check(route.built.has("trade_center") and route.stage==15,"Industry final building does not overwrite the lighthouse campaign")
	var order: Dictionary=route.industry_order()
	for kind in order["needs"]:route.inventory[kind]=int(order["needs"][kind])
	game.player.position=route.MARKET
	var before_coins:int=game.coins
	var reward:int=order["reward"]
	check(route.fulfill_industry_order(),"A mixed industrial contract can be physically delivered")
	check(game.coins==before_coins and route.market_money[4]==reward,"Contract payment stays in Forja cashbox until actual pickup")
	check(route.industry_orders_done==1 and not route.fulfill_industry_order(),"An already fulfilled order cannot be paid twice")
	for kind in order["needs"]:check(route.amount(kind)==0,"Contract consumption empties its actual ingredient "+kind)
	await reload()
	route=game.route
	check(route.region==4 and route.industry_orders_done==1 and route.market_money[4]==reward,"Saving before cash pickup preserves exactly one payment")
	route.tick(.1)
	check(game.coins==before_coins and route.market_money[4]==0 and game.cash.player_held==reward,"Player pickup moves contract reward into in-flight funds")
	route.tick(1.3)
	check(game.coins==before_coins+reward and game.cash.player_held==0,"Delivered contract is credited only after the flight reaches player")
	route.tick(1.3)
	check(game.coins==before_coins+reward,"Repeated local ticks cannot duplicate the collected reward")
	check(game._save_data()["version"]==8,"Additive route fields preserve existing v8 save format")

	game._save_progress()
	game.queue_free()
	await process_frame
	await process_frame
	clean()
	print("RESULT: %d industrial checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
