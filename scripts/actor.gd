extends Node3D
class_name MarketActor

# All face detail is painted by the head material: no detached eyes, nose,
# whiskers or teeth. Unit-sized meshes make attachment dimensions explicit.
const FacePaint=preload("res://scripts/face_paint.gdshader")
const SculptedHead=preload("res://scripts/stylized_head.gd")
var character_role := "player"
var species := "human"
var outfit := Color("#348eb0")
var walk_amount := 0.0
var carrying := 0
var anim_t := 0.0
var body_root: Node3D
var head_root: Node3D
var head_mesh: MeshInstance3D
var tail_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_foot: Node3D
var right_foot: Node3D
var goods_root: Node3D
var stolen_bundle: Node3D
var facing := 0.0
var last_position := Vector3.ZERO
var action := ""
var action_left := 0.0
var action_duration := .55
var ears: Array[Node3D]=[]
var ground_sampler: Callable
var ground_offset:=0.0
static var meshes := {}
static var materials := {}

func setup(role: String, color: Color, species_: String="human") -> void:
	character_role=role; outfit=color; species=species_

func _solid(parent: Node3D, shape: String, tint: Color, pos: Vector3, dimensions: Vector3) -> MeshInstance3D:
	if not meshes.has(shape):
		var model: PrimitiveMesh
		match shape:
			"sphere":
				var sphere:=SphereMesh.new(); sphere.radius=.5; sphere.height=1; sphere.radial_segments=24; sphere.rings=14; model=sphere
			"cylinder":
				var cylinder:=CylinderMesh.new(); cylinder.height=1; cylinder.radial_segments=20; model=cylinder
			"cone":
				var cone:=CylinderMesh.new(); cone.height=1; cone.top_radius=0; cone.radial_segments=12; model=cone
			_:
				model=BoxMesh.new()
		meshes[shape]=model
	var key:=tint.to_html(true)
	if not materials.has(key):
		var mat:=StandardMaterial3D.new(); mat.albedo_color=tint; mat.roughness=.87; materials[key]=mat
	var item:=MeshInstance3D.new(); item.mesh=meshes[shape]; item.material_override=materials[key]
	item.position=pos; item.scale=dimensions; parent.add_child(item)
	return item

func _pivot(at: Vector3, parent: Node3D) -> Node3D:
	var node:=Node3D.new(); node.position=at; parent.add_child(node); return node

