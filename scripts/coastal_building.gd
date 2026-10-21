extends Node3D
class_name WivoriCoastalBuilding

# Original editable architecture. Chamfered geometry, painted vertex colours
# and four shared material finishes replace the interchangeable GLB cottages.
# A whole building is one mesh with a single material surface, not hundreds of
# independent decorative draw calls. It owns no economy, input or collision.
const PAINT=preload("res://scripts/coastal_surface.gdshader")
const ATLAS=preload("res://assets/textures/coastal_atlas.png")
const IVORY=Color("#f5dfb4")
const STONE=Color("#bba58b")
const WOOD=Color("#a66b3e")
const HONEY=Color("#d6a05a")
const INK=Color("#294754")
const GLASS=Color("#66b7bd")
const CORAL=Color("#d9785c")
const BLUE=Color("#427caa")
const JADE=Color("#438c79")
static var meshes: Dictionary={}
static var finishes: Dictionary={}
var kind:="house"
var builders: Dictionary={}
var rotor: Node3D
var draw: MeshInstance3D
var occlusion_materials: Array[ShaderMaterial]=[]
var check_wait:=0.0
var cut_height:=100.0
var target_cut:=100.0

static func supports(asset: String) -> bool:
	return asset.begins_with("coastal_") or asset.begins_with("booth_") or asset in ["market","house","bakery","cafe","depot","workshop","mill","watchtower","greenhouse","farm_barn","farm_coop","farm_corral","treasury","tree"]

static func create(parent: Node3D,asset: String,at: Vector3,size_: Vector3) -> Node3D:
	var node:=WivoriCoastalBuilding.new()
	node.kind=asset.trim_prefix("coastal_")
	node.name="Arquitectura costera · "+node.kind
	node.position=at;node.scale=size_
	parent.add_child(node)
	return node

func _ready() -> void:
	if not meshes.has(kind):
		_build()
		var mesh:=ArrayMesh.new()
		for builder in builders.values():builder.index();builder.commit(mesh)
		meshes[kind]=mesh
		builders.clear()
	var instance:=MeshInstance3D.new()
	instance.mesh=meshes[kind];instance.name="Volúmenes y materiales de "+kind
	add_child(instance)
	draw=instance
	if kind in ["mill","grainmill"]:_rotor()
	set_process(kind!="bed")

func _builder(_finish: int) -> SurfaceTool:
	# UV2 stores the finish per vertex so wood, plaster, leaves and glass share
	# one GPU draw instead of one draw per material on every building and tree.
	if not builders.has(0):
		var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		if not finishes.has(0):
			var mat:=ShaderMaterial.new();mat.shader=PAINT;mat.set_shader_parameter("atlas",ATLAS);finishes[0]=mat
		tool.set_material(finishes[0]);builders[0]=tool
	return builders[0]

func _tri(a: Vector3,b: Vector3,c: Vector3,normal: Vector3,color_: Color,finish: int=0) -> void:
	var builder:=_builder(finish)
	# Cooler undersides and warmer upward planes bake subtle local depth.
	var tint: Color=color_.lerp(Color("#5e777c"),.12*maxf(0.0,-normal.y))
	for vertex: Vector3 in [a,b,c]:
		builder.set_normal(normal);builder.set_color(tint)
		builder.set_uv(Vector2(vertex.x+vertex.z*.41,vertex.y+vertex.z*.37))
		builder.set_uv2(Vector2(float(finish),0.0))
		builder.add_vertex(vertex)

func _quad(points: Array,normal: Vector3,color_: Color,finish: int=0) -> void:
	# Godot front faces are clockwise. Reorder each face against its normal.
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0:
		_tri(points[0],points[2],points[1],normal,color_,finish)
		_tri(points[0],points[3],points[2],normal,color_,finish)
	else:
		_tri(points[0],points[1],points[2],normal,color_,finish)
		_tri(points[0],points[2],points[3],normal,color_,finish)

