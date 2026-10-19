extends RefCounted
class_name WivoriArt

static var packed := {}
static var optimized := {}

static func _missing_model(parent: Node3D, asset: String, at: Vector3, size_: Vector3) -> Node3D:
	# Leave an actionable engine error, not a fatal null.instantiate(). A
	# missing authored model is never replaced with a generic fake building.
	var replacement:=Node3D.new()
	replacement.name="ERROR · Falta modelo 3D "+asset
	replacement.position=at
	replacement.scale=size_
	parent.add_child(replacement)
	return replacement

static func place(parent: Node3D, asset: String, at: Vector3=Vector3.ZERO, size_: Vector3=Vector3.ONE) -> Node3D:
	var path:String="res://assets/models/"+asset+".glb"
	if not packed.has(asset):
		if not ResourceLoader.exists(path):
			push_error("Wivori Trails: falta el modelo importado "+path)
			return _missing_model(parent,asset,at,size_)
		var resource:Resource=load(path)
		if not resource is PackedScene:
			push_error("Wivori Trails: el modelo 3D no es una escena válida: "+path)
			return _missing_model(parent,asset,at,size_)
		packed[asset]=resource
	var node:Node3D=packed[asset].instantiate() as Node3D
	if node==null:
		push_error("Wivori Trails: escena 3D sin raíz Node3D: "+path)
		return _missing_model(parent,asset,at,size_)
	optimize(node)
	node.position=at
	node.scale=size_
	parent.add_child(node)
	return node

static func optimize(root: Node) -> void:
	for item in root.find_children("*","MeshInstance3D",true,false):
		if item.skin!=null or item.mesh==null or item.mesh.get_surface_count()<=3:continue
		var source: Mesh=item.mesh
		var key:=source.get_instance_id()
		if optimized.has(key):item.mesh=optimized[key];continue
		var safe:=true
		for surface in range(source.get_surface_count()):
			var material: Material=source.surface_get_material(surface)
			if not material is StandardMaterial3D or material.albedo_texture!=null or source.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:safe=false;break
		if not safe:optimized[key]=source;continue
		# Original solid PBR colors become vertex colors. Matte, glossy and metallic
		# finishes retain separate surfaces; authored geometry and normals stay intact.
		var tools: Dictionary={}
		for surface in range(source.get_surface_count()):
			var material: StandardMaterial3D=source.surface_get_material(surface)
			var group:=2 if material.metallic>.15 else 1 if material.roughness<.4 else 0
			if not tools.has(group):
				var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
				var finish:=StandardMaterial3D.new();finish.vertex_color_use_as_albedo=true;finish.vertex_color_is_srgb=true
				finish.roughness=[.88,.27,.38][group];finish.metallic=.32 if group==2 else 0.0
				builder.set_material(finish);tools[group]=builder
			var arrays: Array=source.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var colors: PackedColorArray=arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR]!=null else PackedColorArray()
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			var tint:=material.albedo_color.srgb_to_linear()
			var builder: SurfaceTool=tools[group]
			for i in range(indices.size() if not indices.is_empty() else vertices.size()):
				var vertex: int=indices[i] if not indices.is_empty() else i
				builder.set_normal(normals[vertex] if normals.size()>vertex else Vector3.UP)
				builder.set_color(((colors[vertex] if colors.size()>vertex else Color.WHITE)*tint).linear_to_srgb())
				builder.add_vertex(vertices[vertex])
		var mesh:=ArrayMesh.new()
		for builder in tools.values():builder.index();builder.commit(mesh)
		optimized[key]=mesh;item.mesh=mesh