func _ready() -> void:
	body_root=_pivot(Vector3.ZERO,self)
	var skin: Color={"human":Color("#f0b988"),"cat":Color("#dda779"),"rabbit":Color("#ede0c7"),"pig":Color("#eeaea5"),"fox":Color("#e9a15f"),"dog":Color("#c7a37c"),"scottie":Color("#666b72"),"raccoon":Color("#a9b5ba")}.get(species,Color("#e1c6a0"))
	_solid(body_root,"sphere",outfit,Vector3(0,.89,0),Vector3(.76,.85,.58))
	_solid(body_root,"sphere",outfit.lightened(.13),Vector3(0,1.13,.18),Vector3(.54,.30,.32))
	_solid(body_root,"box",Color("#e9d5a4"),Vector3(0,.68,.27),Vector3(.56,.10,.06))
	head_root=_pivot(Vector3(0,1.66,.01),body_root)
	# The face and muzzle belong to ONE continuous low-poly mesh.
	# Painted facial features cannot detach when the actor walks or turns.
	head_mesh=MeshInstance3D.new()
	head_mesh.mesh=SculptedHead.build(species)
	head_root.add_child(head_mesh)
	head_mesh.name="Cabeza esculpida con hocico integrado"
	var face:=ShaderMaterial.new(); face.shader=FacePaint; face.set_shader_parameter("skin",skin)
	face.set_shader_parameter("animal",species!="human"); face.set_shader_parameter("canine",species in ["dog","fox","scottie"]); face.set_shader_parameter("masked",character_role=="thief"); face.set_shader_parameter("scottie",species=="scottie")
	face.set_shader_parameter("phase",float(get_instance_id()%19))
	head_mesh.material_override=face
	if species=="scottie":
		# True Scottish Terrier: pointed upright triangular ears, not drooping puppy ears.
		for x in [-.36,.36]:
			var ear:=_pivot(Vector3(x,.35,-.065),head_root); ears.append(ear)
			var tip:=_solid(ear,"cone",skin.darkened(.08),Vector3(0,.28,0),Vector3(.43,.80,.34))
			tip.rotation.z=.09 if x<0 else -.09
			_solid(ear,"cone",Color("#b78d91"),Vector3(0,.27,.16),Vector3(.23,.54,.048))
	elif species=="rabbit":
		for x in [-.25,.25]:
			var ear:=_pivot(Vector3(x,.32,0),head_root); ears.append(ear)
			_solid(ear,"sphere",skin,Vector3(0,.26,0),Vector3(.25,.83,.23))
			_solid(ear,"sphere",Color("#dca6a0"),Vector3(0,.28,.094),Vector3(.12,.55,.037))
	elif species in ["fox","cat","raccoon"]:
		for x in [-.37,.37]:
			var ear:=_pivot(Vector3(x,.30,-.025),head_root); ears.append(ear)
			_solid(ear,"cone",skin,Vector3(0,.10,0),Vector3(.37,.48,.32))
	elif species=="dog":
		for x in [-.47,.47]:
			var ear:=_pivot(Vector3(x,.12,-.03),head_root); ears.append(ear)
			_solid(ear,"sphere",skin.darkened(.25),Vector3(0,-.12,0),Vector3(.24,.57,.28))
	elif species=="pig":
		for x in [-.43,.43]:_solid(head_root,"sphere",skin,Vector3(x,.28,0),Vector3(.25,.34,.24))
	else:
		_solid(head_root,"sphere",Color("#49382f"),Vector3(0,.29,-.09),Vector3(1.04,.41,.85))
		for x in [-.49,.49]:_solid(head_root,"sphere",skin,Vector3(x,0,0),Vector3(.18,.24,.18))
	if character_role in ["player","helper","guard"] and species!="scottie":
		var cap: Color=Color("#c46b49") if character_role=="player" else (Color("#e6ae50") if character_role=="helper" else Color("#526e9d"))
		_solid(head_root,"cylinder",cap,Vector3(0,.43,.015),Vector3(1.13,.075,1.02))
		_solid(head_root,"sphere",cap,Vector3(0,.47,-.05),Vector3(.92,.41,.85))
		_solid(head_root,"box",Color("#fff1cc"),Vector3(0,.47,.37),Vector3(.20,.11,.035))
	if species=="scottie":
		# A gold neckerchief and distinct layered charcoal coat preserve the
		# terrier silhouette without any decorative cap hiding its eyebrows.
		_solid(body_root,"sphere",Color("#e0ad67"),Vector3(0,1.34,.29),Vector3(.52,.16,.34))
		var knot:=_solid(body_root,"cone",Color("#c88854"),Vector3(0,1.22,.39),Vector3(.26,.38,.14))
		knot.rotation.z=PI
		_solid(body_root,"sphere",skin.darkened(.10),Vector3(0,.70,-.15),Vector3(.84,.67,.64))
	left_arm=_pivot(Vector3(-.34,1.12,0),body_root); right_arm=_pivot(Vector3(.34,1.12,0),body_root)
	for arm in [left_arm,right_arm]:
		_solid(arm,"sphere",outfit.darkened(.06),Vector3(0,-.15,0),Vector3(.28,.44,.29))
		_solid(arm,"sphere",skin,Vector3(0,-.36,.02),Vector3(.26,.26,.26))
	left_leg=_pivot(Vector3(-.19,.60,0),body_root); right_leg=_pivot(Vector3(.19,.60,0),body_root)
	for leg in [left_leg,right_leg]:
		_solid(leg,"sphere",Color("#3d5069"),Vector3(0,-.17,0),Vector3(.30,.46,.32))
		var foot:=_pivot(Vector3(0,-.47,.10),leg)
		_solid(foot,"sphere",Color("#455357"),Vector3.ZERO,Vector3(.36,.20,.49))
		if leg==left_leg:left_foot=foot
		else:right_foot=foot
	if species!="human":
		tail_root=_pivot(Vector3(0,.76,-.29),body_root)
		_solid(tail_root,"sphere",skin.darkened(.13),Vector3(0,0,-.27),Vector3(.19,.19,.57))
		if species=="scottie":
			tail_root.rotation.x=-.30
	if character_role in ["player","helper","thief"]:
		_solid(body_root,"sphere",Color("#ba8b58") if character_role!="thief" else Color("#786f88"),Vector3(0,1.03,-.35),Vector3(.58,.65,.39))
	goods_root=_pivot(Vector3(0,1.37,-.36),body_root)
	for i in range(6):
		_solid(goods_root,"sphere",[Color("#e78965"),Color("#e8bb5a"),Color("#9b83b6")][i%3],Vector3((i%2-.5)*.20,float(i/2)*.13,0),Vector3(.24,.24,.24))
	if character_role=="thief":
		stolen_bundle=_pivot(Vector3(0,1.0,.49),body_root)
		_solid(stolen_bundle,"box",Color("#a77645"),Vector3(0,-.13,0),Vector3(.64,.42,.52))
		for i in range(4):
			_solid(stolen_bundle,"sphere",Color("#efaa57") if i%2==0 else Color("#e5755b"),Vector3((float(i%2)-.5)*.27,.17,float(i/2)*.16),Vector3(.24,.26,.24))
	set_carry(0)
	last_position=position