func _box(at: Vector3,size_: Vector3,color_: Color,finish: int=0,bevel: float=.07,basis_: Basis=Basis.IDENTITY) -> void:
	var half:=size_*.5
	var radius: float=minf(bevel,minf(half.x,minf(half.y,half.z))*.65)
	var inner:=half-Vector3.ONE*radius
	# Six broad faces, twelve bevel strips, eight corner triangles.
	for axis in range(3):
		var u: int=(axis+1)%3;var v: int=(axis+2)%3
		for side in [-1.0,1.0]:
			var points: Array=[]
			for signs in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p:=Vector3.ZERO;p[axis]=half[axis]*side;p[u]=inner[u]*signs.x;p[v]=inner[v]*signs.y
				points.append(at+basis_*p)
			var normal:=Vector3.ZERO;normal[axis]=side
			_quad(points,basis_*normal,color_,finish)
		for s in [-1.0,1.0]:
			for t in [-1.0,1.0]:
				var points: Array=[]
				for end in [-1.0,1.0]:
					var p:=Vector3.ZERO;p[axis]=inner[axis]*end;p[u]=half[u]*s;p[v]=inner[v]*t
					var q:=Vector3.ZERO;q[axis]=inner[axis]*end;q[u]=inner[u]*s;q[v]=half[v]*t
					if end<0:points.append(at+basis_*p);points.append(at+basis_*q)
					else:points.append(at+basis_*q);points.append(at+basis_*p)
				var normal:=Vector3.ZERO;normal[u]=s;normal[v]=t
				_quad(points,(basis_*normal).normalized(),color_.lightened(.035),finish)
	for x in [-1.0,1.0]:
		for y in [-1.0,1.0]:
			for z in [-1.0,1.0]:
				var p:=inner*Vector3(x,y,z);var a:=p+Vector3(radius*x,0,0);var b:=p+Vector3(0,radius*y,0);var c:=p+Vector3(0,0,radius*z)
				var normal: Vector3=(basis_*Vector3(x,y,z)).normalized()
				var points: Array=[at+basis_*a,at+basis_*b,at+basis_*c]
				if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0:_tri(points[0],points[2],points[1],normal,color_,finish)
				else:_tri(points[0],points[1],points[2],normal,color_,finish)

func _cylinder(at: Vector3,radius: float,height: float,color_: Color,finish: int=0,segments: int=16,basis_: Basis=Basis.IDENTITY) -> void:
	for i in range(segments):
		var a: float=TAU*float(i)/float(segments);var b: float=TAU*float(i+1)/float(segments)
		var low_a:=Vector3(cos(a)*radius,-height*.5,sin(a)*radius);var low_b:=Vector3(cos(b)*radius,-height*.5,sin(b)*radius)
		var high_a:=low_a+Vector3.UP*height;var high_b:=low_b+Vector3.UP*height
		_quad([at+basis_*low_a,at+basis_*high_a,at+basis_*high_b,at+basis_*low_b],basis_*Vector3(cos((a+b)*.5),0,sin((a+b)*.5)),color_,finish)
		_quad([at+basis_*Vector3(0,height*.5,0),at+basis_*high_a,at+basis_*high_b,at+basis_*Vector3(0,height*.5,0)],basis_*Vector3.UP,color_.lightened(.08),finish)
		_quad([at+basis_*Vector3(0,-height*.5,0),at+basis_*low_b,at+basis_*low_a,at+basis_*Vector3(0,-height*.5,0)],basis_*Vector3.DOWN,color_.darkened(.1),finish)

