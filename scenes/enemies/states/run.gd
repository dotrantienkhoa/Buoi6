extends EnemyState

## Patrol: walks straight ahead, turns around on hitting a wall or reaching a floor edge.
## Shared by the mushroom, the crab, and the starfish.

func _enter() -> void:
	obj.change_animation("run")


func _update(_delta: float) -> void:
	# ONLY set the horizontal components. Writing `obj.velocity = obj.forward() * speed` would
	# wipe out velocity.y, and the enemy would float instead of falling — the most common trap when
	# porting from 2D to 3D.
	var step: Vector3 = obj.forward() * obj.movement_speed
	obj.velocity.x = step.x
	obj.velocity.z = step.z

	if _should_turn_around():
		obj.turn_around()


func _should_turn_around() -> bool:
	if obj.is_touch_wall():
		return true
	# Only check the floor edge while STANDING on the floor: while falling, the down ray obviously
	# won't hit anything, and turning around then would mean spinning continuously in mid-air.
	if obj.is_on_floor() and obj.is_can_fall():
		return true
	return false
