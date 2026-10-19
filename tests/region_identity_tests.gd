extends SceneTree

# Stage 4 regression contract. This checks scenery ownership, visual activity,
# economy isolation and region switching; it does NOT approve visual quality.
var game: Node3D
var passed:=0
var failed:=0
var path: String="user://wivori_region_identity_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, message: String) -> void:
	if ok:
		passed+=1
		print("PASS: ",message)
	else:
		failed+=1
		push_error("FAIL: "+message)

func run_tests() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	game=load("res://Main.tscn").instantiate()
	game.save_path=path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame
	var money:int=game.coins
	var original_inventory: Dictionary=game.route.inventory.duplicate()
	game.route.ferry=true
	# Fixture unlocks the artwork only, without paying, generating or saving
	# inventory. Actual construction gates remain covered by archipelago_tests.
	for key in ["grainmill","cowbarn","dairy","cannery"]:
		game.route.built.append(key)
	var themes: Array[String]=["","Villa Miga · campos dorados","Puerto Nata · pastos y quesería","Bahía Farol · muelles marineros"]
	for area in [1,2,3]:
		game.route._arrive(area)
		var dressing=game.route.region_identity
		check(dressing!=null and dressing.region_index==area,"Area %d has its own authored district identity" % area)
		check(dressing.name==themes[area] and dressing.landmark_count>0,"Area %d contains distinguishing physical props" % area)
		check(game.route.residents.size()==3 and game.route.residents[0]["actor"].ground_sampler.is_valid(),"Village %d residents sample their own island ground elevation" % area)
		var reeds=dressing.get_node_or_null("Juncos costeros · instanciados") as MultiMeshInstance3D
		check(reeds!=null and reeds.multimesh.instance_count==90,"Area %d batches its coastline vegetation" % area)
		check(game.world.navigation.is_walkable(game.player.position,.25),"Area %d restores a walkable arrival" % area)
		check(game.coins==money and game.route.inventory==original_inventory,"Area %d scenery does not touch balances or cargo" % area)
		check(game.route.regional_sale_bonus("milk")== (1.15 if area==2 else 1.0),"Region %d recognizes its local dairy demand" % area)
		var advertised:int=game.route.sale_value("milk")
		check(advertised>0 and advertised==game.route.sale_value("milk"),"Regional sale prices are deterministic before a transaction")
		if area==1:
			check(game.route.processing_visuals.has("flour") and game.route.processing_visuals.has("feed"),"Grainmill uses distinct flour and feed manufacturing props")
			game.route.jobs["flour"]={"remaining":4.0,"ready":0}
			game.route.tick(.12)
			check(game.route.processing_visuals["flour"]["node"].visible,"Running flour batch is depicted on its conveyor")
			check(not game.route.processing_visuals["feed"]["node"].visible,"Inactive feed recipe is not falsely shown as active")
			game.route.jobs.clear()
			check(game.route.regional_sale_bonus("flour")==1.15,"Grain has a commercial premium in farming village")
			game.route.jobs["flour"]={"remaining":.05,"ready":0,"automatic":true}
			var before_events:float=game.event_fade
			game.route.tick(.2)
			check(game.route.jobs["flour"]["ready"]==2,"Automated flour production still generates finished units")
			check(game.event_fade<=before_events,"Automatic workshop completion does not interrupt play with recurring notices")
			game.route.jobs.clear()
		if area==2:
			check(game.route.regional_sale_bonus("cheese")==1.15 and game.route.regional_sale_bonus("wheat")==1.0,"Livestock town rewards dairy and not unrelated grain")
			check(game.route.animals.size()==2,"Livestock is introduced only by the purchased barn")
			check(game.route.processing_visuals.has("cheese"),"Dairy has an active production representation")
			game.route.employees["cheese"]=true
			game.route._spawn_operator("cheese")
			var dairy_root:Node3D=game.route.station_nodes["dairy"]
			var dairy_operator:MarketActor=dairy_root.get_node("Operator_cheese")
			check(dairy_operator.ground_sampler.is_valid(),"Dairy worker gets a correctly bound ground sampler")
			check(absf(float(dairy_operator.ground_sampler.call(dairy_operator.position))-game.route.ground_height(dairy_root.to_global(dairy_operator.position)))<.001,"Translated workshop workers use island-world coordinates for feet")
			var creature:Node3D=game.route.animals[0]["node"]
			var before:Vector3=creature.position
			game.route.tick(.25)
			check(creature.position.distance_to(before)>0.0,"Livestock motion includes walking, not only rigid rotation")
		if area==3:
			check(game.route.processing_visuals.has("provisions"),"Bay cannery has a physical production process")
			var cargo=game.route.region_identity.storage_props
			check(cargo.size()==6,"Farol port models six real-stock display slots")
			var empty:=true
			for crate in cargo:empty=empty and not crate.visible
			check(empty,"The harbor does not invent cargo while the warehouse is empty")
			game.route.inventory["provisions"]=13
			game.route._update_cargo()
			check(cargo[0].visible and cargo[1].visible and cargo[2].visible and not cargo[3].visible,"Thirteen stored units display three cargo containers")
			game.route.inventory["provisions"]=0
			game.route._update_cargo()
			var cleared:=true
			for crate in cargo:cleared=cleared and not crate.visible
			check(cleared,"Removing real stock hides the previously displayed crates")
			check(game.coins==money,"Display updates have no effects on available cash")
	# Return to the original map and ensure decorative nodes are discarded.
	game.route._arrive(0)
	check(game.route.region_identity==null and game.route.processing_visuals.is_empty(),"Return home disposes of off-island scenery and process props")
	check(game.world.visible and game.world.navigation==game.route.home_nav,"Original market and its navigation are restored")
	check(game.coins==money and game.route.inventory==original_inventory,"Sailing decorations never introduce phantom sales or stock")
	game.queue_free()
	await process_frame
	await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d passed, %d failed (not run automatically)" % [passed,failed])
	quit(1 if failed>0 else 0)
