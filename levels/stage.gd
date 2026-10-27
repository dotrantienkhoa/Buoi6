class_name Stage
extends Node3D

## The root node of every level. In _ready() it hands itself to GameManager, which decides where
## the fox appears. Keep the node NAMED "Stage": Node3DFactory finds the level's containers through
## find_parent("Stage").

@onready var player: Player = $Player
@onready var camera_rig: CameraRig = $CameraRig


func _ready() -> void:
	GameManager.register_stage(self)


## Moves the fox to the spawn point `spawn_name`. Every door and checkpoint joins the
## "spawn_points" group, has an `id`, and has a Marker3D child named Spawn. Returns false (and
## warns) if this stage has no such point.
func place_player_at(spawn_name: String) -> bool:
	for point: Node in get_tree().get_nodes_in_group("spawn_points"):
		if is_ancestor_of(point) and point.id == spawn_name:
			player.global_position = point.get_node("Spawn").global_position
			player.velocity = Vector3.ZERO
			camera_rig.snap_to_target()
			return true
	push_warning("%s has no spawn point '%s'" % [scene_file_path, spawn_name])
	return false
