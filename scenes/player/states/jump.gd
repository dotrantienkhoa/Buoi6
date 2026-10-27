extends PlayerState

func _enter() -> void:
	obj.change_animation("jump")

func _exit() -> void:
	pass

func _update(_delta: float):
	control_moving()
	# In 3D the Y axis points up, so falling means velocity.y is negative
	if obj.velocity.y < 0:
		change_state(fsm.states.fall)
