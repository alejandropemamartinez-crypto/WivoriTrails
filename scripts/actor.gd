extends Node3D
class_name MarketActor

const OutfitShader=preload("res://scripts/outfit.gdshader")
const Motion=preload("res://scripts/character_motion.gd")

# Authored meshes, weighted skeletons and imported animation clips. The API used
# by the market, helpers and saved NPCs is preserved.
var character_role := "player"
var species := "human"
var outfit := Color("#348eb0")
var walk_amount := 0.0
var carrying := 0
var anim_t := 0.0
var body_root: Node3D
var head_mesh: MeshInstance3D
var goods_root: Node3D
var stolen_bundle: Node3D
var money_bag: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var facing := 0.0
var last_position := Vector3.ZERO
var action := ""
var action_left := 0.0
var action_duration := .8
var ground_sampler: Callable
var ground_offset := 0.0
var current_clip := ""
var contact_shadow: MeshInstance3D
var last_speed := 0.0
var motion_clock:=0.0
var motion_phase:=0.0
var motion_bones: Dictionary={}
var is_money_courier := false
var cargo_kind := ""
var visual_cargo_signature:=""
static var scenes := {}
const PRODUCE_KEYS=["tomato","carrot","berry","apple"]
const CARGO_MODEL_OVERRIDES={"packaging":"goods_parcel","preserves":"goods_provisions","kits":"goods_crate"}

func setup(role: String, color: Color, species_: String="human") -> void:
	character_role=role
	outfit=color
	species=species_

static func model(kind: String) -> Node3D:
	if not scenes.has(kind):scenes[kind]=load("res://assets/models/"+kind+".glb")
	return scenes[kind].instantiate()

func _ready() -> void:
	var animal: String="hero" if character_role=="player" else {"scottie":"fox","dog":"fox","human":"pig","cat":"duck"}.get(species,species)
	if animal not in ["hero","fox","pig","duck","rabbit","raccoon"]:animal="rabbit"
	motion_phase=Motion.phase_for(animal)
	body_root=model(animal)
	body_root.name="Personaje orgánico con esqueleto"
	body_root.scale=Vector3.ONE*.84
	add_child(body_root)
	contact_shadow=preload("res://scripts/scene_finish.gd").contact(self)
	skeleton=_find_skeleton(body_root)
	_cache_motion_bones()
	animator=_find_animator(body_root)
	head_mesh=_find_mesh(body_root)
	# A palette mask recolors canvas in the baked atlas while preserving fur,
	# leather and facial detail. Guards remain distinguishable from the hero.
	if head_mesh!=null and character_role!="player":
		var base: StandardMaterial3D=head_mesh.mesh.surface_get_material(0)
		var dye:=ShaderMaterial.new();dye.shader=OutfitShader
		dye.set_shader_parameter("atlas",base.albedo_texture)
		dye.set_shader_parameter("original_dye",Color("#318c88") if animal=="terrier" else Color("#d39a63") if animal=="rabbit" else Color("#63788a"))
		dye.set_shader_parameter("new_dye",outfit)
		head_mesh.set_surface_override_material(0,dye)
	if character_role=="customer":body_root.scale*=.90
	if character_role=="thief":body_root.scale*=.94
	if animator!=null:
		animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for clip in animator.get_animation_list():
			if clip in ["idle","walk","run","carry","alert"]:animator.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
	_play("idle")
	goods_root=Node3D.new()
	goods_root.name="Productos visibles en la mochila"
	goods_root.position=Vector3(0,1.40,-.42)
	add_child(goods_root)
	# Actors start with empty hands. Instantiating five assorted fruits for
	# every idle customer created inaccurate cargo and needless 3D nodes.
	stolen_bundle=Node3D.new()
	stolen_bundle.name="Mercancía sustraída"
	stolen_bundle.position=Vector3(0,.86,.56)
	add_child(stolen_bundle)
	# Stolen produce becomes visible only after the raider actually takes it.
	money_bag=model("money_bag")
	money_bag.name="Bolsa de recaudación real"
	money_bag.scale=Vector3.ONE*.60
	money_bag.position=Vector3(0,.78,.54)
	add_child(money_bag)
	set_carry(0)
	last_position=position
	facing=rotation.y

func face_direction_yaw(yaw: float) -> void:
	# Imported factory workers are spawned facing their counter; a direct
	# rotation.y assignment used to be cancelled by the actor's next tick.
	facing=yaw
	rotation.y=yaw

func _cache_motion_bones() -> void:
	motion_bones.clear()
	if skeleton==null:return
	for name_ in ["head","ear.L","ear.R","eye.L","eye.R","tail","arm.L","arm.R"]:
		var index:int=skeleton.find_bone(name_)
		if index>=0:motion_bones[name_]=index