func _roof(width: float,depth: float,y: float,rise: float,color_: Color) -> void:
	# A curved tiled roof, with individual overlapping bands and warm eaves.
	var count:=10
	for i in range(count):
		var x: float=(float(i)+.5)/float(count)*width-width*.5
		var curve: float=cos(x/width*PI)
		var slope: float=-sin(x/width*PI)*rise*PI/width
		var basis_:=Basis(Vector3.BACK,atan(slope))
		for side in [-1.0,1.0]:
			var top_a: float=y+rise*cos((x-width/float(count)*.5)/width*PI)
			var top_b: float=y+rise*cos((x+width/float(count)*.5)/width*PI)
			var z: float=(depth*.5-.16)*side
			_quad([Vector3(x-width/float(count)*.5,y-.12,z),Vector3(x+width/float(count)*.5,y-.12,z),Vector3(x+width/float(count)*.5,top_b,z),Vector3(x-width/float(count)*.5,top_a,z)],Vector3(0,0,side),IVORY,0)
		_box(Vector3(x,y+rise*curve,0),Vector3(width/float(count)*1.10,.22,depth),color_.lightened(.04*float(i%3)),2,.05,basis_)
		for z in range(4):
			_box(Vector3(x,y+rise*curve+.12,-depth*.5+(float(z)+.5)*depth/4.0),Vector3(width/float(count)*.88,.07,depth/4.0*.95),color_.lightened(.045 if (i+z)%2==0 else -.015),2,.025,basis_)
	_box(Vector3(0,y-.06,depth*.5),Vector3(width+.12,.18,.18),HONEY,1)
	_box(Vector3(0,y-.06,-depth*.5),Vector3(width+.12,.18,.18),HONEY,1)

func _window(at: Vector3,size_: Vector2=Vector2(.78,.94)) -> void:
	_box(at,Vector3(size_.x+.17,size_.y+.17,.16),IVORY,0)
	_box(at+Vector3(0,0,.10),Vector3(size_.x,size_.y,.08),INK,0,.025)
	_box(at+Vector3(0,.025,.15),Vector3(size_.x-.09,size_.y-.09,.025),GLASS,3,.01)
	_box(at+Vector3(0,0,.18),Vector3(.065,size_.y,.07),IVORY,0,.02)
	_box(at+Vector3(0,0,.18),Vector3(size_.x,.065,.07),IVORY,0,.02)
	_box(at+Vector3(0,-size_.y*.5-.14,.12),Vector3(size_.x+.35,.15,.30),HONEY,1)

func _door(at: Vector3,color_: Color=BLUE,width: float=.85) -> void:
	_box(at+Vector3(0,1.0,0),Vector3(width+.25,2.13,.18),HONEY,1)
	_box(at+Vector3(0,1.0,.11),Vector3(width,1.98,.09),color_,1)
	for i in range(3):_box(at+Vector3((float(i)-1)*width/3.5,1.0,.17),Vector3(.018,1.82,.025),color_.darkened(.12),1,.004)
	_cylinder(at+Vector3(width*.29,.90,.22),.055,.07,Color("#eac374"),3,12,Basis(Vector3.RIGHT,PI*.5))
	_box(at+Vector3(0,.07,.42),Vector3(width+.58,.18,.80),IVORY,0)

func _lantern(at: Vector3) -> void:
	_box(at+Vector3(0,.32,0),Vector3(.20,.12,.27),INK,3,.03)
	_box(at,Vector3(.27,.43,.22),INK,3,.045)
	_box(at+Vector3(0,0,.125),Vector3(.17,.29,.025),Color("#ffd68b"),0,.015)
	_box(at+Vector3(0,.25,0),Vector3(.36,.10,.32),HONEY,3,.03)

func _planter(at: Vector3,width: float=1.0) -> void:
	_box(at,Vector3(width,.32,.42),WOOD,1)
	_box(at+Vector3(0,.20,0),Vector3(width*.94,.16,.37),Color("#4e7c4b"),0)
	for i in range(4):
		var pos: Vector3=at+Vector3((float(i)-1.5)*width*.21,.32,.02)
		_cylinder(pos,.095,.13,CORAL if i%2==0 else IVORY,0,10,Basis(Vector3.RIGHT,PI*.5))

func _base(width: float=4.4,depth: float=3.6) -> void:
	_box(Vector3(0,.11,0),Vector3(width+.40,.22,depth+.40),STONE,0,.12)
	_box(Vector3(0,.26,0),Vector3(width+.12,.14,depth+.10),IVORY,0,.06)

