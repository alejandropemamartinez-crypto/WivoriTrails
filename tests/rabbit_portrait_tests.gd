extends SceneTree

# Source-authored contract for the live robbery messenger. This is deliberately
# NOT run in this development phase; it requires Godot 4.4.1 GLB import.
const Banner=preload("res://scripts/rabbit_warning.gd")
const Actor=preload("res://scripts/actor.gd")
var checked:=0
var failed:=0

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, name: String) -> void:
	checked+=1
	if ok:print("PASS: ",name)
	else:
		failed+=1
		push_error("FAIL: "+name)

func run_tests() -> void:
	var banner:RabbitWarningBanner=Banner.new()
	root.add_child(banner)
	check(banner.portrait_view is SubViewport,"Rabbit preview has an actual SubViewport, not a Node3D")
	check(banner.actor is Node3D and banner.actor.get_parent()==banner.portrait_view,
		"The validated imported rabbit is directly parented to the SubViewport")
	check(banner.actor.scene_file_path=="res://assets/models/rabbit.glb",
		"The live warning uses the authored rabbit GLB, not a placeholder")
	check(banner.face_rig!=null and banner.animator!=null,
		"Imported animated messenger retains skeleton and animator")
	var model:Node3D=Actor.model("rabbit")
	check(model is Node3D and model.scene_file_path=="res://assets/models/rabbit.glb",
		"Shared character loader produces a valid 3D scene independently of viewport")
	model.free()
	var original:Vector2i=banner.portrait_view.size
	check(original==Vector2i(128,144) and banner.portrait_view.transparent_bg,
		"3D portrait remains transparent and mobile-sized")
	banner.sync_state("warning")
	check(banner.visible and banner.lifetime>0 and banner.portrait_view.render_target_update_mode==SubViewport.UPDATE_ALWAYS,
		"Thief warning displays a live, updating rabbit without opening a blocking modal")
	banner.point_to(Vector3(5,0,-5),Vector3.ZERO)
	check(not banner.direction.text.is_empty(),"Rabbit remains able to indicate the direction of danger")
	banner.sync_state("escape")
	check(banner.headline.text.contains("PRODUCTOS"),"Messenger updates the warning stage without changing its actual 3D actor")
	banner.recovered(3)
	check(banner.relieved and banner.headline.text=="¡A SALVO!",
		"Recovery shows its authored positive feedback without inventing additional theft")
	banner._process(.1)
	check(banner.actor.get_parent()==banner.portrait_view,"Animated alert still has a visible 3D camera subject")
	banner._finish()
	check(not banner.visible and banner.portrait_view.render_target_update_mode==SubViewport.UPDATE_DISABLED,
		"Invisible portrait no longer demands costly offscreen renders")
	banner.queue_free()
	await process_frame
	print("RESULT: %d portrait contract checks, %d failed" % [checked,failed])
	await create_timer(.08).timeout;quit(1 if failed else 0)
