extends "res://scripts/coastal_building.gd"
class_name WivoriRefugeArt

# Original winter architecture, built as three shared material surfaces.
# The geometry source stays editable; no screenshots or assets from another
# game's client are included. Level changes alter the actual silhouettes.
const SNOW=Color("#e1edf1")
const TIMBER=Color("#74513c")
const LOG=Color("#a67b54")
const SLATE=Color("#3d6279")
const COPPER=Color("#b87644")
const DARK=Color("#293e50")
const LIT=Color("#ffd28b")
static var winter_meshes: Dictionary={}
static var winter_materials: Dictionary={}
var building:="shelter"
var tier:=1
var active:=true
var orbit: Node3D
var elapsed:=0.0

static func make(parent: Node3D,id: String,level_: int=1,at: Vector3=Vector3.ZERO) -> WivoriRefugeArt:
	var result:=WivoriRefugeArt.new();result.building=id;result.tier=level_;result.position=at
	result.name="Refugio · "+id+" · nivel "+str(level_);parent.add_child(result);return result

func _ready() -> void:
	var key: String=building+":"+str(tier)
	if not winter_meshes.has(key):
		_build_winter()
		var mesh:=ArrayMesh.new()
		for builder in builders.values():builder.index();builder.commit(mesh)
		winter_meshes[key]=mesh;builders.clear()
	draw=MeshInstance3D.new();draw.mesh=winter_meshes[key];add_child(draw)
	if building=="core":
		orbit=Node3D.new();orbit.position.y=3.65+float(mini(tier,4))*.12;add_child(orbit)
		var torus:=TorusMesh.new();torus.inner_radius=1.26;torus.outer_radius=1.35;torus.rings=24;torus.ring_segments=6
		var ring:=MeshInstance3D.new();ring.mesh=torus;ring.material_override=_material(2);ring.rotation_degrees.z=12;orbit.add_child(ring)
	set_process(building=="core")

func _process(delta: float) -> void:
	elapsed+=delta
	if orbit!=null:
		orbit.visible=active;orbit.rotation.y+=delta*.28;orbit.scale=Vector3.ONE*(1.0+sin(elapsed*1.6)*.018)

func _material(finish: int) -> Material:
	if not winter_materials.has(finish):
		if finish!=2:
			var paint:=ShaderMaterial.new();paint.shader=preload("res://scripts/refuge_surface.gdshader");paint.set_shader_parameter("metal",finish==1)
			winter_materials[finish]=paint;return paint
		var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.vertex_color_is_srgb=true
		material.roughness=.89 if finish==0 else .42
		if finish==1:material.metallic=.3
		if finish==2:material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.emission_enabled=true;material.emission=Color("#fbb96d");material.emission_energy_multiplier=.55
		winter_materials[finish]=material
	return winter_materials[finish]

func _builder(finish: int) -> SurfaceTool:
	var group: int=mini(finish,2)
	if not builders.has(group):
		var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES);builder.set_material(_material(group));builders[group]=builder
	return builders[group]

func _snow_roof(width: float,depth: float,y: float,rise: float,roof_color: Color=SLATE) -> void:
	for side in [-1.0,1.0]:
		var normal:=Vector3(side*rise,width*.5,0).normalized()
		var eave: float=side*width*.5
		_quad([Vector3(0,y+rise,-depth*.5),Vector3(0,y+rise,depth*.5),Vector3(eave,y,depth*.5),Vector3(eave,y,-depth*.5)],normal,roof_color,1)
		_quad([Vector3(side*.12,y+rise+.10,-depth*.49),Vector3(side*.12,y+rise+.10,depth*.49),Vector3(eave*.95,y+.15,depth*.49),Vector3(eave*.95,y+.15,-depth*.49)],normal,SNOW)
		_box(Vector3(eave,y-.04,0),Vector3(.15,.18,depth+.15),COPPER,1)
	for z in [-1.0,1.0]:
		_quad([Vector3(-width*.5,y,depth*.5*z),Vector3(width*.5,y,depth*.5*z),Vector3(0,y+rise,depth*.5*z),Vector3(0,y+rise,depth*.5*z)],Vector3(0,0,z),TIMBER)
		for side in [-1.0,1.0]:
			var basis_:=Basis(Vector3.BACK,-side*atan(rise/(width*.5)))
			_box(Vector3(side*width*.25,y+rise*.5,depth*.5*z+.02*z),Vector3(sqrt(pow(width*.5,2)+rise*rise),.13,.15),LOG,0,.03,basis_)
	_box(Vector3(0,y+rise+.16,0),Vector3(.25,.18,depth+.2),SNOW)

