extends Area3D

## A flat zone just under the sea: whatever falls in dies. The fox missing a platform ends up here.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.die()
		# Stop the fall right here: the camera follows the fox, and two seconds of falling (the
		# Dead state) would carry it down past the bottom of the sea into an empty void.
		body.movement_enabled = false
	elif body is BaseCharacter:
		body.queue_free()    # an enemy that falls into the sea
