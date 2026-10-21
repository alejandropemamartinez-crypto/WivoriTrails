extends Node3D
class_name WivoriCoastalScenery

# Hand-placed garden edges leave the central manual movement corridor clear.
# All static detail is merged into a few material surfaces, including flowers.
const Kit=preload("res://scripts/coastal_building.gd")
var world: MarketWorld

func _ready() -> void:
	name="Jardines y muros de piedra costeros"
	var kit:=Kit.new()
	for i in range(6):
		var at:=Vector3(-41.0+float(i)*16.0,-.25,-44.0-float(i%2)*3.0)
		kit._sphere(at,Vector3(24,8.0+float(i%3)*1.8,14),Color("#7b9d69") if i%2==0 else Color("#628f6b"),0)
	for z in [-9.0,0.0,8.0]:
		# The wall is outside the bed, with a continuous free approach on its east.
		for i in range(6):
			var at:=Vector3(-11.38,.31,z-2.1+float(i)*.84)
			kit._box(at,Vector3(.44,.57,.78),Kit.STONE.lightened(.035*float(i%3)),0,.095)
			kit._box(at+Vector3(0,.35,0),Vector3(.58,.14,.84),Kit.IVORY,0,.05)
		world.navigation.add_obstacle(Rect2(-11.68,z-2.55,.63,5.1))
		for at in [Vector3(-11.75,.0,z-2.45),Vector3(-11.75,0,z+2.45),Vector3(-5.0,0,z-2.55)]:
			_bush(kit,at,.82)
			_flowers(kit,at+Vector3(.35,0,.12),5)
	for at in [Vector3(-3.08,0,-13),Vector3(-3.08,0,13),Vector3(3.3,0,18),Vector3(12.7,0,8.5),Vector3(-12.3,0,15.9)]:
		kit._box(at+Vector3(0,.20,0),Vector3(1.6,.4,.90),Kit.STONE,0,.12)
		kit._box(at+Vector3(0,.44,0),Vector3(1.68,.13,.98),Kit.IVORY,0,.06)
		_bush(kit,at+Vector3(0,.46,0),1.05)
		_flowers(kit,at+Vector3(0,.50,0),6)
		world.navigation.add_obstacle(Rect2(at.x-.86,at.z-.51,1.72,1.02))
	# Small clusters frame the village rather than filling walkable lanes.
	for at in [Vector3(-14,0,-5),Vector3(-15,0,13),Vector3(15,0,-11),Vector3(-21,0,26),Vector3(17,0,-27)]:
		for i in range(4):
			var p: Vector3=at+Vector3(cos(float(i)*1.7)*1.1,0,sin(float(i)*1.7)*1.1)
			_bush(kit,p,.86);_flowers(kit,p,4)
	var mesh:=ArrayMesh.new()
	for builder in kit.builders.values():builder.index();builder.commit(mesh)
	var merged:=MeshInstance3D.new();merged.name="Bordes floridos agrupados";merged.mesh=mesh;add_child(merged)
	kit.free()

func _bush(kit: Node3D,at: Vector3,scale_: float) -> void:
	for i in range(3):
		var offset:=Vector3((float(i)-1)*.32,.35+float(i%2)*.11,0)*scale_
		kit._sphere(at+offset,Vector3(.80,.66,.70)*scale_,Color("#5f884b") if i%2==0 else Color("#7a9c52"),4)

func _flowers(kit: Node3D,at: Vector3,count: int) -> void:
	for i in range(count):
		var p:=at+Vector3(cos(float(i)*2.4)*.52,.65+float(i%2)*.15,sin(float(i)*2.4)*.34)
		var color_: Color=Kit.IVORY if i%3!=0 else Color("#e39a7c")
		for petal in range(5):
			var a: float=TAU*float(petal)/5.0
			kit._cylinder(p+Vector3(cos(a)*.12,0,sin(a)*.12),.105,.055,color_,0,8)
		kit._cylinder(p+Vector3(0,.035,0),.064,.06,Color("#e3b65c"),0,8)
