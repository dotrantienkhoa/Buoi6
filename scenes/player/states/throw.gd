extends PlayerState

## The throw pose, standing still for a beat. Doesn't touch the object — it already left the hand in
## Carry._update().

## How long to hold the throw pose, in seconds.
const THROW_TIME := 0.25


func _enter() -> void:
	obj.change_animation("throw")
	obj.stop_horizontal()
	timer = THROW_TIME


func _update(delta: float) -> void:
	if update_timer(delta):
		change_state(fsm.states.idle)
