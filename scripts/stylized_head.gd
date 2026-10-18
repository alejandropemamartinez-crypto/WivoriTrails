extends RefCounted

# Sculpted, reusable low-poly head with one continuous surface and integrated
# muzzle silhouette. Faces are SHADER-painted: no floating eyes/nose/teeth.
const LATITUDES := 20
const LONGITUDES := 36
static var _cache: Dictionary = {}

static func _point(species: String, y: float, angle: float) -> Vector3:
	var section: float = sqrt(maxf(0.00001, 1.0 - pow(y / 0.501, 2.0)))
	var x: float = cos(angle) * (0.49 * section)
	var z: float = sin(angle) * (0.45 * section)
	var muzzle_strength: float = 0.0
	match species:
		"dog": muzzle_strength = 0.23
		"fox": muzzle_strength = 0.19
		"pig": muzzle_strength = 0.14
		"raccoon": muzzle_strength = 0.12
		"cat": muzzle_strength = 0.13
		"rabbit": muzzle_strength = 0.11
	if muzzle_strength > 0.0:
		var height_weight: float = exp(-pow((y + 0.18) / 0.17, 2.0))
		var face_weight: float = pow(maxf(sin(angle), 0.0), 6.0)
		z += muzzle_strength * height_weight * face_weight
	# Slightly wider cheeks and a softer crown; a recognisable silhouette.
	x *= 1.0 + 0.06 * exp(-pow((y + 0.12) / 0.22, 2.0))
	return Vector3(x, y, z)

static func _normal(species: String, y: float, angle: float) -> Vector3:
	var dx: Vector3 = _point(species, y, angle + 0.002) - _point(species, y, angle - 0.002)
	var dy: Vector3 = _point(species, clampf(y + 0.002, -0.499, 0.499), angle) - _point(species, clampf(y - 0.002, -0.499, 0.499), angle)
	return dy.cross(dx).normalized()

static func _vertex(surface: SurfaceTool, species: String, y: float, angle: float) -> void:
	var vertex: Vector3 = _point(species, y, angle)
	surface.set_normal(_normal(species, y, angle))
	surface.set_uv(Vector2(angle / TAU, (y + 0.5)))
	surface.add_vertex(vertex)

static func build(species: String) -> ArrayMesh:
	if _cache.has(species):
		return _cache[species]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(LATITUDES - 1):
		var y0: float = lerpf(-0.499, 0.499, float(row) / float(LATITUDES - 1))
		var y1: float = lerpf(-0.499, 0.499, float(row + 1) / float(LATITUDES - 1))
		for column in range(LONGITUDES):
			var a0: float = TAU * float(column) / float(LONGITUDES)
			var a1: float = TAU * float(column + 1) / float(LONGITUDES)
			# Consistent outward winding, shared smooth normals.
			_vertex(surface, species, y0, a0)
			_vertex(surface, species, y0, a1)
			_vertex(surface, species, y1, a0)
			_vertex(surface, species, y0, a1)
			_vertex(surface, species, y1, a1)
			_vertex(surface, species, y1, a0)
	var mesh: ArrayMesh = surface.commit()
	_cache[species] = mesh
	return mesh