func _pose_offset(bone_name: String, axis: Vector3, radians: float) -> void:
	if skeleton==null or not motion_bones.has(bone_name) or absf(radians)<.0001:return
	var index:int=motion_bones[bone_name]
	skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index)*Quaternion(axis,radians))

func _moving_blink() -> void:
	# Preserve the keyed animation's natural idle blink. Walking, running
	# and carrying clips lack that keyframe, so add a synchronized eyelid
	# closure using the imported eye bones, not floating facial decals.
	if skeleton==null:return
	if current_clip not in ["walk","run","carry","turn"]:return
	var blink:float=Motion.blink_factor(motion_clock,motion_phase)
	if blink>.998:return
	for eye in ["eye.L","eye.R"]:
		if not motion_bones.has(eye):continue
		var index:int=motion_bones[eye]
		var existing:Vector3=skeleton.get_bone_pose_scale(index)
		skeleton.set_bone_pose_scale(index,Vector3(existing.x,existing.y*blink,existing.z))

func _secondary_motion(turn_error: float) -> void:
	# The authored GLB still drives walking, ear flicks, blink and tail.
	# Small pose offsets add alertness and turn anticipation after the
	# animation has advanced; no unskinned props or replacement faces.
	if skeleton==null:return
	_moving_blink()
	if current_clip in ["idle","walk","run","carry","turn"]:
		var look:float=Motion.head_scan(motion_clock,motion_phase,walk_amount)
		_pose_offset("head",Vector3.UP,look+clampf(turn_error,-.45,.45)*.12)
		var wag:float=Motion.tail_response(motion_clock,motion_phase,walk_amount,character_role)
		_pose_offset("tail",Vector3.UP,wag)
		_pose_offset("ear.L",Vector3.RIGHT,Motion.ear_follow(motion_clock,motion_phase,-1.0))
		_pose_offset("ear.R",Vector3.RIGHT,Motion.ear_follow(motion_clock,motion_phase,1.0))
	if action_left>0 and walk_amount>.14 and action in ["harvest","deliver","collect"]:
		var amount:float=sin((1-action_left/action_duration)*PI)*.55
		_pose_offset("arm.L",Vector3.RIGHT,-amount)
		_pose_offset("arm.R",Vector3.RIGHT,-amount)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:return node
	for child in node.get_children():
		var found:=_find_skeleton(child)
		if found!=null:return found
	return null

func _find_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:return node
	for child in node.get_children():
		var found:=_find_animator(child)
		if found!=null:return found
	return null

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:return node
	for child in node.get_children():
		var found:=_find_mesh(child)
		if found!=null:return found
	return null

func set_carry(amount: int) -> void:
	carrying=amount
	if goods_root!=null:goods_root.visible=amount>0 and character_role!="thief" and not is_money_courier
	if stolen_bundle!=null:stolen_bundle.visible=amount>0 and character_role=="thief"
	if money_bag!=null:money_bag.visible=amount>0 and is_money_courier

func set_money_carry(amount: int) -> void:
	is_money_courier=true
	set_carry(amount)

func _cargo_asset(kind: String) -> String:
	if PRODUCE_KEYS.has(kind):return "produce_"+kind
	return CARGO_MODEL_OVERRIDES.get(kind,"goods_"+kind)

func _fill_visual_basket(destination: Node3D, amounts: Dictionary, limit: int) -> void:
	if destination==null:return
	var prior_nodes:Array=destination.get_children()
	var kinds: Array=amounts.keys()
	kinds.sort()
	var remaining:Dictionary={}
	for key in kinds:remaining[key]=maxi(0,int(amounts[key]))
	# Round-robin respects individual quantities and displays up to six real
	# items. A one-unit harvest is never represented by five random fruits.
	var visible: Array[String]=[]
	while visible.size()<limit:
		var added:=false
		for key in kinds:
			if int(remaining[key])<=0:continue
			visible.append(str(key))
			remaining[key]=int(remaining[key])-1
			added=true
			if visible.size()==limit:break
		if not added:break
	for i in range(visible.size()):
		var asset:String=_cargo_asset(visible[i])
		var expected:String="res://assets/models/"+asset+".glb"
		var item:Node3D=prior_nodes[i] if i<prior_nodes.size() else null
		# Preserve imported mesh + rig instances when the same product still
		# occupies this slot; repeated farming should not cause GLB churn.
		if item!=null and item.scene_file_path!=expected:
			item.free()
			item=null
		if item==null:
			item=model(asset)
			destination.add_child(item)
			destination.move_child(item,i)
		var x:float=(float(i%3)-1.0)*.22
		var z:float=float(i/3)*.21
		item.position=Vector3(x,z,0)
		item.scale=Vector3.ONE*.53
	for i in range(visible.size(),prior_nodes.size()):
		if is_instance_valid(prior_nodes[i]):prior_nodes[i].free()