func _sphere(at: Vector3,size_: Vector3,color_: Color,finish: int=4) -> void:
	for ring in range(6):
		var a: float=PI*float(ring)/6.0;var b: float=PI*float(ring+1)/6.0
		for slice_ in range(12):
			var c: float=TAU*float(slice_)/12.0;var d: float=TAU*float(slice_+1)/12.0
			var p:=Vector3(sin(a)*cos(c),cos(a),sin(a)*sin(c));var q:=Vector3(sin(b)*cos(c),cos(b),sin(b)*sin(c))
			var r:=Vector3(sin(b)*cos(d),cos(b),sin(b)*sin(d));var s:=Vector3(sin(a)*cos(d),cos(a),sin(a)*sin(d))
			var normals: Array=[p,q,r,s]
			var uvs: Array=[Vector2(float(slice_)/12.0,a/PI),Vector2(float(slice_)/12.0,b/PI),Vector2(float(slice_+1)/12.0,b/PI),Vector2(float(slice_+1)/12.0,a/PI)]
			var points: Array=[at+p*size_*.5,at+q*size_*.5,at+r*size_*.5,at+s*size_*.5]
			var order: Array=[0,2,1,0,3,2]
			var average: Vector3=(p+q+r+s).normalized()
			if (points[1]-points[0]).cross(points[2]-points[0]).dot(average)<0:order=[0,1,2,0,2,3]
			var builder:=_builder(finish)
			for index: int in order:
				var normal: Vector3=(normals[index]/size_).normalized()
				builder.set_normal(normal);builder.set_color(color_);builder.set_uv(uvs[index]);builder.set_uv2(Vector2(float(finish),0));builder.add_vertex(points[index])

func _tree() -> void:
	_cylinder(Vector3(0,1.20,0),.19,2.40,WOOD,1,12)
	for side in [-1.0,1.0]:_cylinder(Vector3(side*.27,1.95,0),.105,1.0,WOOD,1,12,Basis(Vector3.FORWARD,-side*.67))
	var crowns: Array=[
		[Vector3(-.72,2.35,0),Vector3(1.52,1.18,1.54),Color("#487b46")],
		[Vector3(.62,2.43,.25),Vector3(1.69,1.30,1.56),Color("#679348")],
		[Vector3(.12,2.88,-.34),Vector3(1.76,1.42,1.66),Color("#729c50")],
		[Vector3(-.40,3.23,.16),Vector3(1.31,1.14,1.26),Color("#86aa59")],
		[Vector3(.72,3.12,-.25),Vector3(1.11,1.02,1.16),Color("#70984b")]
	]
	for crown in crowns:_sphere(crown[0],crown[1],crown[2],4)

func _cottage(type_: String) -> void:
	var color_: Color=CORAL if type_=="house" else IVORY
	var roof: Color=BLUE if type_ in ["bakery","breadshop","cannery"] else JADE if type_ in ["cafe","dairy"] else CORAL
	_base();_box(Vector3(0,1.53,0),Vector3(4.15,2.55,3.3),color_,0,.13)
	for x in [-2.02,2.02]:_box(Vector3(x,1.65,1.67),Vector3(.18,2.7,.18),HONEY,1)
	for y in [.49,2.75]:_box(Vector3(0,y,1.68),Vector3(4.25,.20,.16),HONEY,1)
	_roof(4.8,4.05,2.89,.78,roof)
	_box(Vector3(-1.30,3.45,-.55),Vector3(.55,1.65,.55),IVORY,0)
	_box(Vector3(-1.30,4.29,-.55),Vector3(.78,.18,.78),STONE,0)
	if type_ in ["bakery","breadshop","cannery"]:
		# Visible oven opening and bread counter, rather than another house.
		_box(Vector3(.80,1.35,1.73),Vector3(1.98,1.80,.20),HONEY,1,.12)
		_box(Vector3(.80,1.41,1.88),Vector3(1.70,1.48,.10),INK,0,.16)
		_box(Vector3(.80,.87,2.02),Vector3(2.12,.19,.66),IVORY,0)
		for i in range(4):
			_box(Vector3(.20+float(i)*.39,1.07,2.02),Vector3(.35,.24,.29),Color("#e8af55"),0,.11)
		_door(Vector3(-1.26,.35,1.73),BLUE,.75)
		_box(Vector3(.65,2.55,1.84),Vector3(1.95,.38,.16),IVORY,0)
		# Tiny bread emblem belongs to the facade, not a screen-sized sign.
		_box(Vector3(.65,2.57,1.96),Vector3(.90,.22,.16),HONEY,0,.10)
	else:
		_door(Vector3(-.77,.35,1.73),roof)
		_window(Vector3(1.02,1.85,1.73));_planter(Vector3(1.02,1.20,1.90),1.2)
	_lantern(Vector3(-1.80,2.15,1.91))

