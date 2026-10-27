extends RigidBody3D

## A bullet that flies horizontally. Destroys itself on hitting someone, hitting terrain, or running
## out of lifetime.

## Maximum lifetime in seconds if it hits nothing. Without it, a missed bullet would fly forever
## and the node count in the level would only ever grow.
@export var lifetime: float = 4.0


func _ready() -> void:
	$HitArea3D.hitted.connect(_on_hitted)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _on_hitted(_area: Area3D) -> void:
	queue_free()


func _on_body_entered(_body: Node) -> void:
	queue_free()
