extends FSMState

## Walks to a random point near home along the A* grid, then rests again. A target with no path
## ends the walk at once (navigation finished) and the mushroom stays put; the timer ends a walk
## that something blocks, such as another body in the way, or that is just longer than the timeout
## (grid paths are staircase-shaped).

func _enter() -> void:
	obj.agent.target_position = obj.random_home_point()
	obj.change_animation("walk")
	timer = obj.walk_timeout


func _update(delta: float) -> void:
	timer -= delta
	if obj.agent.is_navigation_finished() or timer <= 0.0:
		change_state(fsm.states.idle)
		return
	obj.steer_along_path()
