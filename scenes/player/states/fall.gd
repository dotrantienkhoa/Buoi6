extends PlayerState

func _enter() -> void:
	obj.change_animation("fall")

func _update(_delta: float) -> void:
	var is_moving: bool = control_moving()
	if obj.is_on_floor():
		if not is_moving and not control_jump():
			change_state(fsm.states.idle)
