extends SceneTree

# Real touch/drag events through the viewport, with all destinations unlocked
# only as a fixture. Manual control must work independently in every map.
var game: Node3D
var checks:=0
var failures:=0
var save_path: String="user://wivori_campaign_touch_%d.json" % OS.get_process_id()

func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func touch(at: Vector2,pressed: bool) -> void:
	var event:=InputEventScreenTouch.new();event.index=0;event.position=at;event.pressed=pressed
	root.push_input(event,true);await process_frame
func run() -> void:
	print("CAMPAIGN_TOUCH: creating production scene")
	game=load("res://Main.tscn").instantiate();game.save_path=save_path;root.add_child(game)
	print("CAMPAIGN_TOUCH: production scene ready")
	game.set_process(false);game.world.set_process(false)
	game.route.ferry=true;game.route.access_floor=5
	game.route.stage=game.route.PROJECTS.size();game.route.industry_stage=game.route.INDUSTRY_PROJECTS.size()
	game.route.aurora_stage=game.route.AURORA_PROJECTS.size()
	for project in game.route.PROJECTS+game.route.INDUSTRY_PROJECTS+game.route.AURORA_PROJECTS:game.route.built.append(project["id"])
	for region in range(6):
		print("CAMPAIGN_TOUCH: entering map ",region+1)
		game.route._arrive(region)
		game.player.position=Vector3(0,0,12) if region>0 else Vector3(0,0,4)
		game.move_velocity=Vector3.ZERO;game._refresh_ui()
		for i in range(4):await process_frame
		var initial: Vector3=game.player.position
		game._follow_objective()
		if game.route.board_visible():game.route.close_board()
		for i in range(6):game._process_player(.08)
		check(game.player.position.is_equal_approx(initial),"Map %d guidance never starts the hero walking automatically" % (region+1))
		var center: Vector2=game.input_stick.get_global_rect().get_center()
		await touch(center,true)
		var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=center+Vector2(0,-62);drag.relative=Vector2(0,-62)
		root.push_input(drag,true);await process_frame
		for i in range(6):game._process_player(.08);await process_frame
		check(game.player.position.z<initial.z-1.0,"Map %d accepts an actual joystick finger drag" % (region+1))
		await touch(drag.position,false)
		for i in range(15):game._process_player(.08)
		var stopped: Vector3=game.player.position
		for i in range(8):game._process_player(.08)
		check(game.player.position.distance_to(stopped)<.01,"Map %d stops after the finger releases instead of continuing a hidden route" % (region+1))
		check(game.world.navigation.is_walkable(game.player.position,.25),"Map %d touch movement stays on walkable ground" % (region+1))
	game.queue_free();await process_frame;await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	print("RESULT: %d campaign touch checks, %d failures" % [checks,failures]);await create_timer(.08).timeout;quit(1 if failures else 0)
