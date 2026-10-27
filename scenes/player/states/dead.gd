extends PlayerState

func _enter() -> void:
	obj.change_animation("dead")
	obj.stop_move()
	timer = 2.0


func _update(delta: float) -> void:
	if update_timer(delta):
		obj.died.emit()


## Already dead, so no more damage — without this function the trap would still push the fox into
## Hurt and it would come back to life.
func take_damage(_damage: int = 1) -> void:
	pass
