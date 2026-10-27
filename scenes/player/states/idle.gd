extends PlayerState

func _enter() -> void:
	obj.change_animation("idle")

func _update(_delta: float) -> void:
	#Control attack
	if control_attack():
		return
	#Control carry
	if control_carry():
		return
	#Control jump
	control_jump()
	#Control moving
	control_moving()
	#If not on floor change to fall
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