func _winter_window(at: Vector3,width: float=.7,height: float=.85) -> void:
	_box(at,Vector3(width+.20,height+.20,.18),LOG)
	_box(at+Vector3(0,0,.10),Vector3(width,height,.08),DARK)
	_box(at+Vector3(0,0,.15),Vector3(width-.08,height-.08,.025),LIT,2,.01)
	_box(at+Vector3(0,0,.19),Vector3(.055,height,.06),TIMBER)
	_box(at+Vector3(0,0,.19),Vector3(width,.055,.06),TIMBER)
	_box(at+Vector3(0,height*.5+.16,.14),Vector3(width+.35,.17,.33),SNOW)

func _cabin(width: float=4.2,depth: float=3.7,paint: Color=SLATE) -> void:
	_box(Vector3(0,.22,0),Vector3(width+.45,.45,depth+.35),Color("#7d8d94"),0,.16)
	_box(Vector3(0,1.45,0),Vector3(width,2.35,depth),paint,0,.10)
	for x in [-1.0,1.0]:
		for z in [-1.0,1.0]:_box(Vector3(x*(width*.5-.12),1.5,z*(depth*.5+.05)),Vector3(.23,2.55,.22),TIMBER)
	for y in [1.0,1.55,2.10]:_box(Vector3(0,y,depth*.5+.03),Vector3(width,.045,.035),paint.darkened(.12),0,.008)
	_box(Vector3(0,1.05,depth*.5+.14),Vector3(.86,1.70,.16),TIMBER)
	_box(Vector3(.25,1.1,depth*.5+.25),Vector3(.08,.08,.07),COPPER,1)
	_box(Vector3(0,.14,depth*.5+.5),Vector3(1.3,.28,.85),SNOW)
	for x in [-1.0,1.0]:_winter_window(Vector3(x*width*.29,1.63,depth*.5+.13))
	_snow_roof(width+.62,depth+.65,2.70,1.32)
	_box(Vector3(-width*.31,3.50,-depth*.18),Vector3(.54,1.7,.58),Color("#6d7781"))
	_box(Vector3(-width*.31,4.33,-depth*.18),Vector3(.72,.18,.73),SNOW)
	if tier>=2:
		_box(Vector3(width*.5+.52,.8,0),Vector3(1.25,1.35,depth*.72),TIMBER)
		_box(Vector3(width*.5+.52,1.53,0),Vector3(1.5,.22,depth*.80),SNOW)
	if tier>=4:
		_box(Vector3(0,.20,depth*.5+.90),Vector3(width+.25,.35,1.55),TIMBER)
		for x in [-width*.5,width*.5]:_box(Vector3(x,.8,depth*.5+1.5),Vector3(.13,1.1,.13),LOG)
		_box(Vector3(0,1.28,depth*.5+1.5),Vector3(width+.2,.14,.16),LOG)

func _build_winter() -> void:
	match building:
		"core":_heart()
		"shelter":_cabin(4.2,3.5,Color("#647e8c"))
		"kitchen":_glasshouse()
		"lumber":_sawmill()
		"coal":_charcoal()
		"mine":_quarry()
		"clinic":
			_cabin(4.2,3.5,Color("#a9b4b4"))
			_cylinder(Vector3(0,3.1,2.26),.42,.10,Color("#5e9d91"),0,16,Basis(Vector3.RIGHT,PI*.5))
			_box(Vector3(0,3.10,2.34),Vector3(.43,.12,.08),SNOW);_box(Vector3(0,3.10,2.34),Vector3(.12,.43,.08),SNOW)
		"watch":_guardhouse()
		"dock":_harbor()
		"factory":_foundry()
		"tree":_fir()
		"rock":_rock()
		"mountain":_mountain()
		"lamp":_streetlamp()
		"site":_site()
		"cargo_wood":
			for index in range(3):_cylinder(Vector3((index-1)*.25,.17,0),.14,1.0,LOG,0,8,Basis(Vector3.RIGHT,PI*.5))
		"cargo_food":
			_box(Vector3(0,.15,0),Vector3(.8,.3,.65),TIMBER)
			for index in range(3):_sphere(Vector3((index-1)*.22,.35,0),Vector3(.18,.18,.18),Color("#b8b76b"),0)
		"cargo_coal":
			for index in range(3):_sphere(Vector3((index-1)*.22,.18,0),Vector3(.23,.21,.24),DARK,0)
		"cargo_iron":
			for index in range(3):_box(Vector3((index-1)*.23,.15,0),Vector3(.20,.25,.7),Color("#a8bbc4"),1)