func set_visible_cargo(contents: Dictionary) -> void:
	# Cosmetics only. The caller owns the real item counts; we never change
	# inventory or money here. Input order cannot affect our visual layout.
	if character_role=="thief" or is_money_courier:return
	var keys: Array=contents.keys()
	keys.sort()
	var normalized:Dictionary={}
	var signature:PackedStringArray=[]
	for key in keys:
		if not (PRODUCE_KEYS.has(str(key)) or CARGO_MODEL_OVERRIDES.has(str(key)) or str(key) in ["wheat","flour","feed","bread","egg","milk","cheese","meat","provisions"]):continue
		var qty:int=maxi(0,int(contents[key]))
		if qty<=0:continue
		normalized[key]=qty
		signature.append("%s:%d" % [key,qty])
	var proposed:String="|".join(signature)
	if proposed==visual_cargo_signature:return
	visual_cargo_signature=proposed
	_fill_visual_basket(goods_root,normalized,6)

func set_cargo_kind(kind: String) -> void:
	# Workers and raiders transport a single actual product. Keep the legacy
	# entry point but render only that species of cargo on its first use.
	if not PRODUCE_KEYS.has(kind) or kind==cargo_kind:return
	cargo_kind=kind
	var destination:Node3D=stolen_bundle if character_role=="thief" else goods_root
	_fill_visual_basket(destination,{kind:4},4)
	visual_cargo_signature=""  # Player mixed cargo is rebuilt when requested.

func act(kind: String) -> void:
	if action==kind and action_left>.12:return
	action=kind
	action_duration=1.0 if kind in ["harvest","collect","deliver","intercept"] else 1.2
	action_left=action_duration
	_play(kind)

func walk_to(direction: Vector3, speed: float) -> void:
	last_speed=speed
	if direction.length_squared()>.0001:facing=atan2(direction.x,direction.z)

func _play(clip: String) -> void:
	if animator==null or not animator.has_animation(clip):return
	if clip==current_clip:return
	current_clip=clip
	animator.play(clip,.16)

func _process(delta: float) -> void:
	motion_clock+=delta
	var distance:float=position.distance_to(last_position)
	last_position=position
	# Ignore teleport/sailing jumps: they are never a real stride.
	var speed:float=distance/maxf(delta,.001) if distance<3.0 else 0.0
	walk_amount=lerpf(walk_amount,Motion.target_gait(speed),1.0-exp(-14.0*delta))
	var turn_error:float=angle_difference(rotation.y,facing)
	var turn_lean:float=clampf(turn_error,-.35,.35)*walk_amount*.22
	if is_instance_valid(body_root):
		body_root.rotation.z=lerpf(body_root.rotation.z,-turn_lean,1.0-exp(-10.0*delta))
	rotation.y=Motion.turn_blend(rotation.y,facing,delta,character_role)
	anim_t+=distance*3.8 if distance<3.0 else 0.0
	var ground_y:float=ground_sampler.call(position) if ground_sampler.is_valid() else .03
	ground_offset=lerpf(ground_offset,ground_y,1.0-exp(-20.0*delta))
	# A little thoracic breathing makes waiting characters look alive without
	# jumping the floor-contact shadow or moving the actual actor collider.
	var breath:float=.011*sin(motion_clock*1.62+motion_phase)*(1.0-walk_amount)
	body_root.position.y=ground_offset+breath
	contact_shadow.position.y=ground_offset+.025
	var bounce:float=sin(anim_t+motion_phase)*walk_amount*.025
	goods_root.position.y=1.40+ground_offset+bounce
	stolen_bundle.position.y=.86+ground_offset+bounce
	money_bag.position.y=.78+ground_offset+bounce
	if action_left>0:action_left=maxf(0.0,action_left-delta)
	else:
		var locomotion:String=Motion.choose_clip(walk_amount,speed,carrying,turn_error)
		_play(locomotion)
	# A brief upper-body harvesting gesture stays available while walking.
	# The authored leg stride continues without an abrupt feet freeze.
	if action_left>0 and walk_amount>.14 and action in ["harvest","deliver","collect"]:
		_play(Motion.choose_clip(walk_amount,speed,carrying,turn_error))
	if animator!=null:
		animator.speed_scale=Motion.playback_rate(speed,current_clip,species)
		animator.advance(delta)
		_secondary_motion(turn_error)
