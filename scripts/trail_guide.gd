extends Node3D

# A small reusable pool keeps route guidance cheap. Paths use the same obstacle
# map as movement, so the arrows never suggest walking through the market.
var g
var ring: MeshInstance3D
var pointer: Node3D
var arrows: Array[Node3D] = []
var refresh_in := 0.0
var clock := 0.0
var target := Vector3.ZERO
var active := false

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("#dfa437")
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array([Vector3(-.32,0,.17),Vector3(0,0,-.19),Vector3(.32,0,.17),Vector3(.32,0,.40),Vector3(0,0,.04),Vector3(-.32,0,.40)])
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,5,1,4,5,1,2,4,2,3,4])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	for i in range(14):
		var arrow := MeshInstance3D.new(); arrow.mesh=mesh; arrow.material_override=mat
		arrow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(arrow); arrows.append(arrow)
	ring=MeshInstance3D.new()
	var torus := TorusMesh.new(); torus.inner_radius=.82; torus.outer_radius=1.0; torus.rings=24; torus.ring_segments=8
	ring.mesh=torus; ring.material_override=mat; add_child(ring)
	pointer=Node3D.new(); add_child(pointer)
	var head := CylinderMesh.new(); head.top_radius=.43; head.bottom_radius=0; head.height=.65; head.radial_segments=3
	var head_node := MeshInstance3D.new(); head_node.mesh=head; head_node.material_override=mat
	head_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pointer.add_child(head_node)
	visible=false

func update_route(objective: Dictionary) -> void:
	active=objective.has("target") and not g.shop_panel.visible
	visible=active
	if not active:return
	target=objective["target"]
	var path: PackedVector3Array=g.world.navigation.find_path(g.player.position,target)
	for arrow in arrows:arrow.visible=false
	var previous: Vector3=g.player.position
	var travelled := 0.0
	var next_mark := 1.1
	var index := 0
	for point in path:
		var segment := point-previous
		var length := segment.length()
		while next_mark<=travelled+length and index<arrows.size():
			var heading := segment.normalized()
			var arrow: Node3D=arrows[index]
			arrow.position=previous+heading*(next_mark-travelled)+Vector3(0,.16,0)
			arrow.rotation.y=atan2(-heading.x,-heading.z)
			arrow.visible=true
			index+=1; next_mark+=1.25
		travelled+=length; previous=point
	ring.position=target+Vector3(0,.18,0)

func _process(delta: float) -> void:
	if not active:return
	clock+=delta
	var pulse := 1.0+sin(clock*4.5)*.09
	ring.scale=Vector3(pulse,1,pulse)
	pointer.position=target+Vector3(0,3.1+sin(clock*4)*.20,0)
	pointer.rotation.y=clock*.6
