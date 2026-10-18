extends Node3D
class_name WivoriVillageScenery

# Lightweight 3D neighborhood art. Streets actually join the existing market,
# while the new buildable plots remain clear for player-placed structures.
var w: MarketWorld
var wind_vanes: Array[Node3D]=[]
var fountains: Array[Node3D]=[]
var sparkle_time:=0.0

func _ready() -> void:
	name="Barrios de Wivori y caminos"
	_build_roads()
	_build_neighborhoods()
	_build_market_details()
	_build_park()

func _p(kind: String, at: Vector3, scale_: Vector3, tint: Color, parent: Node3D=null) -> MeshInstance3D:
	return w.shape(self if parent==null else parent,kind,at,scale_,tint)

func _build_roads() -> void:
	var stone:=Color("#ceb38c")
	var edging:=Color("#e8cfa5")
	# Wide streets and the central crossroads create an understandable map.
	for street in [
		[Vector3(0,.028,25),Vector3(5.2,.09,19)],
		[Vector3(0,.028,-25),Vector3(5.2,.09,19)],
		[Vector3(-21,.028,18),Vector3(34,.09,3.1)],
		[Vector3(20,.028,-18),Vector3(32,.09,3.1)],
		[Vector3(-26,.028,-4),Vector3(3.1,.09,28)],
		[Vector3(27,.028,3),Vector3(3.1,.09,24)]
	]:
		_p("box",street[0],street[1],stone)
	# Low cobbled curbs define the streets without impeding the player.
	for z in [-32.0,-26.0,25.5,31.5]:
		for x in [-2.8,2.8]:
			_p("box",Vector3(x,.115,z),Vector3(.22,.18,2.8),edging)
	for x in [-31.0,-22.0,20.0,31.0]:
		for z in [-.5,6.0]:
			_p("box",Vector3(x,.115,z),Vector3(2.7,.14,.20),edging)
	# The light posts extend the travel paths into the districts.
	for at in [
		Vector3(-7,0,24),Vector3(7,0,24),Vector3(-7,0,-25),
		Vector3(7,0,-25),Vector3(-22,0,13),Vector3(23,0,-12)
	]:
		_p("cylinder",at+Vector3(0,1.1,0),Vector3(.15,2.2,.15),Color("#90724f"))
		_p("sphere",at+Vector3(0,2.2,0),Vector3(.45,.47,.45),Color("#f7d38f"))
		_p("cone",at+Vector3(0,2.66,0),Vector3(.85,.42,.85),Color("#598778"))

func _cottage(self_root: Node3D, accent: Color, roof: Color, awning: bool) -> void:
	_p("box",Vector3(0,.17,0),Vector3(5.1,.30,4.9),Color("#b99a74"),self_root)
	_p("box",Vector3(0,1.70,0),Vector3(4.4,2.78,4.1),accent,self_root)
	# Ridged roof with two sloped, layered halves rather than a plain lid.
	for x in [-1.26,1.26]:
		var panel:=_p("box",Vector3(x,3.36,0),Vector3(3.10,.24,4.77),roof,self_root)
		panel.rotation.z=(-.48 if x<0 else .48)
		var trim:=_p("box",Vector3(x,3.16,2.22),Vector3(2.95,.14,.17),roof.darkened(.20),self_root)
		trim.rotation.z=(-.48 if x<0 else .48)
	_p("box",Vector3(-1.29,1.10,2.11),Vector3(.95,1.9,.16),Color("#916c53"),self_root)
	for x in [.3,1.52]:
		_p("box",Vector3(x,2.0,2.14),Vector3(.78,.78,.12),Color("#eff0d6"),self_root)
		_p("box",Vector3(x,2.0,2.22),Vector3(.52,.51,.06),Color("#9dcfce"),self_root)
		_p("box",Vector3(x,1.61,2.24),Vector3(1.0,.16,.34),Color("#a97d5c"),self_root)
		_p("box",Vector3(x,1.74,2.40),Vector3(.73,.22,.25),Color("#79a779"),self_root)
	_p("box",Vector3(-1.2,4.0,-.6),Vector3(.68,1.1,.70),Color("#bb855b"),self_root)
	if awning:
		for x in [-1.1,-.25,.6,1.45]:
			_p("box",Vector3(x,1.23,2.38),Vector3(.81,.10,1.04),
			Color("#f3ddbd") if x<0 else Color("#ba7863"),self_root)
	# Very cheap detail makes architecture legible from isometric camera.
	for z in [-1.6,1.6]:
		_p("box",Vector3(2.2,.59,z),Vector3(.22,.35,.61),Color("#86ab75"),self_root)
		_p("sphere",Vector3(2.2,1.01,z),Vector3(.74,.60,.80),Color("#70a371"),self_root)

