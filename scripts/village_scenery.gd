extends Node3D
class_name WivoriVillageScenery

# Lightweight 3D neighborhood art. Streets actually join the existing market,
# while the new buildable plots remain clear for player-placed structures.
const Art=preload("res://scripts/art_library.gd")
var w: MarketWorld
var wind_vanes: Array[Node3D]=[]
var fountains: Array[Node3D]=[]
var sparkle_time:=0.0
var residents: Array[Dictionary]=[]

func _ready() -> void:
	name="Barrios de Wivori y caminos"
	_build_roads()
	_build_neighborhoods()
	_build_market_details()
	_build_park()
	_build_lanes()
	_batch_static()
	call_deferred("_populate")

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
		var path:=_p("box",street[0],street[1],stone)
		var surface:=ShaderMaterial.new();surface.shader=preload("res://scripts/ground.gdshader");surface.set_shader_parameter("cobbled",true);surface.set_shader_parameter("base_color",Color("#bcb9a9"));path.material_override=surface
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
		Art.place(self,"oak_bench",at)
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
	for resident in residents:
		if resident["wait"]>0:resident["wait"]-=delta;continue
		var route: Array=resident["route"]
		if w.get_parent()._move_actor(resident["actor"],route[resident["index"]],1.5,delta):
			resident["index"]=(resident["index"]+1)%route.size();resident["wait"]=2.2;resident["actor"].act("turn")

func _build_lanes() -> void:
	var vertices:=PackedVector3Array();var indices:=PackedInt32Array();var normals:=PackedVector3Array()
	for at in preload("res://scripts/town_builder.gd").LOCATIONS:
		var finish: Vector3=at+Vector3(0,0,3.2)
		var start:=Vector3(0,0,clampf(finish.z,-20,20));var control:=Vector3(finish.x*.55,0,start.z)
		var first:=vertices.size()
		for i in range(13):
			var t:=float(i)/12;var p:=start*(1-t)*(1-t)+control*2*(1-t)*t+finish*t*t
			var tangent: Vector3=(control-start)*2*(1-t)+(finish-control)*2*t
			var side:=Vector3(-tangent.z,0,tangent.x).normalized()
			vertices.append(p+side+Vector3(0,.115,0));vertices.append(p-side+Vector3(0,.115,0));normals.append(Vector3.UP);normals.append(Vector3.UP)
			if i<12:
				var n:=first+i*2;indices.append_array(PackedInt32Array([n,n+1,n+2,n+1,n+3,n+2]))
		for s in [-1,1]:
			var garden: Vector3=at+Vector3(s*3.7,0,.8);Art.place(self,"flower_cart",garden,Vector3.ONE*.9)
			Art.place(self,"tree",at+Vector3(s*4.0,0,-2.5),Vector3(.54,.66,.54))
			w.navigation.add_obstacle(Rect2(garden.x-.54,garden.z-.33,1.08,.66));w.navigation.add_obstacle(Rect2(at.x+s*4.0-.22,at.z-2.72,.44,.44))
		Art.place(self,"oak_bench",at+Vector3(2.9,0,3.5),Vector3.ONE*.9)
		w.navigation.add_obstacle(Rect2(at.x+2.22,at.z+3.1,1.36,.8))
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var road:=MeshInstance3D.new();road.mesh=mesh
	var stone:=ShaderMaterial.new();stone.shader=preload("res://scripts/ground.gdshader");stone.set_shader_parameter("cobbled",true);stone.set_shader_parameter("base_color",Color("#b3b3a1"));road.material_override=stone;add_child(road)

func _batch_static() -> void:
	var groups: Dictionary={}
	for item in find_children("*","MeshInstance3D",true,false):
		if item.mesh==null or item.skin!=null:continue
		var moving:=false;var ancestor: Node=item
		while ancestor!=self and ancestor!=null:
			if ancestor in wind_vanes or ancestor in fountains:moving=true;break
			ancestor=ancestor.get_parent()
		if moving:continue
		var key: String=str(item.mesh.get_instance_id())+":"+str(item.material_override.get_instance_id() if item.material_override!=null else 0)
		if not groups.has(key):groups[key]=[]
		groups[key].append(item)
	for items in groups.values():
		if items.size()<2:continue
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=items[0].mesh;batch.instance_count=items.size()
		var draw:=MultiMeshInstance3D.new();draw.multimesh=batch;draw.material_override=items[0].material_override;add_child(draw)
		for i in range(items.size()):batch.set_instance_transform(i,global_transform.affine_inverse()*items[i].global_transform);items[i].queue_free()

func _populate() -> void:
	var routes: Array=[
		[Vector3(-12,0,17),Vector3(-10,0,18),Vector3(-2,0,18),Vector3(-2,0,3)],
		[Vector3(2,0,15),Vector3(8,0,17),Vector3(10,0,14),Vector3(2,0,12)],
		[Vector3(-13,0,-4),Vector3(-12,0,-11),Vector3(-2,0,-11),Vector3(-2,0,-3)],
		[Vector3(12,0,-5),Vector3(12,0,-9),Vector3(5,0,-11),Vector3(2,0,-7)]]
	for i in range(routes.size()):
		var actor: MarketActor=preload("res://scripts/actor.gd").new()
		actor.setup("resident",[Color("#cc9f68"),Color("#9c7398"),Color("#7fa487"),Color("#d28a73")][i],"rabbit" if i%2==0 else "dog")
		actor.ground_sampler=Callable(w,"ground_height");add_child(actor);actor.position=w.navigation.nearest_free(routes[i][0]);actor.body_root.scale*=.84
		residents.append({"actor":actor,"route":routes[i],"index":1,"wait":float(i)})
