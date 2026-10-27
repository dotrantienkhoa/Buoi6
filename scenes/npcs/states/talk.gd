extends FSMState

## Stands still, facing the fox, while a conversation runs. Conversation sends the mushroom back to
## Idle when it ends.

func _enter() -> void:
	obj.stop_horizontal()
	obj.change_animation("idle")


func _update(_delta: float) -> void:
	obj.stop_horizontal()
