extends PlayerState

func _enter() -> void:
	obj.change_animation("run")

func _update(delta: float):
	if control_attack():
		return
	if control_carry():
		return
	if control_jump():
		return
	if not control_moving():
		change_state(fsm.states.idle)
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
