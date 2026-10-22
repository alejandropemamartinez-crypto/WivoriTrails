extends SceneTree

var game: Node3D
var checks:=0
var failures:=0
var path: String="user://wivori_journey_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func start() -> void:
	game=load("res://Main.tscn").instantiate();game.save_path=path;root.add_child(game)
	game.set_process(false);game.world.set_process(false);await process_frame
func run() -> void:
	await start()
	var campaign=game.route.campaign
	check(campaign.steps(0).size()==5,"The first destination exposes all five requirements from a fresh save")
	check(game.route.route_caption().contains("VILLA MIGA"),"The persistent destination card names the next map")
	var initial: Vector3=game.player.position
	game.route.guide_campaign()
	for i in range(10):game._process_player(.1)
	check(game.player.position==initial and not game.has_tap_destination,"Destination guidance never walks or teleports the protagonist")
	# Follow the actual recommended path with joystick input. No coins, sales,
	# harvests, workers or quest progress are granted by this journey fixture.
	var elapsed:=0.0
	var last_title:=""
	for frame in range(6000):
		if game.route.region==1:break
		var task: Dictionary=game._current_objective()
		if task["title"]!=last_title:
			last_title=task["title"];print("JOURNEY %.1fs: %s · wallet %d · sold %d" % [elapsed,last_title,game.coins,game.sold])
		game.input_stick.axis=Vector2.ZERO
		if not task.has("target"):
			if task.get("upgrade","")=="level":game._follow_objective()
		else:
			var target: Vector3=task["target"]
			if game.player.position.distance_to(target)<=1.5:
				if not str(task.get("action","")).is_empty() or not str(task.get("upgrade","")).is_empty():game._follow_objective()
			else:
				var points: PackedVector3Array=game.world.navigation.find_path(game.player.position,target)
				for point in points:
					var difference: Vector3=point-game.player.position
					if difference.length()<.25:continue
					game.input_stick.axis=Vector2(difference.x,difference.z).normalized();break
		game._process(.1)
		if not game.route.away():game.world._process(.1)
		elapsed+=.1
		if frame%20==0:await process_frame
	check(game.route.region==1,"A fresh economy reaches Villa Miga through the real joystick, cash, purchases and ferry")
	check(elapsed<600.0,"The guided route completes within the simulation budget, without level-six grinding")
	check(game.worker_count==1 and game.checkout_level==1 and game.run.level<6,"The first voyage needs one worker and one checkout upgrade, not maximum upgrades")
	check(game.manual_delivered>=6 and game.sold>=18,"The first voyage includes actual manual deliveries and customer purchases")
	check(game.route.pending_destination==-1,"Arrival clears the selected destination")
	if game.route.region!=1:
		game.queue_free();await process_frame;quit(1);return
	var saved: Dictionary=game._save_data()
	check(saved["version"]==8,"Existing save files retain their schema")
	game.coins=0;game.player.position=game.route.PROJECTS[0]["at"]+Vector3(0,0,3.2)
	check(game.route.build_project() and game.route.wheat.size()==16,"A cash-poor arrival can prepare the included first trigal instead of being stranded")
	game.stash["carrot"]=game.max_capacity
	check(game.route.objective()["action"]=="route:travel:0","A full mainland harvest points directly to the home pier")
	game.route._arrive(0)
	check(game.route.objective().get("target")==Vector3(4,0,2.5),"Returning with mainland crops guides unloading before sailing again")
	game.stash["carrot"]=0;game.route._arrive(1)
	# At the next island exit only the documented core workshop is required.
	game.route.stage=4
	for p in game.route.PROJECTS.slice(0,4):
		if not game.route.built.has(p["id"]):game.route.built.append(p["id"])
	game.route.employees["flour"]=false;game.route.mastery["flour"]=1
	check(campaign.exit_allowed(game.route.PROJECTS[4]),"A paid, paused core operator and its first improvement satisfy the visible exit requirements")
	check(not game.route.employees.has("egg") and not game.route.mastery.has("bread"),"Other workshops can remain optional without blocking the next destination")
	game.route.inventory["bread"]=10;game.route.inventory["egg"]=6
	var funding: Dictionary=game.route.funding_objective(900,"Abrir Puerto Nata",{"tag":"","title":"","detail":"","goal":1,"value":0,"button":""})
	check(not str(funding.get("action","")).begins_with("route:sell:"),"The funding guide reserves the exact supplies required to open the next map")
	game.route.inventory["wheat"]=3
	funding=game.route.funding_objective(900,"Abrir Puerto Nata",{"tag":"","title":"","detail":"","goal":1,"value":0,"button":""})
	check(funding.get("action","")=="route:sell:wheat","The guide sells surplus instead of consuming reserved exit cargo")
	game.route.access_floor=3;game.route.ferry=true
	game.player.position=Vector3(0,0,-5);game.route.plan_travel(0)
	check(game.route.pending_destination==0 and game._current_objective().get("action","")=="route:travel:0","Selecting an unlocked destination retains it while the hero walks to the pier")
	game._save_progress();var state: Dictionary=game.route.save_state()
	game.route.load_state(state)
	check(game.route.unlocked()>=3,"Updating campaign rules does not revoke already opened destinations")
	game.queue_free();await process_frame;await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d journey checks, %d failures; first voyage %.1f simulated seconds" % [checks,failures,elapsed])
	quit(1 if failures else 0)
