extends SceneTree

# Reproduces the reported Android screenshot: navigation must not cover the
# robbery messenger, and the intercept action must not cover the event toast.
var game: Node3D
var viewport: SubViewport
var checks:=0
var failures:=0
var output:=""
var save_path: String="user://wivori_hud_overlap_%d.json" % OS.get_process_id()

func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func frames(count: int) -> void:
	for i in range(count):await process_frame
func disjoint(a: Control,b: Control,message: String) -> void:
	check(not a.get_global_rect().intersects(b.get_global_rect()),message)
func hold_messenger() -> void:
	var banner: RabbitWarningBanner=game.hud.rabbit_banner
	if banner.active_tween!=null:banner.active_tween.kill()
	banner.slide_offset=0;banner.lifetime=120;banner.modulate.a=1;banner._process(0)
func shot(name_: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(output.path_join(name_+".png"))==OK,"Native screenshot saved: "+name_)
func click(button: Control) -> void:
	var event:=InputEventScreenTouch.new();event.index=5;event.pressed=true;event.position=button.get_global_rect().get_center()
	viewport.push_input(event,true);await process_frame
	event=event.duplicate();event.pressed=false;viewport.push_input(event,true);await process_frame
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0];DirAccess.make_dir_recursive_absolute(output)
	viewport=SubViewport.new();viewport.size=Vector2i(720,1280);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	game=load("res://Main.tscn").instantiate();game.save_path=save_path;viewport.add_child(game)
	game.set_process(false);game.world.set_process(false)
	game.run.level=3;game.coins=213;game.stash["berry"]=12
	game.player.position=Vector3(-8,0,-5);game.camera_follow=game.player.position;game._update_camera(1)
	game.run._spawn_raider(Vector3(20,0,-9))
	for spec in [{"id":"720x1280","size":Vector2i(720,1280),"top":0,"bottom":0},{"id":"720x1600","size":Vector2i(720,1600),"top":0,"bottom":0},{"id":"android_safe_1560","size":Vector2i(720,1560),"top":64,"bottom":24},{"id":"android_safe_1280","size":Vector2i(720,1280),"top":64,"bottom":24}]:
		viewport.size=spec["size"];game.hud.root.offset_top=spec["top"];game.hud.root.offset_bottom=-spec["bottom"]
		await frames(3)
		game.run.warning=0;game.run.raiders[0]["state"]="approach"
		game.run.raiders[0]["actor"].position=Vector3(20,0,-9)
		game._refresh_ui();game._notice("¡LLEGARON LOS MAPACHES!\nAcercate y tocá AHUYENTAR.",8)
		hold_messenger();await frames(3)
		var prefix: String=spec["id"]+" · "
		check(game.hud.rabbit_banner.visible and game.hud.intercept_button.visible and game.event_label.visible,prefix+"The exact reported combination is visible")
		disjoint(game.route.route_button,game.hud.rabbit_banner,prefix+"MAPAS never covers the robbery notification")
		disjoint(game.hud.view_button,game.hud.rabbit_banner,prefix+"VISTA never covers the robbery notification")
		disjoint(game.hud.mission_panel,game.hud.rabbit_banner,prefix+"Mission and messenger occupy separate rows")
		disjoint(game.event_label,game.hud.intercept_button,prefix+"The intercept button leaves the entire event message readable")
		disjoint(game.event_label,game.hud.run_button,prefix+"Running cannot cover the event message")
		check(game.event_label.get_global_rect().end.y<=game.hud.intercept_button.get_global_rect().position.y-8,prefix+"The message has an actual gap above the defense action")
		check(game.hud.rabbit_banner.get_global_rect().end.x<=game.hud.root.get_global_rect().end.x,prefix+"The entire notification fits inside the safe width")
		check(game.hud.rabbit_banner.size.y<=160,prefix+"The notification stays compact from its first layout")
		disjoint(game.hud.rabbit_banner,game.event_label,prefix+"Upper and lower notifications leave the game between them visible")
		for line in [game.hud.rabbit_banner.headline,game.hud.rabbit_banner.detail,game.hud.rabbit_banner.direction]:
			var text_width: float=line.get_theme_font("font").get_string_size(line.text,HORIZONTAL_ALIGNMENT_LEFT,-1,line.get_theme_font_size("font_size")).x
			check(text_width<=line.size.x,prefix+"The entire messenger line fits: "+line.text)
		check(game._movement_input_allowed(),prefix+"Notifications remain nonblocking")
		await shot(spec["id"]+"_robo")
		game.pier_owned=true;game.shipment={"kind":"tomato","amount":6,"remaining":12.0};game._refresh_ui();hold_messenger();await frames(2)
		var shipping: Control=game.shipping_label.get_parent()
		disjoint(shipping,game.hud.rabbit_banner,prefix+"Shipping and robbery notices stay separate")
		disjoint(shipping,game.route.route_button,prefix+"Shipping does not share the MAPAS row")
		await click(game.route.route_button)
		check(game.route.board_visible(),prefix+"MAPAS is still touchable during a robbery")
		game.route.close_board()
		game.run.raiders[0]["state"]="escape";game.run.raiders[0]["actor"].position=game.player.position+Vector3(.7,0,0)
		game._refresh_ui();hold_messenger();await frames(2)
		check(not game.hud.intercept_button.disabled,prefix+"The nearby defense action stays available")
		disjoint(game.event_label,game.hud.intercept_button,prefix+"An enabled action also leaves the message unobscured")
		game.run.raiders[0]["state"]="retreat";game.run.raiders[0]["actor"].position=Vector3(40,0,40)
		game.hud.rabbit_banner._finish();game.hud.rabbit_banner.last_phase="";game._refresh_ui()
		for key in game.counter:game.counter[key]=0
		for i in range(6):game._spawn_customer()
		for i in range(100):game._process_customers(.1)
		game._refresh_ui();await frames(3)
		check(game.hud.alert_panel.visible,prefix+"A full waiting queue produces its stock notice")
		disjoint(game.hud.alert_panel,game.route.route_button,prefix+"MAPAS also leaves ordinary stock notifications readable")
		disjoint(shipping,game.hud.alert_panel,prefix+"Shipping does not cover the stock notification")
		await shot(spec["id"]+"_fila_y_barco")
		game.pier_owned=false;game.shipment["kind"]=""
		for customer in game.customers:customer["actor"].queue_free()
		game.customers.clear()
	game.queue_free();await frames(2);viewport.queue_free();await frames(2)
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	print("RESULT: %d HUD overlap checks, %d failures" % [checks,failures])
	await create_timer(.08).timeout;quit(1 if failures else 0)
