extends PlayerState

## Stands still while a conversation runs — no moving, jumping, attacking or carrying: the keys
## belong to the dialogue. Conversation sends the fox back to Idle when it ends. Getting hit still
## works as everywhere else (PlayerState.take_damage).

func _enter() -> void:
	obj.stop_horizontal()
	obj.change_animation("idle")


func _update(_delta: float) -> void:
	obj.stop_horizontal()