func _stall(type_: String) -> void:
	var small: bool=type_.begins_with("booth_")
	var width: float=1.95 if small else 4.7
	var depth: float=1.75 if small else 2.55
	var top: float=2.45 if small else 3.1
	var accent: Color={"booth_helper":CORAL,"booth_collector":JADE,"booth_bag":Color("#aa7558"),"booth_speed":BLUE,"booth_checkout":JADE,"booth_lock":Color("#727aa3"),"booth_alarm":CORAL,"booth_guard":BLUE,"booth_pier":BLUE,"booth_expand":JADE}.get(type_,CORAL)
	_base(width,depth)
	for x in [-width*.46,width*.46]:
		for z in [-depth*.42,depth*.42]:_box(Vector3(x,top*.5,z),Vector3(.14,top,.14),WOOD,1)
	for i in range(7):
		var x: float=(float(i)+.5)*width/7.0-width*.5
		var tint: Color=IVORY if i%2==0 else accent
		_box(Vector3(x,top,.0),Vector3(width/7.0*1.02,.14,depth+0.6),tint,0,.07,Basis(Vector3.RIGHT,-.10))
		_box(Vector3(x,top-.16,depth*.5+.30),Vector3(width/7.0*.96,.35,.14),tint,0,.12)
	_box(Vector3(0,.72,depth*.40),Vector3(width,.92,.44),WOOD,1)
	_box(Vector3(0,1.22,depth*.40),Vector3(width+.12,.16,.65),HONEY,1)
	for i in range(5):_box(Vector3((float(i)-2)*width/5.5,.73,depth*.5+.04),Vector3(.025,.77,.03),HONEY,1,.004)
	if not small:
		for i in range(4):
			_box(Vector3((float(i)-1.5)*1.08,1.36,depth*.40),Vector3(.96,.23,.60),WOOD,1)
			_box(Vector3((float(i)-1.5)*1.08,1.50,depth*.40),Vector3(.82,.12,.47),Color("#55834d"),0)
	_lantern(Vector3(-width*.5-.03,top-.62,depth*.42+.06))

func _barn(type_: String) -> void:
	var coop: bool=type_ in ["henhouse","farm_coop"]
	var color_: Color=Color("#c76b50") if not coop else Color("#deb576")
	_base();_box(Vector3(0,1.45,0),Vector3(4.2,2.5,3.3),color_,1,.09)
	_roof(4.8,3.95,2.72,.97,Color("#6c8895") if not coop else CORAL)
	for x in [-1.98,1.98]:_box(Vector3(x,1.50,1.74),Vector3(.17,2.52,.16),IVORY,0)
	_box(Vector3(0,2.62,1.75),Vector3(4.18,.19,.18),IVORY,0)
	_box(Vector3(0,1.29,1.73),Vector3(2.25,2.06,.19),INK,0)
	for x in [-.62,.62]:
		_box(Vector3(x,1.29,1.90),Vector3(1.06,2.04,.13),color_.darkened(.08),1)
		_box(Vector3(x,1.29,2.0),Vector3(.12,2.04,.07),IVORY,0,.02,Basis(Vector3.FORWARD,.44 if x<0 else -.44))
	for x in [-1.50,1.50]:_window(Vector3(x,2.08,1.74),Vector2(.42,.45))
	if coop:_box(Vector3(0,.30,2.50),Vector3(1.1,.20,1.3),WOOD,1,.05,Basis(Vector3.RIGHT,-.20))

