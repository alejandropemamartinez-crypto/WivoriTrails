extends SceneTree

# Prepared only: do not run with Godot until the author authorizes QA.
# Regressions for visible coins, single money ownership, ferry transitions
# and reloading while a local-market coin flight is still pending.
var game: Node3D
var checks:=0
var failed:=0
var path: String="user://wivori_cross_island_cash_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, message: String) -> void:
	checks+=1
	if ok:print("PASS: ",message)
	else:failed+=1;push_error("FAIL: "+message)

func clean() -> void:
	for part in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+part))

func start() -> void:
	game=load("res://Main.tscn").instantiate()
	game.save_path=path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame

func reload() -> void:
	check(game._save_progress(),"Mid-flight cash can be saved")
	game.queue_free()
	await process_frame
	await process_frame
	await start()

func arrive(destination: int) -> void:
	var route=game.route
	game.player.position=route.DOCK if route.away() else route.HOME_DOCK
	check(route.travel(destination),"The ferry can depart for village %d" % destination)
	route.tick(1.4)
	check(route.region==destination,"Boat arrives in village %d" % destination)

func run_tests() -> void:
	clean()
	await start()
	var route=game.route
	route.ferry=true
	route.stage=route.PROJECTS.size()
	for p in route.PROJECTS:route.built.append(p["id"])
	var opening_wallet:int=game.coins
	await arrive(4)
	check(not game.cash.visible and game.cash.process_mode==Node.PROCESS_MODE_DISABLED,"The original market registers are hidden on remote islands")
	game.player.position=route.MARKET+Vector3(.8,0,0)
	route.market_money[4]=92
	var before_fx:int=route.get_child_count()
	route.tick(.05)
	check(route.market_money[4]==0 and game.cash.player_held==92 and game.coins==opening_wallet,"Taking local cash moves 92 coins to in-flight funds, never the wallet")
	check(route.get_child_count()>before_fx,"Local pickup FX belongs to the visible, persistent route rather than hidden home cash node")
	await reload()
	route=game.route
	check(route.region==4 and game.cash.player_held==92 and game.coins==opening_wallet,"Reloading Forja mid-pickup preserves the uncredited exact amount")
	route.tick(1.15)
	check(game.cash.player_held==0 and game.coins==opening_wallet+92,"After visual travel, Forja credits exactly once")
	route.tick(1.15)
	check(game.coins==opening_wallet+92,"Repeated ticks cannot replay collected industrial cash")
	await arrive(1)
	game.player.position=route.MARKET+Vector3(.8,0,0)
	route.market_money[1]=67
	route.tick(.06)
	check(game.cash.player_held==67 and game.coins==opening_wallet+92,"Villa Miga cash pickup also waits for animation to complete")
	await arrive(0)
	check(game.coins==opening_wallet+92 and game.cash.player_held==67,"Sailing home does not duplicate a still-flying remote payout")
	game.cash.tick(1.12)
	check(game.coins==opening_wallet+159 and game.cash.player_held==0,"Returning home correctly settles the remote in-transit payment once")
	game.cash.tick(1.12)
	check(game.coins==opening_wallet+159,"Treasury and local island payouts cannot double-count")

	game.queue_free()
	await process_frame
	await process_frame
	clean()
	print("RESULT: %d cash crossing checks, %d failures" % [checks,failed])
	quit(1 if failed>0 else 0)
