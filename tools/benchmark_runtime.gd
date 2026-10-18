extends SceneTree
var game: Node3D
var path: String="user://wivori_benchmark_%d.json" % OS.get_process_id()
var results: Array=[]
func _initialize() -> void:call_deferred("run")
func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
func sample(stage: String) -> void:
	for i in range(20):await process_frame
	var frames: Array[float]=[];var calls:=0.0
	for i in range(90):
		var before:=Time.get_ticks_usec();await process_frame;frames.append(float(Time.get_ticks_usec()-before)/1000)
		calls+=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	frames.sort();var total:=0.0
	for elapsed in frames:total+=elapsed
	var report: Dictionary={"stage":stage,"renderer":RenderingServer.get_video_adapter_name(),"frames":90,"frame_ms_median":frames[45],"frame_ms_p95":frames[85],"average_fps":90000.0/total,"draw_calls_average":calls/90,"static_memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0}
	results.append(report);print("BENCHMARK ",JSON.stringify(report))
func run() -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	clean();game=load("res://Main.tscn").instantiate();game.save_path=path;root.add_child(game);await sample("new_market")
	game.run.level=10;game.coins=25000;game.town.in_build_mode=true
	var kinds: Array=["house","cafe","depot","bakery","greenhouse","workshop","park","watchtower","mill"]
	for i in range(kinds.size()):game.town.selected=i;game.town.build(kinds[i])
	game.town.in_build_mode=false
	for i in range(6):game._buy("helper")
	game._buy("expand");game._buy("checkout");game._buy("collector");game._buy("guard");game.counter["tomato"]=60
	await sample("built_market_six_workers")
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():
		var file:=FileAccess.open(args[0],FileAccess.WRITE)
		if file!=null:file.store_string(JSON.stringify({"note":"Linux native host measurement; not Android performance.","samples":results},"  "))
	game.queue_free();await process_frame;clean();quit(0)
