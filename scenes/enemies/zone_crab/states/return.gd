extends EnemyState

## Walks back to a random point of the zone, paying no attention to the fox on the way. Wander
## once there — or at once when the target has no path, or when the timer runs out on a walk that
## something blocks or that is just that long (grid paths are staircase-shaped; from the far side
## of the box it is ~16 m): Wander sends it straight back here if it is still too far.

func _enter() -> void:
	obj.returning = true
	obj.agent.target_position = obj.random_zone_point()
	obj.change_animation("run")
	timer = obj.walk_timeout


func _update(delta: float) -> void:
	timer -= delta
	if obj.agent.is_navigation_finished() or timer <= 0.0:
		obj.returning = false
		change_state(fsm.states.wander)
		return
	obj.steer_along_path(obj.movement_speed)
