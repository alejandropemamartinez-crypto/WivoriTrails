extends SceneTree

const Store=preload("res://scripts/save_store.gd")
var game: Node3D
var checks := 0
var failures := 0
var test_path := "user://wivori_progression_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks+=1
	if condition:print("PASS: ",message)
	else:failures+=1; push_error("FAIL: "+message)

func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))

func start() -> void:
	game=load("res://Main.tscn").instantiate(); game.save_path=test_path
	root.add_child(game); game.set_process(false); game.world.set_process(false)
	await process_frame

func stop() -> void:
	game.queue_free(); await process_frame; await process_frame

func step(delta: float, buyers: bool=true) -> void:
	game.world._process(delta)
	game._process_player(delta)
	game._process_helpers(delta)
	if buyers:
		game._process_customers(delta)
		game.customers_timer-=delta
		if game.customers_timer<=0:game._spawn_customer(); game.customers_timer=3.4
	game._refresh_ui()

func run() -> void:
	clean(); await start()
	game.player.position=Vector3(0,0,4)
	game.input_stick.axis=Vector2.DOWN; game._process_player(.5)
	check(is_equal_approx(game.player.position.z,7.4),"Base movement covers 3.4 world units in half a second")
	game.player.position=Vector3(0,0,4); game.boost_active=true; game._process_player(.5)
	check(is_equal_approx(game.player.position.z,9.1),"Holding run adds fifty percent speed without changing joystick direction")
	game.input_stick._clear(); game.boost_active=false; game.player.position=Vector3(0,0,4)
	game._refresh_ui()
	check(game.trail.visible and game.trail.arrows[0].visible,"The first route is visible before pressing the guide button")
	var pads_reachable := true
	for kind in game.UPGRADE_POS:
		var route: PackedVector3Array=game.world.navigation.find_path(game.player.position,game.UPGRADE_POS[kind])
		pads_reachable=pads_reachable and not route.is_empty() and game.world.navigation.is_walkable(game.UPGRADE_POS[kind])
	check(pads_reachable,"Every upgrade pad has a reachable unobstructed interaction point")
	game.player.position=Vector3(4,0,4)
	game.trail.update_route({"target":Vector3(4,0,-6)})
	var arrows_clear := true
	for arrow in game.trail.arrows:
		if arrow.visible:arrows_clear=arrows_clear and game.world.navigation.is_walkable(arrow.position)
	check(arrows_clear,"Ground arrows follow the route around the solid market")
	game.player.position=Vector3(0,0,4); game._refresh_ui()
	game._follow_objective()
	var elapsed := 0.0
	while game._total_bag()<6 and elapsed<15:step(.1); elapsed+=.1
	check(game._current_objective()["button"]=="ENTREGAR","Collecting six products changes the lesson to delivery")
	game._follow_objective()
	while game._total_bag()>0 and elapsed<25:step(.1); elapsed+=.1
	while game.coins<80 and elapsed<40:step(.1); elapsed+=.1
	check(game.coins>=80 and elapsed<35,"Guided first harvest and real customer sales unlock automation within 35 simulated seconds")
	game.event_fade=0; game.director.tick(.2)
	check(game.director.announcement_count==1 and game.event_label.text.contains("YA PODÉS"),"Reaching the first upgrade price announces the investment")
	for i in range(30):
		game.event_fade=0; game.director.tick(1)
	check(game.director.announcement_count==1,"An affordable tier is not announced again each frame or after its cooldown")
	var wallet: int=game.coins
	game._follow_objective()
	check(game.coins==wallet and game.worker_count==0 and game.tap_destination.distance_to(game.UPGRADE_POS["helper"])<.1,"Affordable guidance routes to the hiring pad without spending")
	for i in range(120):game._process_player(.1)
	game._refresh_ui()
	check(game.active_pad=="helper" and game.hud.pad_panel.visible and game.worker_count==0,"Standing on a pad opens its benefit and price without buying automatically")
	game._purchase_nearby()
	check(game.worker_count==1 and game.coins==wallet-80,"Explicit nearby purchase hires one worker and subtracts the displayed price")
	game.helpers[0]["state"]="to_store"; game.helpers[0]["cargo"]="tomato"; game.helpers[0]["cargo_amount"]=3
	game.helpers[0]["actor"].position=Vector3(0,0,3.3)
	var stock_before: int=game.counter["tomato"]
	game._process_helpers(1)
	check(game.counter["tomato"]==stock_before+3,"Faster helpers complete a four-unit delivery within one second")
	await stop(); clean(); await start()
	for i in range(9):game._spawn_customer()
	check(game._queue_count()==6,"Arriving customers reserve six queue slots without exceeding capacity")
	for i in range(100):game._process_customers(.1)
	check(game._waiting_count()==6 and game.sold==0,"Six shoppers occupy distinct waiting positions and cannot buy absent stock")
	check(game.director.alert().get("id")=="empty","An empty market produces a replenishment alert")
	game.stash["tomato"]=2
	game._follow_alert()
	check(game.tap_destination==Vector3(4,0,2.5) and game._current_objective()["target"]==game.tap_destination,"Replenishment alert and visible route point to the same delivery destination")
	game.stash["tomato"]=0; game.counter["tomato"]=100
	check(game.director.alert().get("id")=="queue","Stocked crowded queues identify checkout speed as the bottleneck")
	game.coins=1000; game._buy("helper")
	var offer: String=game.director.recommended()
	game.counter["tomato"]=0
	check(offer=="checkout" and game.director.recommended()==offer,"An affordable investment keeps its destination when stock temporarily runs out")
	game.counter["tomato"]=100
	game._process_customers(1)
	check(game.total_buyers==0,"Only the front customer can begin a timed checkout")
	game.coins=1000; game._buy("checkout")
	check(game.checkout_level==1 and is_equal_approx(game._checkout_duration(),2.6),"Checkout investment reduces service time from 4.6 to 2.6 seconds")
	for i in range(47):game._process_customers(.1)
	check(game.total_buyers>=1 and game.total_buyers<=2,"A checkout serves serially instead of paying out the entire queue at once")
	var different := true
	var locations := []
	for c in game.customers:
		if c["stage"]=="leaving":continue
		var at: Vector3=c["actor"].position
		for old: Vector3 in locations:
			if at.distance_to(old)<.7:different=false
		locations.append(at)
	check(different,"Waiting customers advance without sharing the same queue position")
	for kind in game.counter:game.counter[kind]=0
	var previous_sales: int=game.sold
	for i in range(80):game._process_customers(.1)
	check(game.sold==previous_sales,"An empty counter cannot create phantom sales after the queue advances")
	await stop(); clean()
	Store.write_data(test_path,{"version":2,"coins":80,"player_speed":5.42,"speed_cost":205})
	await start()
	check(is_equal_approx(game.player_speed,7.72),"v2 speed migration adds the new base while preserving purchased bonuses")
	game.event_fade=0; game.director.tick(.2); game._save_progress()
	await stop(); await start()
	check(is_equal_approx(game.player_speed,7.72),"Reloading v3 never applies the base-speed migration twice")
	game.event_fade=0; game.director.tick(.2)
	check(game.director.announcement_count==0,"Saved affordability announcements do not replay on every launch")
	game.coins=1000; game._buy("checkout"); game._save_progress()
	await stop(); await start()
	check(game.checkout_level==1 and is_equal_approx(game._checkout_duration(),2.6),"The checkout upgrade survives a scene restart")
	await stop(); clean()
	print("RESULT: %d progression checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