func _industrial(type_: String) -> void:
	_base(4.55,3.8)
	var height_: float=2.85 if type_ in ["packaging_plant","shipping_hub"] else 2.30
	var tint: Color=IVORY if type_!="preserves_line" else Color("#b5cfbf")
	# Open production bays expose the existing working press, tanks and hoist.
	# Solid front walls previously enclosed those animated machines.
	_box(Vector3(0,height_*.5+.30,-1.65),Vector3(4.35,height_,.24),tint,0,.09)
	for x in [-2.06,2.06]:_box(Vector3(x,height_*.5+.30,0),Vector3(.22,height_,3.55),tint,0,.07)
	_box(Vector3(0,height_+.12,1.68),Vector3(4.35,.42,.25),HONEY,1)
	if type_ in ["packaging_plant","shipping_hub"]:
		for i in range(3):
			var x: float=-1.5+float(i)*1.5
			_box(Vector3(x,height_+.50,0),Vector3(1.65,.22,4.1),BLUE,2,.05,Basis(Vector3.FORWARD,-.22))
			_window(Vector3(x,height_+.16,1.84),Vector2(1.14,.37))
	else:_roof(4.9,4.1,height_+.30,.37,JADE if type_=="preserves_line" else BLUE)
	for x in [-1.3,1.3]:
		_box(Vector3(x,.40,1.80),Vector3(1.75,.22,.55),STONE,0)
		if type_ not in ["packaging_plant","preserves_line"]:
			# Partly raised loading shutters leave the production floor visible.
			for i in range(3):_box(Vector3(x,1.94+float(i)*.22,1.79),Vector3(1.30,.17,.08),Color("#678b96"),3,.025)
	_lantern(Vector3(0,2.15,1.94))

func _glasshouse() -> void:
	_base();_box(Vector3(0,.54,0),Vector3(4.2,.62,3.4),IVORY,0)
	_box(Vector3(0,1.70,0),Vector3(3.95,1.85,3.22),GLASS,3,.12)
	_roof(4.35,3.7,2.59,.65,Color("#83bfb5"))
	for x in [-1.95,-.98,0.0,.98,1.95]:_box(Vector3(x,1.77,1.66),Vector3(.09,2.1,.12),IVORY,0,.02)
	for y in [1.03,2.13]:_box(Vector3(0,y,1.67),Vector3(4.1,.09,.12),IVORY,0,.02)
	_door(Vector3(0,.32,1.74),JADE,.80)

func _tower() -> void:
	_base(3.5,3.2);_box(Vector3(0,2.30,0),Vector3(2.7,4.12,2.7),IVORY,0,.13)
	_box(Vector3(0,3.68,0),Vector3(3.3,.22,3.3),HONEY,1)
	_roof(3.7,3.65,4.47,.71,BLUE)
	_door(Vector3(0,.33,1.40),BLUE,.85)
	_window(Vector3(0,3.68,1.44),Vector2(1.35,1.04))
	for x in [-1.25,1.25]:_box(Vector3(x,2.32,1.40),Vector3(.15,4.08,.12),HONEY,1)

func _build() -> void:
	if kind=="market" or kind.begins_with("booth_"):_stall(kind);return
	match kind:
		"house","cafe","dairy","bakery","breadshop","cannery":_cottage(kind)
		"farm_barn","cowbarn","farm_coop","henhouse","farm_corral","pigpen":_barn(kind)
		"greenhouse","grain":_glasshouse()
		"watchtower","route_watch","trade_center","aurora_chart_house":_tower()
		"mill","grainmill":_tower()
		"treasury":_cottage("cafe")
		"bed":_bed()
		"tree":_tree()
		_:_industrial(kind)

