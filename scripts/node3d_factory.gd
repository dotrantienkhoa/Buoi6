extends Marker3D
class_name Node3DFactory

## Factory that spawns an object into a container node of the level.
##
## Why not add_child straight onto the shooter: a child node inherits its parent's transform, so
## the bullet would follow the barrel instead of flying straight — and die with the barrel when the
## barrel calls queue_free(). Spawning into a separate container node of the Stage keeps the bullet
## living independently.

signal created(product: Node3D)

## The scene of the thing to spawn. Drag a .tscn file into this field in the Inspector.
@export var product_packed_scene: PackedScene
## Name of the CHILD node of Stage that will hold the product, e.g. "Bullets".
@export var target_container_name: StringName

func create(_product_packed_scene := product_packed_scene) -> Node3D:
	var stage := find_parent("Stage")
	if stage == null:
		push_error("%s is not under any node named 'Stage'" % name)
		return null
	# owned = false as the third argument: by default find_child only finds nodes SAVED in the
	# scene, so a container node created by code at runtime would never be found — a very
	# hard-to-guess bug.
	var container := stage.find_child(target_container_name, true, false)
	if container == null:
		push_error("No container node named '%s' found in Stage — add a Node3D with exactly that name"
			% target_container_name)
		return null

	var product: Node3D = _product_packed_scene.instantiate()
	container.add_child(product)
	# Set the position AFTER entering the tree. global_position on a node with no parent yet is
	# just its local transform; assigning it before add_child would make Godot keep that local
	# transform as-is, so the bullet would spawn offset by exactly the container node's position.
	product.global_position = global_position
	created.emit(product)
	return product