func _heart() -> void:
	_cylinder(Vector3(0,.24,0),2.3,.48,Color("#829399"),0,24)
	_cylinder(Vector3(0,.53,0),1.85,.20,TIMBER,0,20)
	_cylinder(Vector3(0,1.65,0),1.12,2.12,DARK,1,16)
	_cylinder(Vector3(0,1.92,0),1.16,1.12,Color("#ffb65d") if tier>0 else Color("#536976"),2 if tier>0 else 1,16)
	for i in range(6):
		var angle: float=float(i)*TAU/6.0
		var at:=Vector3(cos(angle)*1.23,1.9,sin(angle)*1.23)
		_box(at,Vector3(.16,2.6,.16),COPPER,1)
		_cylinder(Vector3(cos(angle)*1.52,.92,sin(angle)*1.52),.16,.95,COPPER,1,8)
	_cylinder(Vector3(0,3.16,0),1.46,.35,COPPER,1,20)
	_cylinder(Vector3(0,3.42,0),1.25,.20,SNOW,0,20)
	_cylinder(Vector3(0,4.10,0),.55,1.16,DARK,1,12)
	_cylinder(Vector3(0,4.73,0),.82,.20,COPPER,1,16)
	_cylinder(Vector3(0,4.88,0),.88,.13,SNOW,0,16)
	for side in [-1.0,1.0]:
		_box(Vector3(side*1.8,1.2,0),Vector3(.65,1.2,1.4),DARK,1)
		for z in range(5):_box(Vector3(side*1.84,1.3,(z-2)*.27),Vector3(.80,1.1,.08),COPPER,1)
		_box(Vector3(side*1.86,1.89,0),Vector3(.9,.12,1.62),SNOW)
	for index in range(mini(4,tier-1)):
		var at:=Vector3(-2.3-float(index)*.34,.38,0)
		_box(at,Vector3(.16,.45,2.6),COPPER,1)
	_box(Vector3(0,.16,2.24),Vector3(2.3,.32,.85),Color("#97a5a8"))
	_box(Vector3(0,1.1,1.28),Vector3(.7,.65,.12),DARK,1)
	_cylinder(Vector3(0,1.12,1.38),.23,.08,LIT,2,16,Basis(Vector3.RIGHT,PI*.5))

func _glasshouse() -> void:
	_box(Vector3(0,.3,0),Vector3(4.8,.55,4.2),Color("#71848b"))
	_box(Vector3(0,1.48,0),Vector3(4.4,2.1,3.8),Color("#609f9e"),1)
	for x in range(5):
		_box(Vector3((x-2)*1.05,1.55,1.96),Vector3(.13,2.3,.15),COPPER,1)
		if x<4:_winter_window(Vector3((x-1.5)*1.05,1.72,2.0),.80,1.25)
	for y in [1.0,2.4]:_box(Vector3(0,y,2.02),Vector3(4.65,.14,.13),COPPER,1)
	_snow_roof(4.8,4.2,2.65,1.1,Color("#527f8b"))
	for x in [-1.4,0.0,1.4]:
		_box(Vector3(x,.5,2.6),Vector3(.9,.4,.65),TIMBER)
		_sphere(Vector3(x,.8,2.6),Vector3(.36,.27,.25),Color("#8a9b59"),0)
	if tier>=2:_cylinder(Vector3(-2.55,1.0,-.4),.45,1.8,COPPER,1,12);_cylinder(Vector3(-2.55,1.94,-.4),.48,.1,SNOW)

