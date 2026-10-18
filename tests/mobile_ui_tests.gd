extends SceneTree

var game: Node3D
var viewport: SubViewport
var checks := 0
var failures := 0
var test_path := "user://wivori_ui_tests_%d.json" % OS.get_process_id()

func _initialize() -> void:
	viewport=SubViewport.new()
	viewport.size=Vector2i(720,1280)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks+=1
	if condition:print("PASS: ",message)
	else:
		failures+=1
		push_error("FAIL: "+message)

func start_game() -> void:
	game=load("res://Main.tscn").instantiate()
	game.save_path=test_path
	viewport.add_child(game)
	game.set_process(false); game.world.set_process(false)
	for i in range(6): await process_frame

func clean_files() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))

func click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true
	event.position=control.get_global_rect().get_center()
	viewport.push_input(event,true)
	await process_frame
	event=event.duplicate()
	event.pressed=false; viewport.push_input(event,true)
	await process_frame

func touch_at(position: Vector2, index: int, down: bool, cancelled: bool=false) -> void:
	var event := InputEventScreenTouch.new()
	event.index=index; event.pressed=down; event.canceled=cancelled; event.position=position
	viewport.push_input(event,true)
	await process_frame

func run() -> void:
	clean_files()
	await start_game()
	check(game.camera.keep_aspect==Camera3D.KEEP_WIDTH, "Portrait camera preserves the horizontal view of the market")
	check(game._current_objective()["target"]==Vector3(-8,0,0), "A fresh game points to the first harvest")
	if DisplayServer.get_name()!="headless":
		check(game.hud.mission_progress.get_global_rect().end.y < game.hud.team_label.get_global_rect().position.y, "Objective progress and stock chips do not overlap")
	game.input_stick.axis=Vector2.ONE
	game.hud.guide_button.pressed.emit()
	check(game.has_tap_destination and game.input_stick.axis==Vector2.ZERO, "The guide starts a route and releases manual movement")
	for i in range(100):
		game.world._process(.1); game._process_player(.1)
	game._refresh_ui()
	check(game._total_bag()>=6 and game.hud.guide_button.text=="ENTREGAR", "The guide changes to delivery after the first harvest")
	game.hud.guide_button.pressed.emit()
	for i in range(150):game._process_player(.1)
	check(game._total_bag()==0 and game._total_stock()>=6, "The delivery guide reaches the actual drop-off point")
	for i in range(500):
		if i%46==0:game._spawn_customer()
		game._process_customers(.1)
	game._refresh_ui()
	check(game.hud.guide_button.text=="CONTRATAR", "First sales expose the affordable automation upgrade")
	var old_coins: int=game.coins
	game.hud.guide_button.pressed.emit()
	check(game.worker_count==1 and game.coins==old_coins-80, "The onboarding action buys one helper for the displayed price")
	check(game._current_objective().get("upgrade")=="expand", "After hiring, the next goal becomes the orchard")
	game.coins=50; game._refresh_ui()
	check(game.store_buttons["expand"].disabled and game.store_buttons["pier"].disabled, "Unaffordable expansions show a disabled purchase button")
	await click(game.shop_button)
	check(game.shop_panel.visible and game.hud.scrim.visible, "A real pointer click opens the upgrade sheet once")
	check(game.shop_panel.get_global_rect().position.y>=0 and game.shop_panel.get_global_rect().end.y<=viewport.get_visible_rect().size.y, "The complete upgrade sheet fits the portrait viewport")
	game._toggle_shop()
	check(not game.hud.scrim.visible, "Closing upgrades removes the input-blocking backdrop")
	var touch := InputEventScreenTouch.new()
	touch.index=2; touch.pressed=true; touch.position=game.shop_button.get_global_rect().get_center()
	viewport.push_input(touch,true); await process_frame
	touch=touch.duplicate(); touch.pressed=false
	viewport.push_input(touch,true); await process_frame
	check(game.shop_panel.visible, "A raw screen touch activates upgrades without mouse emulation")
	if game.shop_panel.visible:game._toggle_shop()
	var joystick_at: Vector2=game.input_stick.get_global_rect().get_center()+Vector2(45,0)
	var run_at: Vector2=game.hud.run_button.get_global_rect().get_center()
	await touch_at(joystick_at,0,true)
	await touch_at(run_at,1,true)
	check(game.input_stick.axis.length()>.1 and game.boost_active, "Two separate fingers can move and run at the same time")
	await touch_at(run_at,1,false)
	check(not game.boost_active and game.input_stick.axis.length()>.1, "Releasing run leaves the joystick finger active")
	await touch_at(joystick_at,0,false)
	game.coins=1000; game._refresh_ui()
	var guide_at: Vector2=game.hud.guide_button.get_global_rect().get_center()
	await touch_at(guide_at,3,true)
	await touch_at(guide_at,3,false,true)
	check(not game.orchard_owned and game.coins==1000, "A cancelled touch cannot purchase an expansion")
	await touch_at(run_at,1,true)
	game.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not game.boost_active and game.hud.run_button.touch_index==-1, "Pausing releases a held touch button")
	game._toggle_camera_view()
	var distance: float=game.camera_distance
	game._save_progress()
	game.queue_free(); await process_frame
	await start_game()
	check(game.worker_count==1 and game._current_objective().get("upgrade")=="expand" and is_equal_approx(game.camera_distance,distance), "Reload preserves progress, skips completed onboarding and restores the chosen view")
	game.queue_free(); await process_frame
	clean_files()
	print("RESULT: %d mobile UI checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