func _build_neighborhoods() -> void:
	var coords=[
		Vector3(-25,0,21),Vector3(-25,0,11),Vector3(-9,0,-27),
		Vector3(10,0,-27),Vector3(27,0,28),Vector3(18,0,29)
	]
	var facades=[Color("#edd7b5"),Color("#e6b9a4"),Color("#b9d4c4"),
		Color("#e8cc96"),Color("#d6c8e3"),Color("#f2c8b8")]
	var roofs=[Color("#c77e6d"),Color("#8f8ea8"),Color("#a76553"),
		Color("#bb875f"),Color("#72958a"),Color("#c57361")]
	for i in range(coords.size()):
		var building:=Node3D.new()
		building.name="Casa decorada del barrio %d" % (i+1)
		building.position=coords[i]
		building.rotation.y=[0.0,.23,-.18,.18,PI,-.22][i]
		add_child(building)
		_cottage(building,facades[i],roofs[i],i%2==0)
		w.navigation.add_obstacle(Rect2(coords[i].x-2.6,coords[i].z-2.4,5.2,4.8))
	# Green pockets make the walk to future districts feel inhabited.
	for loc in [
		Vector3(-21,0,-27),Vector3(-20,0,26),
		Vector3(17,0,-27),Vector3(31,0,13),Vector3(-9,0,20)
	]:
		_p("cylinder",loc+Vector3(0,1.32,0),Vector3(.36,2.65,.36),Color("#9f7758"))
		for offset in [Vector3(-.55,2.45,0),Vector3(.50,2.7,0),Vector3(0,2.9,.42)]:
			_p("sphere",loc+offset,Vector3(1.16,.92,1.03),Color("#699d77"))
		for i in range(3):
			var x: float=(float(i)-1.0)*.8
			_p("sphere",loc+Vector3(x,.20,1.2),Vector3(.29,.27,.28),
				Color("#e4aa79") if i%2==0 else Color("#e0a7c1"))

func _build_market_details() -> void:
	for at in [Vector3(-6,0,5),Vector3(8,0,7),Vector3(-9,0,14)]:
		_p("box",at+Vector3(0,.48,0),Vector3(1.6,.20,.64),Color("#b1845f"))
		for x in [-.61,.61]:
			_p("box",at+Vector3(x,.24,0),Vector3(.15,.48,.55),Color("#7e6950"))
	# Hanging flags and color-coded market street banners.
	for i in range(7):
		var p:=Vector3(-11+float(i)*3.3,4.1,-10.2)
		_p("box",p,Vector3(2.8,.06,.07),Color("#e7d6b4"))
		var flag:=Node3D.new();flag.position=p+Vector3(0,-.36,0)
		add_child(flag)
		_p("box",Vector3.ZERO,Vector3(.54,.58,.04),
			[Color("#c97661"),Color("#6f9b87"),Color("#e7bd73")][i%3],flag)
		wind_vanes.append(flag)

func _build_park() -> void:
	# Small civic square with benches, planters and moving fountain.
	var core:=Vector3(-8,0,22)
	_p("box",core+Vector3(0,.09,0),Vector3(6.6,.17,7.0),Color("#dbcca8"))
	_p("cylinder",core+Vector3(0,.33,0),Vector3(3.2,.43,3.2),Color("#b9c5af"))
	_p("cylinder",core+Vector3(0,.62,0),Vector3(2.45,.18,2.45),Color("#82c5c7"))
	var jet:=Node3D.new()
	jet.position=core+Vector3(0,1.04,0);jet.name="Fuente animada"
	add_child(jet)
	_p("sphere",Vector3.ZERO,Vector3(.41,.65,.41),Color("#ace1e0"),jet)
	fountains.append(jet)
	for x in [-2.55,2.55]:
		_p("box",core+Vector3(x,.58,0),Vector3(.5,.15,1.28),Color("#986f55"))
		for z in [-.45,.45]:
			_p("box",core+Vector3(x,.28,z),Vector3(.38,.55,.15),Color("#785a43"))
	for j in range(12):
		var angle:=TAU*float(j)/12.0
		var where:=core+Vector3(cos(angle)*4.1,.19,sin(angle)*4.0)
		_p("sphere",where,Vector3(.36,.33,.37),
			Color("#f2bb66") if j%3==0 else Color("#cc8b97"))

func _process(delta: float) -> void:
	sparkle_time+=delta
	for i in range(wind_vanes.size()):
		wind_vanes[i].rotation.z=.12*sin(sparkle_time*1.7+float(i)*.6)
	for fountain in fountains:
		fountain.scale.y=.75+.20*sin(sparkle_time*2.3)
