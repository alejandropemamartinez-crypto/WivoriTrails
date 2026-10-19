extends SceneTree

# Modal interaction regression contract. Authored only; no Godot execution
# during code-only stage 5N. Real touch testing is still mandatory.
var game:Node3D
var checked:=0
var failed:=0
var file_path:String="user://wivori_modal_input_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok:bool,label:String) -> void:
	checked+=1
	if ok:print("PASS: ",label)
	else:
		failed+=1
		push_error("FAIL: "+label)

func clear_save() -> void:
	for extension in ["",".tmp",".bak",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path+extension))

func run_tests() -> void:
	clear_save()
	game=load("res://Main.tscn").instantiate()
	game.save_path=file_path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame

	# Input force cannot sneak movement, harvest or delivery through an
	# open shop, even with stale keyboard/joystick speed already applied.
	game.town.toggle_mode()
	check(game.town.in_build_mode,"Village editing panel is available")
	game.move_velocity=Vector3(3,0,0)
	game._toggle_shop()
	check(game.shop_panel.visible and not game.town.in_build_mode,
		"Opening upgrades closes city editing rather than stacking two modal interfaces")
	check(game.move_velocity==Vector3.ZERO and not game._movement_input_allowed(),
		"Opening shop cancels inertia and blocks movement input")

	game.player.position=game.world.crop_spots[0]["node"].global_position
	game.stash["tomato"]=0
	var origin:Vector3=game.player.position
	game.input_stick.axis=Vector2.RIGHT
	game.move_velocity=Vector3(4,0,0)
	game._process_player(.35)
	check(game.player.position==origin and game.move_velocity==Vector3.ZERO,
		"Menu freezes even a previously moving hero")
	check(game._total_bag()==0,
		"Standing on a ripe crop does not harvest behind the shop")
	game.input_stick._clear()

	game.player.position=Vector3(4,0,2.5)
	game.stash["tomato"]=3
	game._sync_visible_cargo()
	var delivered_before:int=game.delivered
	var previous_stock:int=game.counter["tomato"]
	game._process_player(.25)
	check(game.stash["tomato"]==3 and game.counter["tomato"]==previous_stock and game.delivered==delivered_before,
		"Deliveries do not silently complete behind the shop")
	game._toggle_shop()
	check(not game.shop_panel.visible and game._movement_input_allowed(),
		"Closing the shop restores manual control")
	game._process_player(.25)
	check(game.stash["tomato"]==0 and game.counter["tomato"]>=previous_stock+3,
		"Closing the menu restores ordinary physical delivery")

	# Physical home cash stacks cannot be picked up merely by opening a menu.
	game.cash.pending[0]=35
	game.player.position=game.cash.REGISTERS[0]
	game._toggle_shop()
	game.cash._process_collect_player()
	check(game.cash.pending[0]==35 and game.cash.player_held==0,
		"Hero does not collect money from a register while upgrades are displayed")
	game._toggle_shop()
	game.cash._process_collect_player()
	check(game.cash.pending[0]==0 and game.cash.player_held==35,
		"Register pickup resumes normally when all panels close")
	game.cash._complete_player_flight(2)
	check(game.cash.player_held==0,
		"An already initiated payment is settled exactly once by its flight timer")

	game.run.level=7
	game.route.open_board()
	check(game.route.board_visible(),"Route panel is initially visible")
	game.work.toggle_board()
	check(game.work.board_visible() and not game.route.board_visible(),
		"Contracts panel closes the route panel instead of obscuring it")
	game.route.open_board()
	check(game.route.board_visible() and not game.work.board_visible(),
		"Reopening the route panel closes the contracts board")
	var key:=InputEventKey.new()
	key.pressed=true
	key.keycode=KEY_ESCAPE
	game._unhandled_input(key)
	check(not game.route.board_visible(),"Escape reliably dismisses the routes panel")
	game.work.toggle_board()
	game._unhandled_input(key)
	check(not game.work.board_visible(),"Escape also dismisses the contracts panel")

	# Cash and wheat in the next village remain physical, but a modal
	# screen must not harvest or pick up anything while it is open.
	game.route.ferry=true
	game.route.built.append("grain")
	game.route._arrive(1)
	var village=game.route
	check(village.wheat.size()>0,"Villa Miga contains the authored wheat field after construction")
	if village.wheat.size()>0:
		var crop:Dictionary=village.wheat[0]
		crop["remaining"]=0.0
		game.player.position=crop["node"].position
		var wheat_before:int=village.bag["wheat"]
		village.open_board()
		village.tick(.20)
		check(village.bag["wheat"]==wheat_before,
			"Harvesting does not occur through the map/production panel")
		village.close_board()
		village.tick(.20)
		check(village.bag["wheat"]==wheat_before+1,
			"Closing the map restores genuine, timed wheat harvesting")
	village.market_money[1]=42
	game.player.position=village.MARKET
	village.open_board()
	village.tick(.10)
	check(village.market_money[1]==42,"Local market cash remains on the table behind the routes panel")
	village.close_board()
	village.tick(.10)
	check(village.market_money[1]==0 and game.cash.player_held>=42,
		"Local market pickup resumes immediately after closing the panel")

	village.sailing=.4
	village.sail_target=0
	village.open_board()
	check(not village.board_visible(),"No map can reopen during a ferry crossing")
	game.queue_free()
	await process_frame
	await process_frame
	clear_save()
	print("RESULT: %d prepared modal checks, %d failures" % [checked,failed])
	quit(1 if failed else 0)
