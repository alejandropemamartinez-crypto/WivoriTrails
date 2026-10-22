extends SceneTree

# Real touch controls, layout and captures for the visible travel checklist.
# Prepared saves here complement the no-grants economy in journey_progress_tests.
var game: Node3D
var viewport: SubViewport
var checks:=0
var failures:=0
var output:=""
var path: String="user://wivori_journey_ui_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func frames(count: int) -> void:
	for i in range(count):await process_frame
func click(button: Control) -> void:
	var event:=InputEventScreenTouch.new();event.index=5;event.pressed=true;event.position=button.get_global_rect().get_center()
	viewport.push_input(event,true);await process_frame
	event=event.duplicate();event.pressed=false;viewport.push_input(event,true);await process_frame
func shot(id: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await frames(3);await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(output.path_join(id+".png"))==OK,"Native screenshot: "+id)
func camera(at: Vector3) -> void:
	game.player.position=at;game.camera_follow=at;game.camera_lead=Vector3.ZERO;game._update_camera(1);game._refresh_ui()
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0];DirAccess.make_dir_recursive_absolute(output)
	viewport=SubViewport.new();viewport.size=Vector2i(720,1280);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	game=load("res://Main.tscn").instantiate();game.save_path=path;viewport.add_child(game)
	game.set_process(false);game.world.set_process(false)
	for height in [1280,1600]:
		viewport.size=Vector2i(720,height);camera(Vector3(0,0,4));await frames(4)
		check(game.route.route_button.text.contains("VILLA MIGA") and game.route.route_button.text.contains("0/5"),"Fresh HUD names the destination and shows completed milestones")
		if DisplayServer.get_name()!="headless":
			# Dummy rendering does not shape fonts or compute native label sizes.
			check(not game.route.route_button.get_global_rect().intersects(game.hud.mission_panel.get_global_rect()),"Destination and active objective occupy separate rows")
			check(game.hud.mission_detail.size.y>=game.hud.mission_detail.get_line_height()*mini(2,game.hud.mission_detail.get_line_count()),"The objective detail has enough height for its rendered text")
		await shot(str(height)+"_01_siguiente_paso")
		await click(game.route.route_button);await frames(3)
		check(game.route.board_visible() and game.route.journey_view.rows.size()==5,"A real touch opens all five explicit first-voyage milestones")
		var ferry_row: Dictionary=game.route.journey_view.rows["ferry"]
		var old_heading: Label=ferry_row["heading"]
		var old_coins: int=game.coins;game.coins+=1;game._refresh_ui();await frames(2)
		check(game.route.journey_view.rows["ferry"]["heading"]==old_heading,"Cash refresh updates the checklist without replacing touch controls")
		game.coins=old_coins;game._refresh_ui()
		await shot(str(height)+"_02_todos_los_requisitos")
		game.route.close_board()
	# Readiness and boarding: no automatic travel or level-six requirement.
	game.run.level=2;game.manual_delivered=6;game.worker_count=1;game.checkout_level=1;game.sold=18;game.coins=250
	game._refresh_ui();await frames(3)
	check(game.route.route_button.text.contains("MAPA LISTO"),"Readiness is persistent on the destination card")
	check(game._movement_input_allowed(),"Readiness notification never pauses manual play")
	await shot("03_barco_disponible")
	game.route.open_board();await frames(3)
	check(game.route.journey_view.rows["ferry"]["status"].text.contains("¡LISTO!"),"The checklist tells the player to prepare the boat at the pier")
	game.route.guide_campaign();var initial: Vector3=game.player.position
	for i in range(10):game._process_player(.1)
	check(game.player.position==initial and not game.has_tap_destination,"Choosing the next milestone only marks a walking route")
	camera(game.route.HOME_DOCK);await click(game.hud.guide_button);await frames(3)
	check(game.route.ferry and game.coins==0 and game.route.pending_destination==1,"Preparing the boat spends the displayed 250 once and selects Villa Miga")
	check(game.hud.guide_button.text=="EMBARCAR","At the pier the guide exposes the actual EMBARCAR action")
	await shot("04_embarcar_a_villa_miga")
	await click(game.hud.guide_button)
	check(game.route.sailing>0,"A real touch starts travel to the selected island")
	game.route.tick(5);camera(Vector3(0,0,15));await frames(3)
	check(game.route.region==1 and game.route.pending_destination==-1,"Arrival lands in the selected map and clears only the completed selection")
	check(game._current_objective()["title"].contains("Campos") and game.coins==0,"A zero-wallet arrival is guided to the included first field")
	await shot("05_llegada_granja")
	game.route.open_board();await frames(3);await shot("06_siguiente_pueblo")
	game.queue_free();await frames(2);viewport.queue_free();await frames(2)
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d journey UI checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
