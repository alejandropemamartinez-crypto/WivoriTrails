extends SceneTree

# Art contract only. Not run automatically and not a substitute for rendered
# Godot screenshots or human review of silhouette, rigging and lighting.
const Facade=preload("res://scripts/factory_facade.gd")
const BUILDINGS=["dockworks","packaging_plant","preserves_line","shipping_hub","trade_center"]
var game: Node3D
var failed:=0
var checked:=0
var save_path: String="user://wivori_facades_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run_tests")

func require(ok: bool, message: String) -> void:
	checked+=1
	if ok:print("PASS: ",message)
	else:failed+=1;push_error("FAIL: "+message)

func run_tests() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	game=load("res://Main.tscn").instantiate()
	game.save_path=save_path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame
	var coins:int=game.coins
	var inventory:Dictionary=game.route.inventory.duplicate()
	var before_obstacles:int=game.world.navigation.obstacles.size()
	var tested_silhouettes:Dictionary={}
	for kind in BUILDINGS:
		var site:=Node3D.new()
		site.name="Fábrica ensayada "+kind
		game.route.add_child(site)
		var facade:=Facade.new()
		facade.configure(game.world,kind)
		site.add_child(facade)
		require(facade.name.contains(kind),"Factory %s has an authored recognizable identity" % kind)
		require(facade.window_batches.size()==1 and facade.window_batches[0].multimesh.instance_count==6,"Factory %s uses one batched set of six glazed windows" % kind)
		# The dummy rendering server does not retain MultiMesh transforms.
		# Check the actual GPU buffer in the native visual test instead.
		if DisplayServer.get_name()!="headless":
			require(facade.window_batches[0].multimesh.get_instance_transform(0).origin.z>0.0,"Factory %s windows face the positive-Z player approach, not the back wall" % kind)
		require(facade.moving_parts.size()>0 and facade.is_processing(),"Factory %s has local procedural animation" % kind)
		var moving:Node3D=facade.moving_parts[0]["node"]
		var first:Transform3D=moving.transform
		facade._process(.75)
		require(not moving.transform.is_equal_approx(first),"Factory %s animation changes real 3D transforms" % kind)
		tested_silhouettes[kind]=facade.moving_parts[0]["type"]
		require(game.world.navigation.obstacles.size()==before_obstacles,"Art alone creates no phantom collision in %s" % kind)
		site.free()
	require(tested_silhouettes.size()==5 and ["crane","press","steam","pallet","clock"].all(func(type):return tested_silhouettes.values().has(type)),"Five industrial buildings have five visually different mechanical movements")
	require(game.coins==coins and game.route.inventory==inventory,"Factory visuals never change the game economy or stock")

	# The integrated construction path must attach the authored art to the
	# same root as each imported factory, without unregistered colliders.
	game.route.ferry=true
	game.route.stage=game.route.PROJECTS.size()
	for project in game.route.PROJECTS:game.route.built.append(project["id"])
	game.route._arrive(4)
	for project in game.route.INDUSTRY_PROJECTS:
		game.route.built.append(project["id"])
		game.route._place_project(project,false)
		var plot:Node3D=game.route.station_nodes[project["id"]]
		var authored:Node3D=plot.get_node_or_null("Arquitectura singular · "+project["id"])
		require(authored!=null,"Built %s registers its distinct graphic facade" % project["id"])
	require(game.world.navigation.is_walkable(game.route.DOCK+Vector3(0,0,-2),.25),"Additional visual details keep the boat's arrival navigable")

	game.queue_free()
	await process_frame
	await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	print("RESULT: %d checks, %d failures" % [checked,failed])
	quit(1 if failed>0 else 0)
