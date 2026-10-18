extends RefCounted
class_name WivoriArt

static var packed := {}

static func place(parent: Node3D, asset: String, at: Vector3=Vector3.ZERO, size_: Vector3=Vector3.ONE) -> Node3D:
	if not packed.has(asset):packed[asset]=load("res://assets/models/"+asset+".glb")
	var node: Node3D=packed[asset].instantiate()
	node.position=at
	node.scale=size_
	parent.add_child(node)
	return node
