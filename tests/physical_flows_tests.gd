extends SceneTree

# Stage 3 contracts: physical effects must not create or duplicate actual money
# and must not modify the inventory. Deferred execution is intentional: this
# suite is versioned but NOT run while the no-build stage is under review.
var game: Node3D
var checks:=0
var failures:=0
var save_path: String="user://wivori_physical_flows_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if condition:
		print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)

func run() -> void:
	game=load("res://Main.tscn").instantiate()
	game.save_path=save_path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame

	var wallet: int=game.coins
	var stock: int=game.counter["tomato"]
	var pending: int=game.cash.total_pending()
	var nodes_before: int=game.get_child_count()
	game._fly_model_goods("goods_wheat",Vector3(-9,1,0),Vector3(4,1,2),20,game.player)
	check(game.get_child_count()==nodes_before+8,
		"Each visible cargo burst is capped to eight imported objects")
	check(game.coins==wallet and game.counter["tomato"]==stock and game.cash.total_pending()==pending,
		"Visual-only cargo movement cannot change money or stock")

	game._record_sale(1,42,Vector3(9,1,-1))
	check(game.coins==wallet and game.cash.total_pending()==pending+42,
		"A sale credits the register ledger, not the spendable wallet")
	game.player.position=game.cash.REGISTERS[0]+Vector3(1.3,0,0)
	game.cash.tick(.01)
	check(game.coins==wallet and game.cash.player_held==42 and game.cash.total_pending()==pending,
		"Physical cash pickup transfers ownership once and waits for arrival")
	game.cash.tick(1.0)
	check(game.coins==wallet+42 and game.cash.player_held==0,
		"Collected money enters the wallet only when the flight completes")
	game.cash.tick(.1)
	check(game.coins==wallet+42 and game.cash.total_pending()==pending,
		"Repeated pickup ticks cannot pay the same stack twice")

	for model_name in ["goods_wheat","goods_flour","goods_feed","goods_bread",
		"goods_egg","goods_milk","goods_cheese","goods_meat","goods_provisions",
		"goods_jam","goods_parcel","goods_crate"]:
		check(ResourceLoader.exists("res://assets/models/"+model_name+".glb"),
			"Physical cargo asset exists: "+model_name)

	game.queue_free()
	await process_frame
	await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	print("RESULT: %d physical-flow checks, %d failures" % [checks,failures])
	await create_timer(.08).timeout;quit(1 if failures else 0)
