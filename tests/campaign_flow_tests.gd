extends SceneTree

# Prepared regression scenarios. Do not run during the source-only phase.
# Static grammar checks do not establish that any scenario below passes.
var game: Node3D
var checks:=0
var failures:=0
var save_path: String="user://wivori_campaign_flow_%d.json" % OS.get_process_id()

func _initialize() -> void:call_deferred("run_checks")
func check(condition: bool,message: String) -> void:
	checks+=1
	if condition:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
func start() -> void:
	game=load("res://Main.tscn").instantiate();game.save_path=save_path;root.add_child(game)
	game.set_process(false);game.world.set_process(false);await process_frame
func reload() -> void:
	game._save_progress();game.queue_free();await process_frame;await process_frame;await start()
func factory_fixture() -> void:
	game.route.ferry=true;game.route.stage=game.route.PROJECTS.size();game.route.industry_stage=game.route.INDUSTRY_PROJECTS.size()
	for project in game.route.PROJECTS+game.route.INDUSTRY_PROJECTS:game.route.built.append(project["id"])
	for key in game.route.RECIPES:
		if game.route.RECIPES[key]["region"]==4:game.route.employees[key]=false;game.route.mastery[key]=3

func run_checks() -> void:
	clean();await start()
	game.milestone.announce("flow:news","Nuevo destino","El jugador elige cuándo leer.","boat")
	game.run.level=3;game.run.warning=5
	for i in range(30):game.milestone.tick(1.0)
	check(not game.milestone.is_open(),"Repeated tasks, attacks and elapsed time cannot automatically open news")
	game.milestone.show_next()
	check(game.milestone.is_open(),"News can be opened deliberately")
	game.milestone.dismiss();game.run.warning=0
	check(not game.milestone.is_open(),"Dismissing news does not automatically open another card")

	# Map exit requires real upgrades and consumes nothing when rejected.
	game.coins=100000;game.route.ferry=true;game.route.stage=4
	for i in range(4):game.route.built.append(game.route.PROJECTS[i]["id"])
	game.route._arrive(1);game.route.inventory["bread"]=10;game.route.inventory["egg"]=6
	game.player.position=game.route.DOCK
	var wallet: int=game.coins
	check(not game.route.build_project() and game.coins==wallet and game.route.inventory["bread"]==10,"An unfinished map cannot purchase its exit or lose its supplies")
	for key in ["flour","feed","bread","egg"]:game.route.employees[key]=false;game.route.mastery[key]=3
	check(game.route.build_project() and game.route.unlocked()==2,"Paid but paused operators count toward mastery, without a second hire")
	await reload()
	check(game.route.unlocked()==2,"A legitimately opened map remains available after reload")

	# Old saves retain access even when they predate the mastery rules.
	game.route.load_state({"ferry":true,"stage":10,"region":3,"market_money":[0,12,0,7,0]})
	check(game.route.unlocked()>=3 and game.route.market_money[3]==7,"A legacy v8 bay and its cash survive new map requirements")
	factory_fixture()
	game.route.industry_orders_done=5
	check(game.route.unlocked()==4,"Five contracts do not prematurely open Aurora")
	game.route.industry_orders_done=6
	check(game.route.unlocked()==5,"Maxed factories and the full six-order round open the sixth map")
	game.route.access_floor=5;game.route.aurora_stage=game.route.AURORA_PROJECTS.size()
	for project in game.route.AURORA_PROJECTS:game.route.built.append(project["id"])
	game.route._arrive(5);game.player.position=game.route.MARKET
	check(game.route.region_identity.expedition_boat!=null,"The purchased shipyard supplies an independent visible freight ship")
	var manifest: Dictionary=game.route.EXPEDITIONS[0]
	for key in manifest["needs"]:game.route.inventory[key]=int(manifest["needs"][key])
	var old_cash: int=game.route.market_money[5]
	wallet=game.coins
	check(game.route.start_expedition(0),"A loaded expedition starts only at its physical departure point")
	check(not game.route.start_expedition(0),"A second press cannot consume the same manifest again")
	check(game.coins==wallet and game.route.market_money[5]==old_cash,"Departure never credits money in advance")
	game.route._arrive(0);game.route.tick(20.0)
	check(float(game.route.expedition["remaining"])==float(manifest["duration"])-20.0,"Expedition time advances while the player works in another map")
	await reload()
	check(not game.route.expedition.is_empty(),"An unfinished expedition survives save and reload")
	game.route.tick(100.0)
	check(game.route.expedition.is_empty() and game.route.market_money[5]==old_cash+int(manifest["reward"]),"Arrival credits the Aurora cashbox exactly once")
	game.route.tick(100.0)
	check(game.route.market_money[5]==old_cash+int(manifest["reward"]),"Later ticks cannot duplicate an arrived shipment")
	await reload()
	check(game.route.expedition.is_empty() and game.route.expeditions_done==1,"Reload cannot revive an already paid expedition")
	check(game.route.expedition_routes.size()==1 and not game.route.campaign.completed(5),"Repeating one route does not complete the three-route network")
	check(game._save_data()["version"]==8,"Campaign additions preserve the existing outer save schema")

	# Order content changes independently from its fixed sign geometry.
	game.run.level=4;game.world.update_security(game.run)
	var sign: WivoriPremiumSign=game.world.premium_board
	var dimensions: float=(sign.get_child(0) as Sprite3D).pixel_size
	for level in [4,5,6,12,20]:
		game.run.level=level;game.world.update_security(game.run)
		check(is_equal_approx((sign.get_child(0) as Sprite3D).pixel_size,dimensions),"Long crop names cannot resize the premium board")
	game.queue_free();await process_frame;await process_frame;clean()
	print("RESULT: %d campaign checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
