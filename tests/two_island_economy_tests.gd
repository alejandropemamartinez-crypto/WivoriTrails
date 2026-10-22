extends SceneTree

# Simulates player joystick input from an empty save through Puerto Nata.
# No grants, teleports, recipe completion, wallet edits or level skips.
var game: Node3D
var checks:=0
var failures:=0
var path: String="user://wivori_two_islands_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func run() -> void:
	game=load("res://Main.tscn").instantiate();game.save_path=path;root.add_child(game)
	game.set_process(false);game.world.set_process(false);await process_frame
	var elapsed:=0.0
	var first_arrival:=-1.0
	var last_stage:=-1
	for frame in range(18000):
		if game.route.region==2:break
		if game.route.region==1 and first_arrival<0:first_arrival=elapsed
		if game.route.stage!=last_stage:
			last_stage=game.route.stage;print("ECONOMY: stage %d at %.1f simulated seconds" % [last_stage,elapsed])
		var task: Dictionary=game._current_objective()
		game.input_stick.axis=Vector2.ZERO
		if not task.has("target"):
			if task.get("upgrade","")=="level":game._follow_objective()
		else:
			var target: Vector3=task["target"]
			if game.player.position.distance_to(target)<=1.5:
				# Waiting for a real batch is an intentional choice; opening the
				# optional other-task board would correctly stop world movement.
				if task.get("action","")!="route:board" and (not str(task.get("action","")).is_empty() or not str(task.get("upgrade","")).is_empty()):game._follow_objective()
			else:
				var points: PackedVector3Array=game.world.navigation.find_path(game.player.position,target)
				for point in points:
					var difference: Vector3=point-game.player.position
					if difference.length()<.25:continue
					game.input_stick.axis=Vector2(difference.x,difference.z).normalized();break
		game._process(.1)
		if not game.route.away():game.world._process(.1)
		elapsed+=.1
		if frame%20==0:await process_frame
	check(first_arrival>0 and first_arrival<600,"The first island opens from real deliveries, sales and purchases")
	check(game.route.region==2 and game.route.stage==5,"Following the guide reaches Puerto Nata through the complete first farming economy")
	check(game.route.campaign.completed(1),"Every documented Villa Miga milestone was earned in sequence")
	check(game.route.employees.size()==1 and game.route.employees.has("flour") and int(game.route.mastery.get("flour",0))==1,"Only the single documented core operator and first improvement are required")
	check(game.run.level<6 and game.worker_count==1,"Optional market chapters and extra workers do not block either voyage")
	check(game.coins>=0 and game.route.unlocked()==2,"The economic route preserves a nonnegative wallet and opens exactly the earned destinations")
	if failures:print("FINAL STATE: ",game._current_objective()," · wallet ",game.coins," · bag ",game.route.bag," · inventory ",game.route.inventory)
	game.queue_free();await process_frame;await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RESULT: %d two-island economy checks, %d failures; %.1f simulated seconds" % [checks,failures,elapsed])
	await create_timer(.08).timeout
	quit(1 if failures else 0)
