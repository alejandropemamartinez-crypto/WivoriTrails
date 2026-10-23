extends SceneTree

var viewport: SubViewport
var game: Node3D
var checks:=0
var failures:=0
var path: String="user://refuge_ui_%d.json" % OS.get_process_id()
var output:=""
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
	checks+=1
	if ok:print("PASS: ",text)
	else:failures+=1;push_error("FAIL: "+text)
func frames(count: int) -> void:
	for index in range(count):await process_frame
func touch_at(point: Vector2,pressed: bool,index: int=4) -> void:
	var event:=InputEventScreenTouch.new();event.index=index;event.position=point;event.pressed=pressed;viewport.push_input(event,true);await process_frame
func tap(button: Control) -> void:
	var at: Vector2=button.get_global_rect().get_center();await touch_at(at,true);await touch_at(at,false)
func shot(name_: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await frames(3);await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(output.path_join(name_+".png"))==OK,"Native mobile capture "+name_)
func advance(seconds: float) -> void:
	for step in range(ceili(seconds/.1)):game.state.tick(.1)
	game.ui.refresh(.1);await frames(3)
func find_text(parent: Node,text: String) -> Button:
	for button in parent.find_children("*","Button",true,false):
		if button.text==text:return button
	return null
func run() -> void:
	var args:=OS.get_cmdline_user_args();if not args.is_empty():output=args[0];DirAccess.make_dir_recursive_absolute(output)
	viewport=SubViewport.new();viewport.size=Vector2i(720,1280);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	game=load("res://Refuge.tscn").instantiate();game.save_path=path;viewport.add_child(game);game.set_process(false)
	await frames(5)
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://Refuge.tscn","The installed app launches the new settlement experience")
	for height in [1280,1600]:
		viewport.size=Vector2i(720,height);await frames(4);game._camera(1);game._placards();game.ui.refresh(0);await frames(3)
		if DisplayServer.get_name()!="headless":
			var task_card: Control=game.ui.task_title.get_parent().get_parent().get_parent().get_parent()
			check(task_card.get_global_rect().encloses(game.ui.task_button.get_global_rect()),"The objective action stays inside its card at height "+str(height))
			check(not game.ui.route_button.get_global_rect().intersects(task_card.get_global_rect()),"The route navigation never covers the active objective at height "+str(height))
			for label in [game.ui.task_title,game.ui.task_detail]:check(label.size.y>=label.get_line_height()*label.get_line_count(),"The rendered objective has enough room for all its lines")
			for id in game.ui.placards:
				var button: Button=game.ui.placards[id]
				if button.visible:check(button.position.x>=0 and button.get_global_rect().end.x<=720,"Visible building labels stay within the phone width")
		await shot(str(height)+"_01_inicio")
		if DisplayServer.get_name()!="headless":
			var original=game.state;var late=preload("res://scripts/refuge_state.gd").new();late.city=5;late.unlocked=5;late.lit=true
			for id in late.BUILDINGS:late.town()["levels"][id]=8
			late.town()["levels"]["core"]=7;late.town()["people"]=18
			for id in ["lumber","kitchen","coal"]:late.town()["workers"][id]=1
			late.resources={"wood":0.0,"food":1000.0,"coal":1000.0,"iron":1000.0};game.state=late;game.ui.state=late;game.ui.refresh(0);await frames(3)
			for label in [game.ui.task_title,game.ui.task_detail]:check(label.get_line_count()<=2 and label.size.y>=label.get_line_height()*label.get_line_count(),"Late-campaign resource guidance fits without truncation at height "+str(height))
			check(not game.ui.route_button.get_global_rect().intersects(game.ui.task_title.get_parent().get_parent().get_parent().get_parent().get_global_rect()),"Long campaign objectives keep the bottom navigation clear")
			game.state=original;game.ui.state=original;game.ui.refresh(0)
	var initial_hero: Vector3=game.hero.position
	await tap(game.ui.task_button);game._process(.1);game.set_process(false)
	check(game.state.lit and not game.ui.modal.visible,"A real touch ignites the central heater without an unsolicited popup")
	check(game.hero.position==initial_hero,"Following a city objective never sends the protagonist running by itself")
	game.ui.show_building("lumber");await frames(3);await tap(game.ui.refs["upgrade"])
	check(not game.state.construction.is_empty() and game.state.construction["id"]=="lumber","A real touch starts construction of the included sawmill")
	check(game.ui.refs["upgrade"].disabled,"An active construction cannot be purchased again from the same panel")
	await advance(6.2)
	check(game.state.level("lumber")==1 and game.ui.worker_rows.has("lumber"),"Finishing a building reveals its actual worker assignment controls")
	await tap(game.ui.worker_rows["lumber"]["plus"])
	check(game.state.worker_count("lumber")==1,"The worker plus control assigns exactly one inhabitant by real touch")
	var old_plus: Button=game.ui.worker_rows["lumber"]["plus"]
	game.ui.refresh(.12);await frames(2)
	check(game.ui.worker_rows["lumber"]["plus"]==old_plus,"Resource updates do not rebuild a button under a finger")
	game.state.resources["wood"]=500.0;game.state.resources["coal"]=200.0;game.state.town()["levels"]["core"]=3
	await tap(game.ui.refs["upgrade"]);await frames(2)
	var plus_point: Vector2=old_plus.get_global_rect().get_center();await touch_at(plus_point,true,7)
	await advance(9)
	check(game.state.level("lumber")==2 and game.ui.worker_rows["lumber"]["plus"]==old_plus,"Construction completion preserves a held worker control until release")
	await touch_at(plus_point,false,7);game.ui.refresh(.12);await frames(3)
	check(game.state.worker_count("lumber")==2,"Releasing the held control applies one assignment, without a duplicated tap")
	check(game.ui.worker_rows["lumber"]["plus"]!=old_plus,"The panel displays the new level and next price once the finger is released")
	game.ui.close();await tap(game.ui.route_button);await frames(3)
	check(game.ui.view=="route" and game.ui.goal_rows.size()==5,"A real route touch exposes all five explicit chapter requirements")
	await shot("03_requisitos")
	var route_scroll: ScrollContainer=game.ui.listing.get_parent();var origin:=Vector2(370,820)
	await touch_at(origin,true,8)
	var drag:=InputEventScreenDrag.new();drag.index=8;drag.position=origin-Vector2(0,150);drag.relative=Vector2(0,-150);viewport.push_input(drag,true);await process_frame
	await touch_at(drag.position,false,8)
	check(game.ui.modal.visible and game.ui.view=="route","Dragging the checklist does not activate a travel button or close the panel")
	game.ui.show_team();await frames(3)
	game.state.resources["food"]=50.0;game.state.family_cooldown=0;game.ui.refresh(0)
	await tap(game.ui.refs["family"]);game._process(.1);game.set_process(false)
	check(game.state.town()["people"]==6 and game.residents.size()==6,"Receiving a family adds exactly two inhabitants and two arriving characters")
	await shot("04_equipo")
	var legacy_path: String=preload("res://scripts/game.gd").SAVE_PATH
	var legacy_before: String=FileAccess.get_file_as_string(legacy_path) if FileAccess.file_exists(legacy_path) else ""
	check(game.save(),"The new settlement writes its own atomic v8 save")
	var legacy_after: String=FileAccess.get_file_as_string(legacy_path) if FileAccess.file_exists(legacy_path) else ""
	check(legacy_before==legacy_after,"Saving the settlement preserves the previous archipelago save byte for byte")
	game.ui.close();game.center_camera();game._camera(1);game.ui.refresh(0)
	game.state.town()["levels"]["core"]=3;game.state.town()["levels"]["shelter"]=2;game.state.town()["levels"]["watch"]=1;game.state.town()["people"]=8;game.state.town()["storms"]=1
	game.state.resources={"wood":500.0,"food":200.0,"coal":200.0,"iron":80.0};game.ui.show_route();await frames(3)
	check(game.ui.refs["open"].text.contains("VALLE ÁMBAR") and not game.ui.refs["open"].disabled,"A ready chapter names and enables the exact next destination")
	await tap(game.ui.refs["open"]);await frames(3)
	check(game.state.unlocked==1 and game.state.city==0,"Opening a route never automatically teleports the player")
	var travel_button: Button=find_text(game.ui.listing,"VIAJAR A VALLE ÁMBAR")
	check(travel_button!=null,"The newly opened destination has an explicit travel action")
	if travel_button!=null:
		travel_button.grab_focus();await frames(3);await tap(travel_button);await frames(4)
	check(game.state.city==1 and not game.ui.modal.visible,"A deliberate real touch enters the next prepared settlement")
	check(game.state.worker_count("lumber")==1 and game.models["kitchen"].building=="kitchen","The new zone starts with its own staffed buildings and correct scene")
	await shot("05_valle_ambar")
	game.ui.close();game.toggle_walk();await frames(2);var before_walk: Vector3=game.hero.position
	game.stick.axis=Vector2(1,0);game._process(.2);game.set_process(false)
	check(game.hero.position.distance_to(before_walk)>.5,"Optional walking responds to the player's joystick input")
	game.stick.axis=Vector2.ZERO;before_walk=game.hero.position;game._process(.2);game.set_process(false)
	check(game.hero.position==before_walk,"The protagonist stops as soon as the joystick is released")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var stored: Dictionary=preload("res://scripts/save_store.gd").load_data(path);stored["last_saved"]=Time.get_unix_time_from_system()-40
	preload("res://scripts/save_store.gd").write_data(path,stored)
	var resume_wood: float=float(game.state.resources["wood"])
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED);game.set_process(false);await frames(3)
	check(float(game.state.resources["wood"])>resume_wood and game.ui.state==game.state,"Returning from Android pause credits production and binds the visible UI to the resumed state")
	check(not game.walk_mode and not game.stick.visible,"Resuming clears held movement and returns to city management")
	game.queue_free();await frames(2);viewport.queue_free();await frames(2);await create_timer(.1).timeout
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d refuge UI checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
