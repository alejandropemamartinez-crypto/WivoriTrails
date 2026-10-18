extends Node3D
class_name MarketActor

# 3D actor: separate moving limbs, eyes, hairstyle, backpack and props.
# No pasted picture / flat sprite: every visible part is a 3D mesh.
var character_role := "player"
var species := "human"
var outfit := Color("#348eb0")
var walk_amount := 0.0
var carrying := 0
var anim_t := 0.0
var body_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var goods_root: Node3D
var body_y := 0.0

func setup(role: String, color: Color, species_: String = "human") -> void:
	character_role = role
	outfit = color
	species = species_

func _solid(parent: Node3D, shape: String, tint: Color, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh: PrimitiveMesh
	match shape:
		"sphere":
			var s := SphereMesh.new()
			s.radial_segments = 16
			s.rings = 8
			mesh = s
		"capsule":
			var c := CapsuleMesh.new()
			c.radial_segments = 12
			c.rings = 6
			mesh = c
		"cylinder":
			var c := CylinderMesh.new()
			c.radial_segments = 18
			mesh = c
		"cone":
			var c := CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = .5
			c.radial_segments = 16
			mesh = c
		_:
			mesh = BoxMesh.new()
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.83
	m.material_override = mat
	m.position = pos
	m.scale = size
	parent.add_child(m)
	return m

func _ready() -> void:
	body_root = Node3D.new()
	body_root.name = "AnimatedBody"
	add_child(body_root)
	var skin := Color("#f0b881")
	var hair := Color("#472b23")
	if species == "cat":skin=Color("#d8a979")
	elif species == "pig":skin=Color("#efb6a9")
	elif species == "rabbit":skin=Color("#f2dec2")
	elif species == "fox":skin=Color("#e9a25a")
	elif species == "dog":skin=Color("#d9ad78")
	if character_role == "helper":
		hair = Color("#5b3324")
	# Tunic, trousers, sleeves and neck. Face is actual 3D geometry.
	_solid(body_root, "capsule", outfit, Vector3(0, 1.06, 0), Vector3(.65, .77, .43))
	_solid(body_root, "sphere", skin, Vector3(0, 1.82, .06), Vector3(.69, .68, .65))
	if species == "human":
		_solid(body_root, "sphere", hair, Vector3(0, 2.11, -.02), Vector3(.72, .32, .68))
	else:
		# Distinct species, modelled in world-space; not flat sprite faces.
		match species:
			"rabbit":
				for x in [-.40,.40]:
					_solid(body_root,"capsule",skin,Vector3(x,2.52,-.04),Vector3(.26,.67,.20))
					_solid(body_root,"capsule",Color("#de9a9a"),Vector3(x,2.56,.15),Vector3(.15,.43,.07))
			"cat","fox":
				for x in [-.44,.44]:
					_solid(body_root,"cone",skin,Vector3(x,2.34,-.02),Vector3(.62,.69,.31))
					_solid(body_root,"sphere",Color("#df9987"),Vector3(x,2.30,.20),Vector3(.19,.19,.055))
			"pig":
				for x in [-.61,.61]:
					_solid(body_root,"sphere",skin.darkened(.08),Vector3(x,2.04,.03),Vector3(.30,.35,.16))
			"dog":
				for x in [-.64,.64]:
						_solid(body_root,"capsule",Color("#96683d"),Vector3(x,1.95,-.05),Vector3(.22,.47,.17))
		_solid(body_root,"sphere",skin.lightened(.12),Vector3(0,1.62,.60),Vector3(.35,.23,.24))
		if species == "pig":
			_solid(body_root,"sphere",Color("#e89396"),Vector3(0,1.67,.77),Vector3(.38,.24,.19))
			for x in [-.13,.13]:_solid(body_root,"sphere",Color("#b46c6d"),Vector3(x,1.69,.934),Vector3(.067,.08,.035))
		else:
			_solid(body_root,"sphere",Color("#4f3c39"),Vector3(0,1.72,.82),Vector3(.13,.11,.10))
		if species == "cat":
			for x in [-.36,.36]:
				for y in [1.65,1.55]:
					_solid(body_root,"cylinder",Color("#fff2df"),Vector3(x,y,.68),Vector3(.33,.012,.012))
		_solid(body_root,"sphere",skin.darkened(.07),Vector3(0,1.0,-.69),Vector3(.19,.36,.53))
	_solid(body_root, "sphere", Color("#fff9ef"), Vector3(-.19, 1.85, .606), Vector3(.18,.19,.09))
	_solid(body_root, "sphere", Color("#fff9ef"), Vector3(.19, 1.85, .606), Vector3(.18,.19,.09))
	_solid(body_root, "sphere", Color("#2d323d"), Vector3(-.18,1.86,.677), Vector3(.076,.10,.045))
	_solid(body_root, "sphere", Color("#2d323d"), Vector3(.18,1.86,.677), Vector3(.076,.10,.045))
	_solid(body_root, "sphere", Color("#cd8a6f"), Vector3(0,1.66,.69), Vector3(.14,.08,.07))
	_solid(body_root, "sphere", skin, Vector3(-.68,1.82,0), Vector3(.14,.20,.15))
	_solid(body_root, "sphere", skin, Vector3(.68,1.82,0), Vector3(.14,.20,.15))
	# Clothing details make the avatar recognisable from a top-down camera.
	_solid(body_root, "box", Color("#fff4db"), Vector3(0,1.24,.40), Vector3(.15,.41,.04))
	_solid(body_root, "sphere", Color("#ffd36f"), Vector3(0,1.47,.44), Vector3(.11,.10,.04))
	# Soft brimmed hat and belt for lead character.
	if character_role != "customer" or character_role == "vendor":
		_solid(body_root, "cylinder", Color("#e7b968"), Vector3(0,2.29,0), Vector3(.93,.075,.87))
		_solid(body_root, "cylinder", Color("#d8a253"), Vector3(0,2.48,0), Vector3(.55,.23,.56))
		_solid(body_root, "cylinder", Color("#70492e"), Vector3(0,2.33,0), Vector3(.58,.05,.59))
	left_arm = Node3D.new(); left_arm.position = Vector3(-.43,1.41,0); body_root.add_child(left_arm)
	right_arm = Node3D.new(); right_arm.position = Vector3(.43,1.41,0); body_root.add_child(right_arm)
	_solid(left_arm,"capsule",outfit.darkened(.08), Vector3(-.10,-.32,0),Vector3(.22,.47,.25))
	_solid(right_arm,"capsule",outfit.darkened(.08), Vector3(.10,-.32,0),Vector3(.22,.47,.25))
	_solid(left_arm,"sphere",skin,Vector3(-.10,-.57,.01),Vector3(.22,.22,.22))
	_solid(right_arm,"sphere",skin,Vector3(.10,-.57,.01),Vector3(.22,.22,.22))
	left_leg = Node3D.new(); left_leg.position = Vector3(-.21,.70,0); body_root.add_child(left_leg)
	right_leg = Node3D.new(); right_leg.position = Vector3(.21,.70,0); body_root.add_child(right_leg)
	_solid(left_leg,"capsule",Color("#364960"),Vector3(0,-.27,0),Vector3(.27,.42,.28))
	_solid(right_leg,"capsule",Color("#364960"),Vector3(0,-.27,0),Vector3(.27,.42,.28))
	_solid(left_leg,"sphere",Color("#503a2c"),Vector3(0,-.57,.13),Vector3(.32,.18,.42))
	_solid(right_leg,"sphere",Color("#503a2c"),Vector3(0,-.57,.13),Vector3(.32,.18,.42))
	# Backpack is physically attached to character and visibly fills up.
	_solid(body_root,"box",Color("#875c32"),Vector3(0,1.14,-.49),Vector3(.59,.64,.27))
	_solid(body_root,"box",Color("#d7af66"),Vector3(0,1.36,-.645),Vector3(.52,.065,.02))
	goods_root = Node3D.new(); goods_root.position = Vector3(0,1.53,-.50); body_root.add_child(goods_root)
	for i in range(5):
		var x := (float(i % 3) - 1.0) * .19
		var z := -float(i / 3) * .18
		_solid(goods_root,"sphere", Color("#d94336") if i % 2 == 0 else Color("#e8a03a"),Vector3(x,float(i%2)*.12,z),Vector3(.20,.20,.20))
	set_carry(0)

func set_carry(amount: int) -> void:
	carrying = amount
	if goods_root != null:
		goods_root.visible = amount > 0
		goods_root.scale = Vector3.ONE * (.6 + minf(float(amount), 10.0) * .05)

func walk_to(direction: Vector3, speed: float) -> void:
	walk_amount = minf(speed / 4.7, 1.0)
	if direction.length_squared() > .0001:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), .20)

func _process(delta: float) -> void:
	anim_t += delta * (3.0 + 11.0 * walk_amount)
	var step := sin(anim_t) * walk_amount
	left_leg.rotation.x = step * .60
	right_leg.rotation.x = -step * .60
	left_arm.rotation.x = -step * .43
	right_arm.rotation.x = step * .43
	body_root.position.y = absf(sin(anim_t)) * walk_amount * .075
	body_root.rotation.z = sin(anim_t * .5) * walk_amount * .035
	walk_amount = move_toward(walk_amount, 0.0, delta * 3.0)
