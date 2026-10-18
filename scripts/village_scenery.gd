extends Node3D
class_name WivoriVillageScenery

# Lightweight 3D neighborhood art. Streets actually join the existing market,
# while the new buildable plots remain clear for player-placed structures.
const Art=preload("res://scripts/art_library.gd")
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
	Art.place(self_root,"cafe" if awning else "house")

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
	var fountain:=Art.place(self,"park",Vector3(-8,0,22))
	var drops:=Node3D.new();drops.position=Vector3(-8,1.65,22);add_child(drops)
	for i in range(8):
		var a:=TAU*float(i)/8
		_p("sphere",Vector3(cos(a)*.35,.1,sin(a)*.35),Vector3(.055,.16,.055),Color("#b5e3df"),drops)
	fountains.append(drops)

func _process(delta: float) -> void:
	sparkle_time+=delta
	for i in range(wind_vanes.size()):
		wind_vanes[i].rotation.z=.12*sin(sparkle_time*1.7+float(i)*.6)
	for fountain in fountains:
		fountain.scale.y=.75+.20*sin(sparkle_time*2.3)