func _bed() -> void:
	_box(Vector3(0,.08,0),Vector3(5.6,.24,4.4),WOOD,1,.10)
	_box(Vector3(0,.27,0),Vector3(5.04,.17,3.92),Color("#6f4d36"),5,.08)
	for z in [-2.10,2.10]:
		_box(Vector3(0,.28,z),Vector3(5.7,.36,.20),HONEY,1,.065)
		_box(Vector3(0,.48,z),Vector3(5.80,.10,.28),WOOD.lightened(.13),1,.045)
	for x in [-2.70,2.70]:_box(Vector3(x,.28,0),Vector3(.20,.36,4.32),HONEY,1,.065)
	for x in [-2.72,2.72]:
		for z in [-2.10,2.10]:
			_box(Vector3(x,.27,z),Vector3(.32,.52,.32),WOOD,1,.06)
			_cylinder(Vector3(x,.55,z),.11,.055,Color("#eac48e"),3,12)
	for z in [-1.23,0.0,1.23]:_box(Vector3(0,.36,z),Vector3(4.85,.055,.52),Color("#805d41"),0,.025)

func _rotor() -> void:
	rotor=Node3D.new();rotor.name="Rotordel molino";rotor.position=Vector3(0,3.60,1.90);add_child(rotor)
	# Separate moving mesh; the complete building remains cached and static.
	var blade_mesh:=BoxMesh.new();blade_mesh.size=Vector3(.32,3.8,.10)
	var mat:=StandardMaterial3D.new();mat.albedo_color=IVORY;mat.roughness=.9
	for angle in [0.0,PI*.5]:
		var blade:=MeshInstance3D.new();blade.mesh=blade_mesh;blade.material_override=mat;blade.rotation.z=angle;rotor.add_child(blade)

func _process(delta: float) -> void:
	if rotor!=null:rotor.rotation.z+=delta*.36
	if kind=="tree":return
	check_wait-=delta
	if check_wait<=0:
		check_wait=.16
		_update_occlusion()
	if not occlusion_materials.is_empty() and not is_equal_approx(cut_height,target_cut):
		cut_height=move_toward(cut_height,target_cut,delta*24.0)
		for mat in occlusion_materials:mat.set_shader_parameter("cut_height",cut_height)

func _update_occlusion() -> void:
	if not is_visible_in_tree() or draw==null:return
	var player: Node3D=get_tree().get_first_node_in_group("wivori_player") as Node3D
	var camera:=get_viewport().get_camera_3d()
	if player==null or camera==null:return
	var center: Vector3=global_position+Vector3.UP*1.8
	if center.distance_to(camera.global_position)>=player.global_position.distance_to(camera.global_position)-.4:
		target_cut=8.0;return
	var bounds:=draw.get_aabb()
	var screen_bounds:=Rect2()
	var first:=true
	for x in [0.0,1.0]:
		for y in [0.0,1.0]:
			for z in [0.0,1.0]:
				var at: Vector3=draw.to_global(bounds.position+bounds.size*Vector3(x,y,z))
				if camera.is_position_behind(at):continue
				var projected:=camera.unproject_position(at)
				if first:screen_bounds=Rect2(projected,Vector2.ONE);first=false
				else:screen_bounds=screen_bounds.expand(projected)
	var head: Vector2=camera.unproject_position(player.global_position+Vector3.UP*1.25)
	var overlaps: bool=not first and screen_bounds.has_point(head)
	target_cut=1.12 if overlaps else 8.0
	if overlaps and occlusion_materials.is_empty():
		for index in range(draw.mesh.get_surface_count()):
			var mat: ShaderMaterial=draw.mesh.surface_get_material(index).duplicate() as ShaderMaterial
			draw.set_surface_override_material(index,mat);occlusion_materials.append(mat)
		cut_height=8.0
