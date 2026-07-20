extends Node3D

## Attach to any imported model (or a node containing one) to automatically
## generate exact collision matching its visual mesh, since imported scenes
## don't come with physics bodies on their own.
func _ready() -> void:
	_add_collision(self)

func _add_collision(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).create_trimesh_collision()
	for child in node.get_children():
		_add_collision(child)
