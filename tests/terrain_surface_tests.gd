extends SceneTree

# Regression: changing the island primitive once raised the lawn above every
# road and planter. Compare rendered surface bounds with actual walking height.
var game: Node3D
var failures:=0
var checks:=0
var save_path: String="user://wivori_terrain_%d.json" % OS.get_process_id()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func top(mesh: MeshInstance3D) -> float:
	var bounds:=mesh.mesh.get_aabb()
	return mesh.to_global(bounds.position+Vector3(0,bounds.size.y,0)).y
func run() -> void:
	game=load("res://Main.tscn").instantiate();game.save_path=save_path;root.add_child(game);game.set_process(false)
	var land: MeshInstance3D=game.world.get_node("Base de isla")
	for name_ in ["Paseo principal","Plaza comercial","Zona de fila"]:
		var road: MeshInstance3D=game.world.get_node(name_)
		check(top(land)<top(road),name_+" remains above the visible lawn")
		check(absf(game.world.ground_height(road.position)-top(road))<.045,name_+" agrees with the player's foot sampler")
	var shoreline: MeshInstance3D=game.world.get_node("Corte de isla")
	check(top(shoreline)<top(land),"The sand rim does not bury the playable grass")
	check(game.world.navigation.is_walkable(Vector3(0,0,4),.25),"The initial manual movement corridor remains open")
	game.queue_free();await process_frame;await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	print("RESULT: %d terrain checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
