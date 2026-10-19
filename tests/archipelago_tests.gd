extends SceneTree
const Store=preload("res://scripts/save_store.gd")
var game: Node3D
var checks:=0
var failures:=0
var test_path: String="user://wivori_route_tests_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run_tests")
func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))
func start() -> void:
	game=load("res://Main.tscn").instantiate();game.save_path=test_path;root.add_child(game);game.set_process(false);game.world.set_process(false);await process_frame
func stop() -> void:game.queue_free();await process_frame;await process_frame
func go(region: int) -> void:
	if game.route.region==region:return
	game.player.position=game.route.DOCK if game.route.away() else game.route.HOME_DOCK
	check(game.route.travel(region),"A dock interaction starts travel to region %d" % region)
	game.route.tick(1.4)
	check(game.route.region==region and game.world.navigation.is_walkable(game.player.position,.25),"Arrival uses a free position in region %d" % region)
func ensure(key: String,quantity: int,depth: int=0) -> void:
	if depth>7:check(false,"Recipe graph must not contain a cycle");return
	var route=game.route
	if key=="wheat":
		await go(1)
		while route.amount(key)<quantity:
			var crop: Dictionary=route.wheat[0];game.player.position=crop["node"].position;route.tick(8.1);route.harvest_wait=0
			if game._total_bag()>=game.max_capacity:game.player.position=route.DOCK;route.deposit()
		return
	while route.amount(key)<quantity:
		var recipe: Dictionary=route.RECIPES[key]
		for ingredient in recipe["needs"]:await ensure(ingredient,recipe["needs"][ingredient],depth+1)
		await go(recipe["region"]);game.player.position=route.station(key)
		var before: int=route.amount(key)
		check(route.start_batch(key),"Ingredients start a real batch of "+key)
		check(not route.start_batch(key),"A running batch cannot consume ingredients twice")
		route.tick(recipe["time"]+.1)
		if game._total_bag()+recipe["count"]>game.max_capacity:game.player.position=route.DOCK;route.deposit();game.player.position=route.station(key)
		check(route.pickup(key) and route.amount(key)==before+recipe["count"],"Collecting adds only the finished batch of "+key)
