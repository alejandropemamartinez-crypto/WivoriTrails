extends SceneTree

var game: Node3D
var checks:=0
var failures:=0
var test_path: String="user://wivori_production_%d.json" % OS.get_process_id()

func _initialize() -> void:call_deferred("run_tests")
func check(condition: bool, message: String) -> void:
	checks+=1
	if condition:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))
func start() -> void:
	game=load("res://Main.tscn").instantiate();game.save_path=test_path;root.add_child(game);game.set_process(false);game.world.set_process(false);await process_frame
func stop() -> void:game.queue_free();await process_frame;await process_frame

func run_tests() -> void:
	clean();await start()
	for animal in ["scottie","rabbit","raccoon"]:
		var actor: MarketActor=game.ActorScript.new();actor.setup("customer",Color("#4c8e8b"),animal);game.add_child(actor)
		var complete:=actor.skeleton!=null and actor.head_mesh.skin!=null
		for clip in ["idle","walk","run","turn","harvest","carry","deliver","collect","celebrate","surprise","intercept","build"]:
			complete=complete and actor.animator.has_animation(clip) and actor.animator.get_animation(clip).get_track_count()>0
		check(complete,"%s has a real weighted skeleton and all twelve action clips" % animal)
		actor.queue_free()
	var wallet: int=game.coins
	game._record_sale(1,40)
	game.player.position=game.cash.REGISTERS[0]+Vector3(1.3,0,0)
	game.cash.tick(.01)
	check(game.coins==wallet and game.cash.player_held==40 and game.cash.total_pending()==0,"Money has one owner during a player pickup and remains unspendable")
	game._save_progress();await stop();await start()
	check(game.coins==wallet and game.cash.player_held==40,"Closing during a coin flight preserves its cash without early credit")
	game.cash.tick(.3)
	check(game.coins==wallet,"Resumed money still waits for visual travel time")
	game.cash.tick(.8)
	check(game.coins==wallet+40 and game.cash.player_held==0,"The resumed pickup credits exactly on arrival")
	for i in range(12):game.cash.tick(.1)
	check(game.coins==wallet+40,"Repeated nearby ticks cannot duplicate a completed pickup")
	game.coins=2000;game.run.level=1;game._toggle_build_mode()
	game.town.select_at(game.town.LOCATIONS[3])
	check(not game.town.build("bakery") and game.coins==2000,"A locked district cannot consume construction money")
	game.town.select_at(game.town.LOCATIONS[0]);game.town.build("house")
	var after_build: int=game.coins
	check(game.town.begin_move(),"Selecting an owned building starts explicit relocation")
	check(game.town.select_at(game.town.LOCATIONS[1]) and game.town.constructed[0].is_empty() and game.town.constructed[1]=="house","Relocation transfers the existing building to a free open plot")
	check(game.coins==after_build and game.town.constructed.count("house")==1,"Relocation neither charges again nor duplicates a building bonus")
	check(game.world.navigation.is_walkable(game.town.LOCATIONS[0]) and not game.world.navigation.is_walkable(game.town.LOCATIONS[1]),"Relocation frees the old collision and blocks the new footprint")
	game._save_progress();await stop();await start()
	check(game.town.constructed[0].is_empty() and game.town.constructed[1]=="house" and game.coins==after_build,"Relocated buildings and their cost survive a restart")
	game.coins=1800;game.player.position=Vector3(0,0,18);game.cash.hire_collector()
	game.cash.pending[0]=56
	game.cash.collector.position=game.cash.REGISTERS[0]+Vector3(0,0,1)
	var before_bank: int=game.coins
	game.cash.tick(.1);game.cash.tick(.1)
	check(game.cash.collector_state=="collecting" and game.cash.collector_held==56 and game.cash.collector.money_bag.visible,"Courier bends to collect with a visible money bag")
	check(game.coins==before_bank,"A courier pickup cannot credit the treasury remotely")
	game.cash.tick(.9)
	game.cash.collector.position=game.cash.BANK+Vector3(1.2,0,.2)
	game.cash.tick(.1)
	check(game.cash.collector_state=="deposit" and game.coins==before_bank,"Reaching treasury starts a physical deposit before spending is allowed")
	game._save_progress();await stop();await start()
	check(game.cash.collector_state=="deposit" and game.cash.collector_held==56,"A deposit in progress survives reloading")
	game.cash.tick(.3)
	check(game.coins==before_bank,"Reloading a deposit never skips the remaining transfer")
	game.cash.tick(.8)
	check(game.coins==before_bank+56 and game.cash.collector_held==0,"Completed courier deposit credits the held amount once")
	game.player.position=Vector3(0,0,18);game.move_velocity=Vector3.ZERO;game.player_speed=game.MAX_SPEED;game.boost_active=true
	game.input_stick.axis=Vector2.RIGHT*.2
	for i in range(30):game._process_player(.016)
	check(game.move_velocity.length()<2.0 and game.move_velocity.length()>1.0,"Partial joystick travel remains proportional at maximum upgraded sprint")
	var initial_speed: float=game.move_velocity.length();var at: Vector3=game.player.position
	game.input_stick._clear();game._process_player(.016)
	check(game.move_velocity.length()>0 and game.move_velocity.length()<initial_speed,"Releasing movement decelerates smoothly")
	for i in range(20):game._process_player(.016)
	check(game.move_velocity==Vector3.ZERO and game.player.position.distance_to(at)<.10,"Braking settles promptly without overshooting a nearby interaction")
	game.hud.rabbit_banner.last_phase="escape";game.hud.rabbit_banner.recovered(4);game.hud.rabbit_banner.sync_state("")
	check(game.hud.rabbit_banner.visible and game.hud.rabbit_banner.relieved and game.hud.rabbit_banner.lifetime>2,"Recovered goods trigger a complete rabbit relief reaction")
	await stop();clean()
	print("RESULT: %d production checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
