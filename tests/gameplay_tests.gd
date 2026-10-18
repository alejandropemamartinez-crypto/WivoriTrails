extends SceneTree

const Store = preload("res://scripts/save_store.gd")
var game: Node3D
var failures := 0
var checks := 0
var test_path := "user://wivori_tests_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func clean_files() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + suffix))

func start_game() -> void:
	game = load("res://Main.tscn").instantiate()
	game.save_path = test_path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame

func stop_game() -> void:
	game.queue_free()
	await process_frame
	await process_frame

func run() -> void:
	clean_files()
	await start_game()
	check(game.coins == 50 and game.world.crop_spots.size() == 27, "Fresh game starts with 50 coins and three fields")

	game.player.position = Vector3(-8, 0, 0)
	for i in range(32):
		game.world._process(.4)
		game._process_player(.4)
	var bag: int = game._total_bag()
	check(bag == 12, "Manual harvesting fills the bag without exceeding capacity")
	game.player.position = Vector3(4, 0, 2.5)
	game._process_player(.4)
	check(game._total_stock() == bag and game._total_bag() == 0 and game.delivered == bag, "Delivery transfers and counts the complete bag")
	for i in range(500):
		if i % 46 == 0: game._spawn_customer()
		game._process_customers(.1)
	check(game.sold == bag and game.coins > 50, "Shoppers reach the stall, buy the harvest and pay")

	game.player.position = Vector3(4, 0, 4)
	game._set_world_goal(Vector3(4, 0, -6))
	for i in range(100):game._process_player(.1)
	check(game.player.position.distance_to(Vector3(4,0,4))<.01 and not game.has_tap_destination, "A terrain marker cannot start automatic player travel")
	game.player.position = Vector3(4, 0, 4)
	game.input_stick.axis = Vector2.UP
	game._process_player(4.0)
	check(game.world.navigation.is_walkable(game.player.position) and game.player.position.z > -.1, "A large frame cannot push joystick movement through the stall")
	game.input_stick._clear()

	var coins_before: int = game.coins
	game._buy("not-an-upgrade")
	check(game.coins == coins_before, "Unknown upgrades cannot charge the player")
	game.coins = 0
	game._buy("helper")
	check(game.coins == 0 and game.helpers.is_empty(), "Unaffordable upgrades do not charge or spawn helpers")
	game.coins = 5000
	game._buy("helper")
	game._buy("helper")
	var sales_before: int = game.sold
	for i in range(1800):
		game.world._process(.1)
		game._process_helpers(.1)
		game._process_customers(.1)
		if i % 46 == 0: game._spawn_customer()
		if i % 150 == 0: await process_frame
	check(game.helpers.size() == 2 and game.sold > sales_before, "Two hired helpers produce sales without player input")
	var actor: Node3D = game.helpers[0]["actor"]
	actor.position = Vector3(13, 0, -13)
	actor.remove_meta("route_goal")
	var route_free := true
	var reached := false
	for i in range(300):
		reached = game._move_actor(actor,Vector3(4,0,3.3),2.8,.1)
		route_free = route_free and game.world.navigation.is_walkable(actor.position)
		if reached: break
	check(route_free and reached, "Helper routes from the orchard around the solid stall")

	game.coins = 5000
	game._buy("expand")
	game.world.open_orchard()
	check(game.world.crop_spots.size() == 36, "Opening an orchard twice does not duplicate its crops")
	var all_fields_reachable := true
	for crop in game.world.crop_spots:
		var start := Vector3(4,0,3.3)
		var route: PackedVector3Array=game.world.navigation.find_path(start,crop["node"].global_position)
		all_fields_reachable=all_fields_reachable and not route.is_empty()
		for point in route:
			all_fields_reachable=all_fields_reachable and game.world.navigation.segment_clear(start,point)
			start=point
	check(all_fields_reachable, "All 36 crop positions have clear routes from the delivery point")
	game._buy("pier")
	game.sold = 0
	game.quest_level = 1
	game.coins = 100
	for kind in game.counter: game.counter[kind] = 0
	game.counter["tomato"] = 8
	game._process_shipping(.1)
	check(game.shipment["kind"] == "", "The dock waits until it can preserve the local reserve")
	game.counter["tomato"] = 9
	game._process_shipping(.1)
	check(game.shipment["kind"] == "tomato" and game.counter["tomato"] == 3, "The dock loads six products and leaves three for local shoppers")
	game._process_shipping(30)
	game._process_shipping(30)
	check(game.coins == 154 and game.shipments_completed == 1 and game.sold == 6, "Shipment pays the 50 percent premium exactly once")

	# Persist both a loaded helper and a separate boat cargo. Neither may vanish
	# or be counted twice after the actual scene is destroyed and re-created.
	game.helpers[1]["actor"].queue_free()
	game.helpers.remove_at(1)
	game.worker_count = 1
	game.helpers[0]["cargo"] = "berry"
	game.helpers[0]["cargo_amount"] = 3
	game.helpers[0]["state"] = "to_store"
	game.helpers[0]["actor"].position = Vector3(13,0,-13)
	game.counter["berry"] = 0
	game.stash["apple"] = 2
	game.counter["tomato"] = 9
	game._process_shipping(.1)
	game._process_shipping(5)
	game.world.harvest(game.world.crop_spots[0])
	check(game._save_progress(), "Atomic save writes successfully")
	check(game._save_progress(), "A second save preserves a readable backup")
	var saved_coins: int = game.coins
	await stop_game()
	await start_game()
	check(game.helpers[0]["cargo"] == "berry" and game.helpers[0]["cargo_amount"] == 3 and game.helpers[0]["state"] == "to_store", "Reload restores the helper's cargo and delivery task")
	check(game.stash["apple"] == 2 and game.counter["tomato"] == 3 and not game.world.crop_spots[0]["ready"], "Reload preserves bag, stock and crop regrowth")
	check(game.shipment["kind"] == "tomato" and is_equal_approx(float(game.shipment["remaining"]),25), "Reload preserves the boat cargo and remaining travel time")
	for i in range(300):
		game._process_helpers(.1)
		if game.helpers[0]["cargo"] == "": break
	check(game.counter["berry"] == 3 and game.helpers[0]["cargo"] == "", "Restored helper delivers its cargo once and clears the carried goods")
	game._process_shipping(25)
	game._process_shipping(25)
	check(game.coins == saved_coins+54 and game.shipments_completed == 2, "Restored shipment pays once without duplicating stock")

	game.input_stick.axis = Vector2.ONE
	game.boost_active = true
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.input_stick.axis == Vector2.ZERO and not game.boost_active, "Pausing clears touch movement and running")
	game._save_progress()
	var recovery_coins: int = game.coins
	var broken := FileAccess.open(test_path,FileAccess.WRITE)
	broken.store_string("{interrupted save")
	broken.close()
	await stop_game()
	await start_game()
	check(game.coins == recovery_coins and game.pier_owned, "A damaged primary save recovers from the last valid backup")
	await stop_game()
	clean_files()

	check(Store.write_data(test_path,{"version":1,"coins":345,"worker_count":1,"orchard_owned":true,"stash":{"carrot":2},"counter":{"berry":5}}), "An existing v1 save can be written for migration")
	await start_game()
	check(game.coins == 345 and game.helpers.size() == 1 and game.stash["carrot"] == 2 and game.counter["berry"] == 5 and game.world.crop_spots.size() == 36, "v1 migration preserves progress and unlocked orchard")
	await stop_game()
	clean_files()
	Store.write_data(test_path,{"version":2,"coins":-50,"worker_count":999999,"player_speed":"fast","stash":[],"counter":"bad","helpers":{},"player_pos":["bad",9999]})
	await start_game()
	check(game.coins == 0 and game.worker_count == game.MAX_HELPERS and is_equal_approx(game.player_speed,game.BASE_SPEED) and game._total_bag() == 0 and absf(game.player.position.z)<=23, "Malformed fields load safely with bounds and defaults")
	await stop_game()
	clean_files()

	await start_game()
	game.coins=2000
	game._toggle_build_mode()
	check(game.town.in_build_mode and game.hud.town_panel.visible, "Construction toggles the aerial village view and opens the build controls")
	check(game.town.constructed.size()==9 and game.town.constructed[0]=="", "New market offers nine expandable, genuinely empty plots")
	game.town.select_at(game.town.LOCATIONS[0])
	var price_before: int=game.coins
	check(game.town.build("house") and game.coins==price_before-180, "A house is explicitly purchased at the selected site once")
	check(not game.town.build("house") and game.coins==price_before-180, "Repeated taps cannot purchase the same plot again")
	game.town.select_at(game.town.LOCATIONS[1])
	check(game.town.build("cafe"), "Coffee shop can be built on a different plot")
	var earnings_before: int=game.coins
	game._record_sale(1,10)
	check(game.coins==earnings_before+12, "Village coffee shop boosts actual sales by precisely 20 percent")
	game.town.select_at(game.town.LOCATIONS[2])
	var capacity_before: int=game.max_capacity
	check(game.town.build("depot") and game.max_capacity==capacity_before+6, "Building the depot raises playable carrying capacity")
	game._toggle_build_mode()
	check(not game.town.in_build_mode and game.hud.run_button.visible, "Leaving city mode restores direct character controls")
	var village_money: int=game.coins
	game._save_progress()
	await stop_game()
	await start_game()
	check(game.town.has_building("house") and game.town.has_building("cafe") and game.town.has_building("depot"), "Reload reconstructs all three visible town structures")
	check(game.coins==village_money and game.max_capacity==capacity_before+6, "Reload preserves village purchases without charging or granting capacity twice")
	game.coins=15000
	game._toggle_build_mode()
	var bonus_before: int=game._total_bag()
	game.town.select_at(game.town.LOCATIONS[3])
	check(game.town.build("bakery") and game.town.income_bonus(100)==30, "Bakery cumulatively raises cafe revenue from 20 to 30 percent")
	game.town.select_at(game.town.LOCATIONS[4])
	check(game.town.build("greenhouse"), "Greenhouse can be placed in a separate northern village plot")
	var extra_crops:=0
	for n in range(5):
		if game.town.bonus_harvest():extra_crops+=1
	check(extra_crops==1, "Greenhouse awards one extra harvest per five successful actions")
	game.town.select_at(game.town.LOCATIONS[5])
	check(game.town.build("workshop") and is_equal_approx(game.town.player_speed_factor(),1.08), "Road workshop actually increases the controllable hero speed")
	game.town.select_at(game.town.LOCATIONS[6])
	check(game.town.build("park") and game.town.customer_interval_factor()<.75, "Public park and houses combine to attract more visitors")
	game.town.select_at(game.town.LOCATIONS[7])
	check(game.town.build("watchtower") and game.town.warning_seconds()==4.0, "Built lookout adds four seconds of raid warning")
	game.town.select_at(game.town.LOCATIONS[8])
	check(game.town.build("mill") and game.town.shipment_speed_factor()==1.30, "Mill reduces export travel time")
	game._toggle_build_mode()
	game._save_progress()
	await stop_game()
	await start_game()
	check(game.town.constructed.size()==9 and game.town.has_building("mill") and game.town.has_building("greenhouse"), "All expanded districts and purchased utility buildings persist after reload")
	await stop_game()
	clean_files()

	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
