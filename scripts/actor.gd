extends Node3D
class_name MarketActor

const OutfitShader=preload("res://scripts/outfit.gdshader")

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
var last_speed := 0.0
var is_money_courier := false
var cargo_kind := ""
static var scenes := {}

func setup(role: String, color: Color, species_: String="human") -> void:
	character_role=role
	outfit=color
	species=species_

static func model(kind: String) -> Node3D:
	if not scenes.has(kind):scenes[kind]=load("res://assets/models/"+kind+".glb")
	return scenes[kind].instantiate()

func _ready() -> void:
	var animal := "terrier" if species in ["scottie","dog","fox","cat","human","pig"] else species
	body_root=model(animal)
	body_root.name="Personaje orgánico con esqueleto"
	body_root.scale=Vector3.ONE*.84
	add_child(body_root)
	skeleton=_find_skeleton(body_root)
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
	for i in range(5):
		var fruit:=model("produce_"+["tomato","carrot","berry","apple","tomato"][i])
		fruit.position=Vector3((float(i%3)-1)*.15,float(i/3)*.18,0)
		fruit.scale=Vector3.ONE*.52
		goods_root.add_child(fruit)
	stolen_bundle=Node3D.new()
	stolen_bundle.name="Mercancía sustraída"
	stolen_bundle.position=Vector3(0,.86,.56)
	add_child(stolen_bundle)
	for i in range(4):
		var fruit:=model("produce_tomato")
		fruit.position=Vector3((float(i%2)-.5)*.23,float(i/2)*.17,0)
		fruit.scale=Vector3.ONE*.65
		stolen_bundle.add_child(fruit)
	money_bag=model("money_bag")
	money_bag.name="Bolsa de recaudación real"
	money_bag.scale=Vector3.ONE*.60
	money_bag.position=Vector3(0,.78,.54)
	add_child(money_bag)
	set_carry(0)
	last_position=position

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

func set_cargo_kind(kind: String) -> void:
	if kind not in ["tomato","carrot","berry","apple"] or kind==cargo_kind:return
	cargo_kind=kind
	var root: Node3D=stolen_bundle if character_role=="thief" else goods_root
	if root==null:return
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	for i in range(4):
		var item:=model("produce_"+kind)
		item.position=Vector3((float(i%2)-.5)*.23,float(i/2)*.17,0)
		item.scale=Vector3.ONE*.65
		root.add_child(item)

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
	var distance:=position.distance_to(last_position)
	last_position=position
	var speed:=distance/maxf(delta,.001) if distance<3 else 0.0
	walk_amount=lerpf(walk_amount,minf(speed/4.2,1),1-exp(-14*delta))
	rotation.y=lerp_angle(rotation.y,facing,1-exp(-12*delta))
	anim_t+=distance*3.8 if distance<3 else 0
	var ground_y: float=ground_sampler.call(position) if ground_sampler.is_valid() else .03
	ground_offset=lerpf(ground_offset,ground_y,1-exp(-20*delta))
	body_root.position.y=ground_offset
	goods_root.position.y=1.40+ground_offset+sin(anim_t)*walk_amount*.025
	stolen_bundle.position.y=.86+ground_offset+sin(anim_t)*walk_amount*.025
	money_bag.position.y=.78+ground_offset+sin(anim_t)*walk_amount*.025
	if action_left>0:action_left=maxf(0,action_left-delta)
	else:
		var locomotion: String=("carry" if carrying>0 else ("run" if speed>6.8 else "walk")) if walk_amount>.06 else "idle"
		_play(locomotion)
	# Keep the gait active during pickups while walking. The upper-body action
	# is layered onto the skeleton instead of freezing the feet for a full clip.
	if action_left>0 and walk_amount>.14 and action in ["harvest","deliver","collect"]:
		_play("carry" if carrying>0 else ("run" if speed>6.8 else "walk"))
	if animator!=null:
		animator.speed_scale=clampf(speed/(6.5 if current_clip=="run" else 4.3),.55,1.85) if current_clip in ["walk","run","carry"] else 1.0
		animator.advance(delta)
		if action_left>0 and walk_amount>.14 and action in ["harvest","deliver","collect"] and skeleton!=null:
			var amount:=sin((1-action_left/action_duration)*PI)*.8
			for arm in ["arm.L","arm.R"]:
				var bone:=skeleton.find_bone(arm)
				if bone>=0:skeleton.set_bone_pose_rotation(bone,skeleton.get_bone_pose_rotation(bone)*Quaternion(Vector3.RIGHT,-amount))
