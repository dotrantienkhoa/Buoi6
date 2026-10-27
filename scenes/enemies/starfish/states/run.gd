extends EnemyState

## Patrols like the mushroom, but the moment it sees the fox, it turns to face it and charges.

func _enter() -> void:
	obj.change_animation("run")
	obj.enable_check_player_in_sight()


func _update(_delta: float) -> void:
	var step: Vector3 = obj.forward() * obj.movement_speed
	obj.velocity.x = step.x
	obj.velocity.z = step.z

	if obj.found_player != null:
		# Pick the direction RIGHT NOW and lock it in. change_direction() takes effect at the end of
		# this frame, and Attack._enter() runs on the next frame — so it reads the new direction.
		obj.change_direction(BaseCharacter.direction_to(
			obj.global_position, obj.found_player.global_position))
		change_state(fsm.states.attack)
		return

	if obj.is_touch_wall() or (obj.is_on_floor() and obj.is_can_fall()):
		obj.turn_around()
