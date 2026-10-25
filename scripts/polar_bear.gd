extends Node3D

# Original quadruped. Eyes, nose and ears are children of the moving head.
var body: Node3D
var head: Node3D
var legs: Array[Node3D]=[]
var eyes: Array[Node3D]=[]
var time:=0.0
var phase:=0.0
var hit_left:=0.0
var fallen:=false
var materials: Dictionary={}
var armor_tier:=0

func _plate(parent: Node3D,at: Vector3,dimensions: Vector3,color_: Color) -> void:
	var draw:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=dimensions;draw.mesh=box;draw.position=at
	if not materials.has(color_):
		var material:=StandardMaterial3D.new();material.albedo_color=color_;material.metallic=.35;material.roughness=.5;materials[color_]=material
	draw.material_override=materials[color_];parent.add_child(draw)

func _armor() -> void:
	var steel: Color=Color("#547b95") if armor_tier==1 else Color("#2d536d")
	var trim: Color=Color("#bdd1d5") if armor_tier==1 else Color("#d8a34f")
	_ellipsoid(body,Vector3(0,1.39,-.23),Vector3(.76,.42,1.00),steel)
	_ellipsoid(head,Vector3(0,.24,-.08),Vector3(.53,.30,.47),steel)
	_plate(head,Vector3(0,.24,.38),Vector3(.83,.12,.13),trim)
	_plate(body,Vector3(0,1.02,.87),Vector3(.70,.32,.17),trim)
	for side in [-1.0,1.0]:
		_ellipsoid(body,Vector3(side*.69,1.1,.40),Vector3(.19,.38,.43),steel)
		_plate(body,Vector3(side*.76,1.14,.42),Vector3(.11,.18,.21),trim)
		for z in [-.53,.14]:_ellipsoid(body,Vector3(side*.39,1.75,z),Vector3(.055,.055,.055),trim)
	if armor_tier==2:
		_plate(head,Vector3(0,.54,-.05),Vector3(.13,.18,.55),trim)
		for side in [-1.0,1.0]:_ellipsoid(body,Vector3(side*.69,1.16,-.60),Vector3(.20,.30,.34),steel)

func _ellipsoid(parent: Node3D,at: Vector3,scale_: Vector3,color_: Color) -> MeshInstance3D:
	var mesh:=SphereMesh.new();mesh.radius=1;mesh.height=2;mesh.radial_segments=16;mesh.rings=8
	var draw:=MeshInstance3D.new();draw.mesh=mesh;draw.position=at;draw.scale=scale_
	if not materials.has(color_):
		var material:=StandardMaterial3D.new();material.albedo_color=color_;material.roughness=.92;materials[color_]=material
	draw.material_override=materials[color_];parent.add_child(draw);return draw

func _ready() -> void:
	body=Node3D.new();add_child(body)
	_ellipsoid(body,Vector3(0,1.02,-.17),Vector3(.68,.68,1.02),Color("#e4ece8"))
	_ellipsoid(body,Vector3(0,1.05,.47),Vector3(.65,.70,.63),Color("#edf1e7"))
	head=Node3D.new();head.position=Vector3(0,1.34,.88);body.add_child(head)
	_ellipsoid(head,Vector3.ZERO,Vector3(.48,.44,.47),Color("#edf1e7"))
	_ellipsoid(head,Vector3(0,-.12,.36),Vector3(.30,.25,.36),Color("#d7e2dc"))
	_ellipsoid(head,Vector3(0,-.065,.63),Vector3(.15,.105,.10),Color("#263b43"))
	for side in [-1.0,1.0]:
		_ellipsoid(head,Vector3(side*.34,.32,-.03),Vector3(.15,.17,.12),Color("#e9eee4"))
		_ellipsoid(head,Vector3(side*.34,.33,.065),Vector3(.085,.10,.04),Color("#a2b8b8"))
		eyes.append(_ellipsoid(head,Vector3(side*.27,.09,.38),Vector3(.061,.073,.048),Color("#233c48")))
		_ellipsoid(head,Vector3(side*.26,.112,.423),Vector3(.016,.018,.010),Color("#ffffff"))
		for z in [-.73,.61]:
			var limb:=Node3D.new();limb.position=Vector3(side*.43,.69,z);body.add_child(limb);legs.append(limb)
			_ellipsoid(limb,Vector3(0,-.21,0),Vector3(.22,.40,.24),Color("#dbe6e2"))
			_ellipsoid(limb,Vector3(0,-.48,.07),Vector3(.26,.17,.33),Color("#d0deda"))
	_ellipsoid(body,Vector3(0,1.10,-1.08),Vector3(.14,.16,.13),Color("#dce7e2"))
	if armor_tier>0:_armor()
	preload("res://scripts/scene_finish.gd").contact(self)

func react() -> void:hit_left=.32
func _process(delta: float) -> void:
	time+=delta;hit_left=maxf(0,hit_left-delta)
	if fallen:return
	var stride: float=sin(time*2.2+phase)
	body.position=Vector3(sin(time*.9+phase)*.13,absf(stride)*.035,cos(time*.75+phase)*.16)
	body.rotation.y=sin(time*.65+phase)*.16
	head.rotation.x=sin(time*1.1+phase)*.065-hit_left*.7
	head.rotation.y=sin(time*.7+phase)*.15
	for index in range(legs.size()):legs[index].rotation.x=stride*.12*(-1 if index in [0,3] else 1)
	var blink: float=.12 if fposmod(time+phase,4.4)>.0 and fposmod(time+phase,4.4)<.12 else 1.0
	for eye in eyes:eye.scale.y=.073*blink