func set_carry(amount: int) -> void:
	carrying=amount
	if stolen_bundle!=null:stolen_bundle.visible=amount>0
	if goods_root!=null:
		goods_root.visible=amount>0
		goods_root.scale=Vector3.ONE*(.75+minf(amount,12)*.025)

func act(kind: String) -> void:
	action=kind; action_duration=.32 if kind=="harvest" else .55; action_left=action_duration

func walk_to(direction: Vector3, speed: float) -> void:
	walk_amount=minf(speed/5,1)
	if direction.length_squared()>.0001:facing=atan2(direction.x,direction.z)

func _process(delta: float) -> void:
	var distance:=position.distance_to(last_position); last_position=position
	var moving:=minf(distance/maxf(delta,.001)/5,1) if distance<3 else 0.0
	walk_amount=lerpf(walk_amount,moving,1-exp(-14*delta))
	rotation.y=lerp_angle(rotation.y,facing,1-exp(-18*delta))
	anim_t+=distance*3.8 if distance<3 else 0
	var stride:=sin(anim_t)*walk_amount
	left_leg.rotation.x=stride*.52; right_leg.rotation.x=-stride*.52
	var bob:=absf(sin(anim_t))*walk_amount*.04
	left_leg.position.y=.13+.47*cos(left_leg.rotation.x)+.10*sin(left_leg.rotation.x)+maxf(0,-cos(anim_t))*.13*walk_amount-bob
	right_leg.position.y=.13+.47*cos(right_leg.rotation.x)+.10*sin(right_leg.rotation.x)+maxf(0,cos(anim_t))*.13*walk_amount-bob
	left_foot.rotation.x=-left_leg.rotation.x; right_foot.rotation.x=-right_leg.rotation.x
	var carry_pose: float=-.44 if carrying>0 else 0.0
	left_arm.rotation.x=-stride*.54+carry_pose; right_arm.rotation.x=stride*.54+carry_pose
	var ground_y: float=ground_sampler.call(position) if ground_sampler.is_valid() else .03
	ground_offset=lerpf(ground_offset,ground_y-.03,1-exp(-20*delta))
	body_root.position.y=ground_offset+bob+sin(Time.get_ticks_msec()*.002)*.009
	body_root.rotation.z=stride*.035
	body_root.rotation.x=walk_amount*.045
	head_root.rotation.x=-walk_amount*.035
	for i in range(ears.size()):ears[i].rotation.x=sin(anim_t-.5)*walk_amount*.10
	if tail_root!=null:tail_root.rotation.y=sin(anim_t*1.2)*(.11+.19*walk_amount)
	if action_left>0:
		action_left=maxf(0,action_left-delta)
		var emphasis:=sin((1-action_left/action_duration)*PI)
		left_arm.rotation.x-=emphasis*.8; right_arm.rotation.x-=emphasis*.8
		if action=="harvest":body_root.rotation.x+=emphasis*.22
		if action=="intercept":head_root.rotation.z=emphasis*.12
	else:head_root.rotation.z=0
