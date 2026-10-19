extends RefCounted

# One flat navigation map serves tap movement, helpers and shoppers.
# Geometry is registered by the world, so the visuals and routes stay in sync.
const CELL_SIZE := 0.5
const LIMIT := 34.0
const AGENT_RADIUS := .25
var grid := AStarGrid2D.new()
var obstacles: Array[Rect2] = []
var revision := 0
var grid_ready := false
var land_center := Vector2.ZERO
var land_radius := Vector2.ZERO
var bridges: Array[Rect2] = []

func remove_obstacle(bounds: Rect2) -> void:
	var index:=obstacles.find(bounds)
	if index<0:return
	obstacles.remove_at(index)
	if not grid_ready:return
	revision+=1
	# Only revisit the released footprint; moving a house must not stall the
	# whole town by rebuilding every cell in the 137 by 137 navigation map.
	for cx in range(floori((bounds.position.x-.28)/CELL_SIZE),ceili((bounds.end.x+.28)/CELL_SIZE)+1):
		for cz in range(floori((bounds.position.y-.28)/CELL_SIZE),ceili((bounds.end.y+.28)/CELL_SIZE)+1):
			var id:=Vector2i(cx,cz)
			if grid.is_in_boundsv(id):grid.set_point_solid(id,not is_walkable(Vector3(cx*CELL_SIZE,0,cz*CELL_SIZE),.26))

func add_obstacle(bounds: Rect2) -> void:
	obstacles.append(bounds)
	if not grid_ready:return
	revision+=1
	# Dynamic construction updates only occupied and adjacent cells.
	# Rebuilding the entire 137x137 map for a small new building made
	# late-game construction visibly stall on mobile hardware.
	var from_x:=floori((bounds.position.x-.28)/CELL_SIZE)
	var to_x:=ceili((bounds.end.x+.28)/CELL_SIZE)
	var from_z:=floori((bounds.position.y-.28)/CELL_SIZE)
	var to_z:=ceili((bounds.end.y+.28)/CELL_SIZE)
	for cx in range(from_x,to_x+1):
		for cz in range(from_z,to_z+1):
			var id:=Vector2i(cx,cz)
			if grid.is_in_boundsv(id):
				grid.set_point_solid(id,not is_walkable(Vector3(cx*CELL_SIZE,0,cz*CELL_SIZE),.26))

func build() -> void:
	revision += 1
	grid.region = Rect2i(-68, -68, 137, 137)
	grid.cell_size = Vector2.ONE * CELL_SIZE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for x in range(-68, 69):
		for z in range(-68, 69):
			var at := Vector3(x * CELL_SIZE, 0, z * CELL_SIZE)
			grid.set_point_solid(Vector2i(x, z), not is_walkable(at, 0.26))
	grid_ready=true

func is_walkable(at: Vector3, margin: float = 0.0) -> bool:
	if absf(at.x) > LIMIT or absf(at.z) > LIMIT:
		return false
	if land_radius.x>0.0:
		var point:=Vector2(at.x,at.z)
		var normalized: Vector2=(point-land_center)/(land_radius-Vector2.ONE*margin)
		var on_land: bool=normalized.length_squared()<=1.0
		for bridge in bridges:
			if bridge.grow(-margin).has_point(point):on_land=true
		if not on_land:return false
	for bounds in obstacles:
		if bounds.grow(margin).has_point(Vector2(at.x, at.z)):
			return false
	return true

func nearest_free(at: Vector3) -> Vector3:
	var clamped := Vector3(clampf(at.x, -LIMIT, LIMIT), 0, clampf(at.z, -LIMIT, LIMIT))
	if is_walkable(clamped,AGENT_RADIUS):
		return clamped
	var best := Vector3.ZERO
	var distance := INF
	for x in range(-68, 69):
		for z in range(-68, 69):
			var cell := Vector2i(x, z)
			if grid.is_point_solid(cell):
				continue
			var point := Vector3(x * CELL_SIZE, 0, z * CELL_SIZE)
			var candidate := point.distance_squared_to(clamped)
			if candidate < distance:
				distance = candidate
				best = point
	return best

func segment_clear(start: Vector3, end: Vector3) -> bool:
	var samples := maxi(1, int(ceil(start.distance_to(end) / 0.12)))
	for i in range(1, samples + 1):
		if not is_walkable(start.lerp(end, float(i) / samples),AGENT_RADIUS):
			return false
	return true

func _cell(at: Vector3) -> Vector2i:
	var center := Vector2i(roundi(at.x / CELL_SIZE), roundi(at.z / CELL_SIZE))
	var best := center
	var distance := INF
	# Nearby cells avoid snapping a free position onto an obstacle at a grid edge.
	for x in range(center.x - 2, center.x + 3):
		for z in range(center.y - 2, center.y + 3):
			var candidate := Vector2i(x, z)
			if not grid.is_in_boundsv(candidate) or grid.is_point_solid(candidate):
				continue
			var point := Vector3(x * CELL_SIZE, 0, z * CELL_SIZE)
			if at.distance_squared_to(point) < distance and segment_clear(at, point):
				best = candidate
				distance = at.distance_squared_to(point)
	return best

func find_path(start: Vector3, destination: Vector3) -> PackedVector3Array:
	var goal := nearest_free(destination)
	var route := PackedVector3Array()
	if segment_clear(start, goal):
		route.append(goal)
		return route
	var points := grid.get_point_path(_cell(start), _cell(goal))
	if points.is_empty():
		return route
	# Smooth only across verified clear segments; never cut a booth corner.
	var anchor := start
	var index := 0
	while index < points.size():
		var farthest := index
		for next in range(index + 1, points.size()):
			var point := Vector3(points[next].x, 0, points[next].y)
			if not segment_clear(anchor, point):
				break
			farthest = next
		var waypoint := Vector3(points[farthest].x, 0, points[farthest].y)
		route.append(waypoint)
		anchor = waypoint
		index = farthest + 1
	if anchor.distance_to(goal) > 0.01 and segment_clear(anchor, goal):
		route.append(goal)
	return route

func slide(start: Vector3, motion: Vector3) -> Vector3:
	var position := start if is_walkable(start,AGENT_RADIUS) else nearest_free(start)
	var steps := maxi(1, int(ceil(motion.length() / 0.12)))
	var step := motion / steps
	for i in range(steps):
		var next := position + step
		next.x = clampf(next.x, -LIMIT, LIMIT)
		next.z = clampf(next.z, -LIMIT, LIMIT)
		if is_walkable(next,AGENT_RADIUS):
			position = next
		else:
			var along_x := Vector3(next.x, 0, position.z)
			if is_walkable(along_x,AGENT_RADIUS):
				position = along_x
			var along_z := Vector3(position.x, 0, next.z)
			if is_walkable(along_z,AGENT_RADIUS):
				position = along_z
	return position
