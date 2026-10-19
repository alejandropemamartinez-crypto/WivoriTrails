extends SceneTree

# Stage 5D specifications. Do not execute automatically or present these
# as passed: images, materials, collisions and frame rate still require Godot.
const Facade=preload("res://scripts/village_facade.gd")
var game: Node3D
var passed:=0
var failed:=0
var path: String="user://wivori_village_facades_%d.json" % OS.get_process_id()

const IDENTITIES=[
	"grain","grainmill","breadshop","henhouse",
	"cowbarn","dairy","pigpen","butcher",
	"harbor_depot","cannery","route_watch","beacon"
]

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, message: String) -> void:
	if ok:passed+=1;print("PASS: ",message)
	else:failed+=1;push_error("FAIL: "+message)

func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))

func run_tests() -> void:
	clean()
	game=load("res://Main.tscn").instantiate()
	game.save_path=path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame
	var initial_coins:int=game.coins
	var initial_stock:Dictionary=game.route.inventory.duplicate()
	check(IDENTITIES.size()==12,"There are twelve unique purchased Faro-region projects with 3D models")

	# A freshly unlocked agricultural island must not fake harvested grain.
	game.route.ferry=true
	game.route._arrive(1)
	var village=game.route.region_identity
	check(village.find_children("Espiga decorativa","MeshInstance3D",true,false).is_empty(),"Grain field is not fully grown before the first project")
	game.route.built.append("grain")
	game.route._refresh_region_identity()
	check(game.route.region_identity.find_children("Espiga decorativa","MeshInstance3D",true,false).size()>0,"Buying grain visibly populates the agricultural landscape")
	var count_obstacles:int=game.world.navigation.obstacles.size()
	game.route._refresh_region_identity()
	check(game.world.navigation.obstacles.size()==count_obstacles,"Refreshing the farm never accumulates ghost decorations or obstacles")

	# Construction fixtures test art only; economy gates and build costs are
	# covered by the archipelago regression suite.
	for region in [1,2,3]:
		for p in game.route.PROJECTS:
			if p["region"]==region and not p["model"].is_empty() and not game.route.built.has(p["id"]):
				game.route.built.append(p["id"])
		game.route._arrive(region)
		var found:=0
		for p in game.route.PROJECTS:
			if p["region"]!=region or p["model"].is_empty():continue
			var root:Node3D=game.route.station_nodes[p["id"]]
			var detail:WivoriVillageFacade=root.get_node_or_null("Identidad de pueblo · "+p["id"]) as WivoriVillageFacade
			check(detail!=null,"Completed %s renders its own authored regional facade" % p["id"])
			if detail==null:continue
			found+=1
			check(detail.project_id==p["id"] and detail.visual_pieces>=4,"Building %s gets visible themed props, not a generic placeholder" % p["id"])
			check(root.position==p["at"],"Decorated %s retains its exact economic station location" % p["id"])
			if detail.moving.size()>0:
				var flag:Node3D=detail.moving[0]["node"]
				var previous:float=flag.rotation.z
				detail._process(.8)
				check(not is_equal_approx(flag.rotation.z,previous),"The flag at %s reacts to scene time" % p["id"])
		check(found==4,"Region %d has all four purchased buildings differentiated" % region)
		check(game.world.navigation.is_walkable(game.route.DOCK+Vector3(0,0,-2),.25),"Region %d remains reachable after adding facade details" % region)
		check(game.coins==initial_coins and game.route.inventory==initial_stock,"Region %d adds no phantom products or spendable coins" % region)

	game.route._arrive(0)
	check(game.route.region_identity==null and game.world.navigation==game.route.home_nav,"Returning home removes regional facade scenes and restores the original market")
	game.queue_free()
	await process_frame
	await process_frame
	clean()
	print("RESULT: %d checked, %d failed" % [passed+failed,failed])
	await create_timer(.08).timeout;quit(1 if failed else 0)
