extends RefCounted
const Ground=preload("res://scripts/ground.gdshader")
const Water=preload("res://scripts/water.gdshader")
static var shadow_material: ShaderMaterial
static var grass_mesh: ArrayMesh
static func ground(node: MeshInstance3D,color: Color,cobbled: bool=false) -> void:
	var material:=ShaderMaterial.new();material.shader=Ground;material.set_shader_parameter("base_color",color);material.set_shader_parameter("cobbled",cobbled);node.material_override=material
static func water(node: MeshInstance3D,island: bool=false) -> void:
	var material:=ShaderMaterial.new();material.shader=Water;material.set_shader_parameter("island",island);node.material_override=material
static func contact(parent: Node3D) -> MeshInstance3D:
	if shadow_material==null:shadow_material=ShaderMaterial.new();shadow_material.shader=preload("res://scripts/contact_shadow.gdshader")
	var disk:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(1.30,.90);disk.mesh=plane;disk.material_override=shadow_material;disk.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(disk);return disk
static func meadow(parent: Node3D,points: PackedVector3Array) -> void:
	if grass_mesh==null:
		var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(3):
			var angle:=float(i)*TAU/3.0
			for v in [Vector3(-.10,0,0),Vector3(.10,0,0),Vector3(.045,.26+float(i)*.05,.04)]:
				builder.set_normal(Vector3.UP);builder.add_vertex(v.rotated(Vector3.UP,angle))
		grass_mesh=builder.commit();var material:=ShaderMaterial.new();material.shader=preload("res://scripts/meadow.gdshader");grass_mesh.surface_set_material(0,material)
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.mesh=grass_mesh;batch.instance_count=points.size()
	for i in range(points.size()):
		batch.set_instance_transform(i,Transform3D(Basis(Vector3.UP,float(i)*2.4).scaled(Vector3.ONE*(.8+float(i%4)*.13)),points[i]))
		batch.set_instance_color(i,[Color("#779c59"),Color("#a7bd72"),Color("#6f975d")][i%3])
	var node:=MultiMeshInstance3D.new();node.multimesh=batch;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node)
