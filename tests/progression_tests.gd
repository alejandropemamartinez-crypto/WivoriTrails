extends SceneTree

const Store=preload("res://scripts/save_store.gd")
var game: Node3D
var checks:=0
var failures:=0
var test_path: String="user://wivori_levels_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run_tests")
func check(condition: bool,message: String) -> void:
	checks+=1
	if condition:print("PASS: ",message)
	else:failures+=1; push_error("FAIL: "+message)
func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))
func start() -> void:
	game=load("res://Main.tscn").instantiate(); game.save_path=test_path; root.add_child(game)
	game.set_process(false); game.world.set_process(false); await process_frame
func stop() -> void:game.queue_free(); await process_frame; await process_frame
func run_tests() -> void:
	clean(); await start()
	game.player.position=Vector3(0,0,4); game.input_stick.axis=Vector2.DOWN; game._process_player(.5)
	check(absf(game.player.position.z-7.4)<.02,"Manual movement retains controllable acceleration and base speed")
	game.input_stick._clear(); var at: Vector3=game.player.position
	game._follow_objective(); game._set_tap_goal(Vector2(500,600))
	for i in range(60):game._process_player(.1)
	check(game.player.position.distance_to(at)<.08 and not game.has_tap_destination,"Guides and terrain taps cannot create player autopilot")
	check(game.trail.visible and game.trail.arrows[0].visible,"Spatial guidance remains visible without moving the protagonist")
	var reachable:=true
	for kind in game.UPGRADE_POS:reachable=reachable and not game.world.navigation.find_path(game.player.position,game.UPGRADE_POS[kind]).is_empty()
	check(reachable,"All economic and defensive upgrade sites are reachable")
	game.coins=5000; var wallet: int=game.coins; game._buy("guard")
	check(game.coins==wallet and game.run.guard_level==0,"Defenses cannot be bought before their level unlock")
	game._buy("helper"); game.sold=12
	check(not game.run.complete(),"Automatic sales alone cannot complete the manual delivery goal")
	game.player.position=Vector3(4,0,2.5); game.stash["tomato"]=6; game._process_player(.1)
	check(game.run.complete(),"First level requires sales, a worker and a real player delivery")
	wallet=game.coins
	check(game.run.advance() and game.run.level==2 and game.coins==wallet+80,"Completing a level awards its reward and opens the next objectives")
	wallet=game.coins; game.run.advance()
	check(game.run.level==2 and game.coins==wallet,"Repeated continue actions cannot duplicate a level reward")
	var manual: int=game.manual_delivered
	game.helpers[0]["actor"].position=Vector3(4,0,3.3); game.helpers[0]["state"]="to_store"; game.helpers[0]["cargo"]="carrot"; game.helpers[0]["cargo_amount"]=3
	game._process_helpers(.1)
	check(game.manual_delivered==manual and game.counter["carrot"]==3,"Worker automation never counts as player delivery")
	game._buy("helper"); game.sold+=18; game.manual_delivered+=12
	check(game.run.advance() and game.run.level==3 and not game._upgrade("lock")["locked"],"Third level introduces the storage defense and raid goals")
	game.run.warning=2; game.run.next_raid=0; game.run.tick(2.1)
	check(game.run.raiders.size()==1,"The first raid arrives after its visible warning")
	for raid in game.run.raiders:raid["actor"].queue_free()
	game.run.raiders.clear()
	game.counter["tomato"]=12; game.counter["carrot"]=0
	game.run._spawn_raider(Vector3(20,0,-9))
	var raid: Dictionary=game.run.raiders[0]; raid["actor"].position=game.run.STOCK
	game.run.tick(.1)
	check(raid["state"]=="tamper" and game.counter["tomato"]==12,"A thief must first spend time opening the storage")
	game._buy("lock")
	check(is_equal_approx(raid["remaining"],8),"Buying a lock gives extra response time even during a theft attempt")
	game.run.tick(7.8)
	check(game.counter["tomato"]==12,"The reinforced lock prevents immediate theft")
	game.run.tick(.3)
	check(game.counter["tomato"]==8 and raid["amount"]==4 and raid["state"]=="escape","A successful attempt transfers bounded real stock into the fleeing thief's bag")
	game._save_progress(); wallet=game.coins
	await stop(); await start()
	raid=game.run.raiders[0]
	check(raid["state"]=="escape" and raid["amount"]==4 and game.counter["tomato"]==8,"Reload preserves stolen cargo without restoring or duplicating it")
	game.player.position=Vector3(-8,0,0)
	check(not game.run.intercept() and game.counter["tomato"]==8,"A distant player cannot repel thieves remotely")
	game.player.position=raid["actor"].position+Vector3(2,0,0); game.run.intercept()
	check(game.run.blocked==1 and game.counter["tomato"]==12 and game.coins==wallet,"Nearby interception returns the stolen products without inventing coins")
	game.run.intercept(); game._save_progress(); await stop(); await start()
	check(game.counter["tomato"]==12 and game.run.blocked==1,"Repeated interception and reload cannot recover the same cargo twice")
	for old in game.run.raiders:old["actor"].queue_free()
	game.run.raiders.clear(); game.counter["tomato"]=9
	game.run._spawn_raider(Vector3(20,0,-9)); raid=game.run.raiders[0]
	raid["state"]="escape"; raid["cargo"]="tomato"; raid["amount"]=3; raid["actor"].position=raid["entry"]
	game.run.tick(.1)
	check(game.run.escaped==1 and game.run.lost==3 and game.counter["tomato"]==9,"Escaping removes only already-carried stock and leaves the game playable")
	game.run.level=4; game.coins=5000; game._buy("guard"); game.run._tick_guard(0)
	game.run._spawn_raider(Vector3(20,0,-9)); game.run.raiders[0]["actor"].position=game.run.guard.position+Vector3(1,0,0)
	game.run._tick_guard(.1)
	check(game.run.raiders[0]["state"]=="retreat" and game.run.guard_cooldown>0,"The visible guard physically intercepts a nearby thief and then needs recovery")
	game.run._spawn_raider(Vector3(-19,0,-12)); var second: Dictionary=game.run.raiders[-1]
	second["actor"].position=game.run.guard.position+Vector3(1.2,0,0); game.run._tick_guard(.1)
	check(second["state"]!="retreat","A recovering guard cannot instantly neutralize an entire wave")
	game.run.guard_cooldown=9.0; game._save_progress(); await stop(); await start()
	check(is_equal_approx(game.run.guard_cooldown,9) and game.run.guard_level==1,"Guard recovery and defense purchases survive reload")
	game.player.position=game.run.CART; game.stash["apple"]=10; wallet=game.coins
	var pending_before: int=game.cash.total_pending()
	check(game.run.deliver_contract()==8 and game.coins==wallet and game.cash.total_pending()==pending_before+224 and game.stash["apple"]==2,"Premium contracts pay collectible money into cashier rather than wallet")
	wallet=game.coins
	check(game.run.deliver_contract()==0 and game.coins==wallet and game.cash.total_pending()==pending_before+224,"A fulfilled premium contract cannot pay again")
	game._save_progress(); await stop(); await start()
	check(game.run.level==4 and game.run.contract_done==8 and game.stash["apple"]==2,"The level and premium order progress persist alongside inventory")
	for old in game.run.raiders:old["actor"].queue_free()
	game.run.raiders.clear(); game._buy("expand"); game.run.blocked=game.run.start_blocked+1
	check(game.run.advance() and game.run.level==5 and game.run.contract_done==0,"Completing the orchard chapter opens a new export contract")
	game.run.contract_done=12; game.shipments_completed+=1; game._buy("pier"); game.run.blocked=game.run.start_blocked+2
	check(game.run.advance() and game.run.level==6,"Export, premium delivery and interception goals unlock chapter six")
	game._buy("alarm"); game.run.contract_done=16; game.run.blocked=game.run.start_blocked+2
	check(game.run.advance() and game.run.level==7,"Completing the six introductory chapters opens continuing contracts")
	game.run.level=7; var first_kind: String=game.run.contract_kind(); var first_goal: int=game.run.contract_goal()
	game.run.level=8
	check(game.run.contract_kind()!=first_kind and game.run.contract_goal()>first_goal,"Later levels rotate requested products and increase their goals")
	var actor: MarketActor=game.player
	actor.action_left=0;actor.last_position=actor.position; actor.position+=Vector3(.2,0,0); actor.walk_to(Vector3.RIGHT,6.8); actor._process(.05)
	var left_pose:=actor.skeleton.get_bone_pose_rotation(actor.skeleton.find_bone("leg.L"))
	var right_pose:=actor.skeleton.get_bone_pose_rotation(actor.skeleton.find_bone("leg.R"))
	check(actor.current_clip in ["walk","carry"] and left_pose.angle_to(right_pose)>.05,"Actual skeletal leg poses oppose each other during distance-driven walking")
	for i in range(90):actor._process(.016)
	check(actor.walk_amount<.01,"Releasing movement blends the character back to idle")
	await stop(); clean()
	Store.write_data(test_path,{"version":3,"coins":300,"worker_count":2,"orchard_owned":true,"player_speed":7.72})
	await start()
	check(game.run.level==4 and game.helpers.size()==2 and is_equal_approx(game.player_speed,7.72),"v3 migration preserves purchases and starts at the matching new chapter")
	check(game.manual_delivered==0 and game.run.contract_done==0,"Old automatic delivery totals cannot pre-complete new manual goals")
	await stop(); clean()
	print("RESULT: %d progression and defense checks, %d failures" % [checks,failures]); await create_timer(.08).timeout;quit(1 if failures else 0)