func run_tests() -> void:
	clean();await start()
	check(not game.route.ferry and game.route.unlocked()==0 and game.route.stage==0,"New games start in Wivori with a visible but locked route")
	var price: int=game.coins
	check(not game.route.repair_ferry() and game.coins==price,"The ferry cannot be repaired before its gates")
	var models: Dictionary={}
	for species in ["dog","scottie","fox","cat","human","pig","duck","rabbit","raccoon"]:
		var actor: MarketActor=game.ActorScript.new();actor.setup("customer",Color("#429b97"),species);game.add_child(actor)
		check(actor.body_root.scene_file_path not in ["res://assets/models/terrier.glb","res://assets/models/hero.glb"],"NPC alias %s cannot use the protagonist mesh" % species)
		models[actor.body_root.scene_file_path]=true;actor.queue_free()
	check(models.size()>=5,"NPCs have at least five distinct authored silhouettes")
	var spaced:=true;var targets: Array=game.UPGRADE_POS.values()
	for i in range(targets.size()):
		for j in range(i+1,targets.size()):spaced=spaced and targets[i].distance_to(targets[j])>=5
	check(spaced,"Upgrade sites are separated by at least five metres")
	var reachable:=true
	for at in targets:reachable=reachable and not game.world.navigation.find_path(Vector3.ZERO,at).is_empty()
	check(reachable,"Separated upgrade destinations retain a navigable entrance")
	game.milestone.tick(2);await process_frame;await process_frame;await process_frame
	check(game.milestone.is_open(),"A new mission opens an explicit large introduction")
	var rect: Rect2=game.milestone.card.get_global_rect();var screen: Vector2=game.get_viewport().get_visible_rect().size
	check(rect.get_area()/screen.x/screen.y>=.75,"The mission card covers at least three quarters of the screen")
	game.input_stick.axis=Vector2.RIGHT;var at: Vector3=game.player.position;var raid: float=game.run.next_raid;game._process(.5)
	check(game.player.position==at and game.run.next_raid==raid,"Reading a major alert pauses movement and danger")
	game.milestone.dismiss();check(game.input_stick.axis==Vector2.ZERO,"Dismissing a mission clears held movement")
	game.run.level=6;game.coins=100000;game.pier_owned=true;game.world.open_pier();game.player.position=Vector3.ZERO
	check(not game.route.repair_ferry(),"Ferry repair requires physically reaching the port")
	game.player.position=game.route.HOME_DOCK;price=game.coins
	check(game.route.repair_ferry() and game.coins==price-900,"Ferry repair spends the displayed amount exactly once")
	check(not game.route.repair_ferry() and not game.route.travel(2),"Repair cannot repeat and later towns stay locked")
	await go(1);check(not game.world.visible and game.route.scenery.visible,"Only the active town is rendered")
	check(game.route.wheat.is_empty(),"Wheat fields require their actual construction project")
	# Complete the dependency graph by harvesting and crafting. Coins alone are a fixture.
	for stage in range(15):
		var p: Dictionary=game.route.project()
		for attempt in range(8):
			if game.route.has_needs(p["needs"]):break
			for key in p["needs"]:await ensure(key,p["needs"][key])
		await go(p["region"])
		game.player.position=p["at"]+(Vector3(0,0,3.2) if not p["model"].is_empty() else Vector3.ZERO)
		var spent: int=game.coins
		check(game.route.build_project() and game.route.stage==stage+1 and game.coins==spent-p["cost"],"Sequential project %d consumes its price and real supplies" % (stage+1))
		game._save_progress()
		if stage in [2,6,11]:
			var region: int=game.route.region;var stock: Dictionary=game.route.inventory.duplicate();var position: Vector3=game.player.position;await stop();await start()
			check(game.route.stage==stage+1 and game.route.region==region and game.route.inventory==stock,"Reload preserves current town, projects and warehouse")
			check(game.player.position.distance_to(position)<.8,"Reload restores The protagonist near his saved position in the active town")
	check(game.route.unlocked()==4 and game.route.project().is_empty() and game.route.industry_stage==0 and game.route.built.has("beacon"),"Fifteen historical lighthouse chapters remain complete and open the optional industrial destination")
	await go(1);await ensure("wheat",12);game.player.position=game.route.DOCK;game.route.deposit();game.player.position=game.route.station("flour");price=game.coins
	check(game.route.hire("flour") and game.coins==price-650,"A station operator is an explicit paid automation upgrade")
	game.route.employees["flour"]=false;price=game.coins
	check(not game.route.hire("flour") and game.coins==price,"Pausing an operator cannot permit a duplicate purchase")
	game.route.employees["flour"]=true;game.route.tick(.1);check(game.route.jobs["flour"]["remaining"]>0,"An operator starts production from saved cargo")
	for i in range(20):game.route.tick(13)
	check(game.route.jobs["flour"]["ready"]<=9,"Automated output has a finite physical collection buffer")
	check(game.route.improve("flour") and game.route.mastery["flour"]==1,"Production has persistent additional upgrade tiers")
	game.player.position=Vector3.ZERO;var position: Vector3=game.player.position;game._set_world_goal(game.route.station("flour"))
	for i in range(10):game._process_player(.1)
	check(game.player.position.distance_to(position)<.01,"Production guides never introduce protagonist autopilot")
	await go(0);check(game.world.visible and game.world.navigation==game.route.home_nav,"Returning restores the original world and its navigation")
	game._save_progress();check(game._save_data()["version"]==8 and game.route.stage==15,"The new save schema stores the completed campaign")
	await stop();clean();Store.write_data(test_path,{"version":7,"coins":321,"worker_count":2,"player_speed":8,"run":{"level":8},"town":{"buildings":["house"]}});await start()
	check(game.coins==321 and game.worker_count==2 and game.run.level==8 and game.town.has_building("house") and not game.route.ferry,"Version seven migrates without resetting money, helpers, chapter or buildings")
	await stop();clean();print("RESULT: %d archipelago checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