func _sawmill() -> void:
	_cabin(4.1,3.6,Color("#9b7753"))
	_box(Vector3(0,.7,2.8),Vector3(3.5,.18,1.25),TIMBER)
	for x in [-1.5,1.5]:_box(Vector3(x,.36,2.8),Vector3(.22,.65,.75),DARK)
	_cylinder(Vector3(.2,1.12,2.8),.56,.14,Color("#91a3a6"),1,20,Basis(Vector3.RIGHT,PI*.5))
	for row in range(2):
		for index in range(3-row):_cylinder(Vector3(-2.45-index*.15,.35+row*.45,-.65+index*.55),.23,2.1,LOG,0,10,Basis(Vector3.RIGHT,PI*.5))

func _charcoal() -> void:
	_box(Vector3(0,.15,0),Vector3(4.8,.3,4.5),Color("#8d9da4"))
	for x in [-1.05,1.05]:
		_cylinder(Vector3(x,1.03,0),1.0,1.6,DARK,0,12)
		_cylinder(Vector3(x,2.0,0),.68,.42,COPPER,1,12)
		_cylinder(Vector3(x,2.7,0),.22,1.15,DARK,1,8)
		_cylinder(Vector3(x,3.3,0),.39,.14,SNOW,0,12)
		_box(Vector3(x,.68,1.0),Vector3(.65,.60,.08),LIT,2)
	for index in range(5):_sphere(Vector3(-1.65+index*.6,.38,1.8),Vector3(.4,.35,.4),Color("#354553"),0)
	if tier>=2:_box(Vector3(0,.5,-1.8),Vector3(3.9,.7,.9),TIMBER);_box(Vector3(0,.92,-1.8),Vector3(4.2,.16,1.2),SNOW)

func _quarry() -> void:
	_box(Vector3(0,.12,0),Vector3(5.5,.24,4.7),Color("#8d9da6"))
	for index in range(7):
		var angle: float=PI+float(index)*PI/6.0
		_sphere(Vector3(cos(angle)*2.1,1.1,sin(angle)*1.4),Vector3(1.0,1.4,1.0),Color("#688291"),0)
	for side in [-1.0,1.0]:_box(Vector3(side*1.2,1.6,.6),Vector3(.4,3.2,.4),TIMBER)
	_box(Vector3(0,3.1,.6),Vector3(3.0,.4,.5),LOG)
	_box(Vector3(0,3.36,.6),Vector3(3.3,.18,.7),SNOW)
	_box(Vector3(0,.8,1.1),Vector3(1.65,1.5,.12),DARK)
	_box(Vector3(0,.14,2.2),Vector3(1.9,.2,2.0),TIMBER)
	for index in range(4):_sphere(Vector3(-1.8+index*1.15,.40,2.15),Vector3(.38,.32,.37),COPPER,1)

func _guardhouse() -> void:
	for x in [-1.2,1.2]:
		for z in [-1.1,1.1]:_box(Vector3(x,1.6,z),Vector3(.27,3.2,.27),TIMBER)
	_box(Vector3(0,3.1,0),Vector3(3.1,.30,3.0),LOG)
	_box(Vector3(0,3.92,0),Vector3(2.6,1.35,2.5),SLATE)
	_winter_window(Vector3(0,4.0,1.32),1.4,.62)
	_snow_roof(3.35,3.3,4.75,1.0)
	for index in range(6):_box(Vector3(-1.0+index*.4,.3+index*.43,2.9-index*.27),Vector3(1.5,.14,.45),LOG)
	_box(Vector3(1.0,5.6,0),Vector3(.12,1.8,.12),COPPER,1)
	_box(Vector3(1.5,6.0,0),Vector3(.9,.55,.06),Color("#bd724f"))

