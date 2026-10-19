extends SceneTree

# Prepared, not executed. Real animation QA still requires imported Godot
# scenes, slow-motion screenshots and 30 minutes of device input.
const Motion=preload("res://scripts/character_motion.gd")
const Actor=preload("res://scripts/actor.gd")
const SPECIES=["fox","pig","duck","rabbit","raccoon"]
var checked:=0
var failed:=0

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool,label: String) -> void:
	checked+=1
	if ok:print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)

func run_tests() -> void:
	check(Motion.choose_clip(0,0,0,0)=="idle","Stationary characters remain in idle")
	check(Motion.choose_clip(0,0,0,.35)=="turn","A stationary actor has a distinct turn-in-place animation")
	check(Motion.choose_clip(.8,5.0,0,0)=="walk","Ordinary walking uses the foot-grounded authored stride")
	check(Motion.choose_clip(.8,8.2,0,0)=="run","Only high speed uses the sprint clip")
	check(Motion.choose_clip(.8,8.2,3,0)=="carry","Visible cargo overrides run with an authored carry stride")
	check(is_equal_approx(Motion.target_gait(0),0) and Motion.target_gait(7)>0.9,"Gait blend responds smoothly to measured speed")
	check(Motion.playback_rate(4.3,"walk","pig")<Motion.playback_rate(4.3,"walk","rabbit"),"Heavy pig and nimble rabbit have different walk cadences")
	check(Motion.playback_rate(5.0,"idle","hero")==1.0,"Idle clip keeps its original natural cadence")
	check(absf(Motion.turn_blend(PI,PI,.1,"helper")-PI)<.001,"Workshop workers hold their instructed heading")
	check(absf(Motion.head_scan(.4,.0,1.0))<absf(Motion.head_scan(.4,.0,.0)),"Moving actors scan less than idle ones")
	check(Motion.blink_factor(3.35,0.0)<.20 and Motion.blink_factor(0.0,0.0)>.99,"A travelling character blinks briefly but spends most time with open eyes")

	var temp:=Node3D.new()
	root.add_child(temp)
	for kind in SPECIES:
		var npc:MarketActor=Actor.new()
		npc.setup("customer",Color("#8dada6"),kind)
		temp.add_child(npc)
		check(npc.body_root!=null and npc.skeleton!=null and npc.animator!=null,"Species "+kind+" retains imported, rigged GLB")
		check(npc.motion_bones.has("head") and npc.motion_bones.has("tail"),"Species "+kind+" retains real skeleton head and tail")
		npc.face_direction_yaw(PI)
		npc._process(.06)
		check(absf(angle_difference(npc.rotation.y,PI))<.001,"Species "+kind+" never snaps back from explicitly assigned facing")
		npc.last_position=npc.position
		npc.position+=Vector3(.12,0,0)
		npc.walk_to(Vector3.RIGHT,3.0)
		npc._process(.04)
		check(npc.walk_amount>0 and npc.current_clip in ["walk","run","carry"],"Species "+kind+" responds visibly to world movement")
		npc.set_carry(2)
		npc._process(.04)
		check(npc.goods_root.visible and npc.carrying==2,"Species "+kind+" displays collected goods while walking")
		npc.queue_free()

	var protagonist:MarketActor=Actor.new()
	protagonist.setup("player",Color("#9db7c5"),"dog")
	temp.add_child(protagonist)
	check(protagonist.body_root.scene_file_path=="res://assets/models/hero.glb","The hero retains its original unnamed custom model")
	check(protagonist.skeleton!=null and protagonist.motion_bones.has("ear.L") and protagonist.motion_bones.has("ear.R"),"Unnamed hero keeps both rigged ears for small secondary motions")
	check(protagonist.motion_bones.has("eye.L") and protagonist.motion_bones.has("eye.R"),"Scottish Terrier blink uses two genuine skinned eye bones, no floating eyelids")
	var base_pose:Vector3=protagonist.body_root.position
	protagonist._process(.25)
	check(protagonist.body_root.position.distance_to(base_pose)<.04,"Standing breathing is subtle enough to preserve grounded feet")
	protagonist.last_position=protagonist.position
	protagonist.position+=Vector3(5,0,0)
	protagonist._process(.016)
	check(protagonist.walk_amount<.05,"Teleporting five units is not erroneously treated as running")
	protagonist.set_money_carry(100)
	check(protagonist.money_bag.visible and not protagonist.goods_root.visible,"Cash couriers keep their money bag instead of fake produce")
	temp.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures; authored but NOT executed" % [checked,failed])
	quit(1 if failed else 0)
