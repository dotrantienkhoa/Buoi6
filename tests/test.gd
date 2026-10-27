extends Node3D

## The test yard isn't a real stage: it never registers with GameManager, so a saved game can't
## pull the fox out of it. When the fox dies here, the yard simply starts over.


func _ready() -> void:
	# Deferred: the fox dies in the middle of a physics step, and swapping the scene right then
	# would pull nodes out of the tree while the engine is still stepping them.
	$Player.died.connect(get_tree().reload_current_scene, CONNECT_DEFERRED)