func _harbor() -> void:
	_box(Vector3(0,.15,0),Vector3(5.2,.30,5.5),TIMBER)
	for z in range(13):_box(Vector3(0,.32,-2.5+z*.42),Vector3(5.1,.08,.38),LOG)
	for x in [-2.4,2.4]:
		for z in [-2.4,2.4]:_cylinder(Vector3(x,.6,z),.13,1.2,TIMBER,0,8);_sphere(Vector3(x,1.24,z),Vector3(.22,.11,.22),SNOW,0)
	_box(Vector3(-1.5,1.15,-1.4),Vector3(1.9,1.8,1.9),SLATE)
	_snow_roof(2.2,2.2,2.1,.8)
	_winter_window(Vector3(-1.5,1.4,-.4),.65,.6)
	for index in range(3):_box(Vector3(.8+index*.45,.65,-1.8),Vector3(.65,.65,.65),LOG)
	_box(Vector3(1.4,1.8,0),Vector3(.15,3.5,.15),COPPER,1)
	_box(Vector3(1.4,3.3,0),Vector3(2.2,.15,.15),COPPER,1)
	_box(Vector3(2.3,2.2,0),Vector3(.05,2.1,.05),DARK)

func _foundry() -> void:
	_cabin(5.0,4.2,Color("#677d85"))
	for x in [-1.45,1.45]:
		_cylinder(Vector3(x,3.8,-1.0),.35,4.8,DARK,1,12)
		_cylinder(Vector3(x,6.22,-1.0),.5,.18,COPPER,1,12)
	_box(Vector3(0,1.1,2.8),Vector3(3.2,1.4,1.1),DARK,1)
	_box(Vector3(0,1.25,3.4),Vector3(2.7,.42,.12),LIT,2)
	for index in range(mini(4,tier)):_box(Vector3(-1.4+index*.8,.45,3.7),Vector3(.62,.7,.7),Color("#9cabb0"),1)

func _fir() -> void:
	_cylinder(Vector3(0,.7,0),.22,1.4,TIMBER,0,7)
	for index in range(3):
		var radius: float=1.35-float(index)*.30
		var y: float=1.0+float(index)*.88
		_cone(Vector3(0,y,0),radius,1.85,Color("#365a64"))
		_cone(Vector3(0,y+.30,0),radius*.79,1.59,SNOW)

func _cone(at: Vector3,radius: float,height: float,color_: Color) -> void:
	for i in range(8):
		var a: float=TAU*float(i)/8.0;var b: float=TAU*float(i+1)/8.0
		var one: Vector3=at+Vector3(cos(a)*radius,0,sin(a)*radius);var two: Vector3=at+Vector3(cos(b)*radius,0,sin(b)*radius)
		_quad([one,two,at+Vector3.UP*height,at+Vector3.UP*height],Vector3(cos((a+b)*.5),radius/height,sin((a+b)*.5)).normalized(),color_)

func _rock() -> void:
	_sphere(Vector3(0,.30,0),Vector3(1.3,.85,1.0),Color("#6b8695"),0)
	_sphere(Vector3(-.12,.85,-.04),Vector3(1.07,.30,.86),SNOW,0)
func _mountain() -> void:
	_cone(Vector3.ZERO,8.0,12.0,Color("#7996aa"));_cone(Vector3(0,7.1,0),3.26,4.89,SNOW)
func _streetlamp() -> void:
	_cylinder(Vector3(0,.15,0),.3,.3,DARK,0,10)
	_cylinder(Vector3(0,1.25,0),.07,2.5,COPPER,1,8)
	_box(Vector3(0,2.55,0),Vector3(.44,.58,.44),DARK)
	_box(Vector3(0,2.55,0),Vector3(.31,.40,.47),LIT,2)
	_box(Vector3(0,2.90,0),Vector3(.60,.18,.60),SNOW)
func _site() -> void:
	_box(Vector3(0,.05,0),Vector3(4.6,.1,4.0),Color("#9eb7c0"),0,.2)
	for x in [-2.1,2.1]:
		for z in [-1.8,1.8]:_box(Vector3(x,.5,z),Vector3(.16,1.0,.16),LOG);_sphere(Vector3(x,1.0,z),Vector3(.2,.1,.2),SNOW,0)
	for z in [-1.8,1.8]:_box(Vector3(0,.65,z),Vector3(4.3,.12,.12),LOG)
	_box(Vector3(0,.12,0),Vector3(1.2,.12,.25),SNOW);_box(Vector3(0,.12,0),Vector3(.25,.12,1.2),SNOW)
