extends PlayerState

## Swings the sword: enables the hit area for exactly the animation's duration, then disables it.

func _enter() -> void:
	obj.change_animation("attack")
	obj.stop_horizontal()
	# Reads the duration DIRECTLY from the animation instead of hardcoding a number — changing the
	# frame duration in the sheet automatically changes the attack duration along with it.
	#
	# Uses "attack_%s" % obj.direction instead of obj.get_animation_name(): that function reads
	# current_animation, but the change_animation() call above only sets _next_animation — it
	# doesn't take effect until the next frame.
	timer = obj.anim_player.get_animation("attack_%s" % obj.direction).length
	_hit_shape().disabled = false


func _exit() -> void:
	_hit_shape().disabled = true


func _update(delta: float) -> void:
	if update_timer(delta):
		change_state(fsm.previous_state)


func _hit_shape() -> CollisionShape3D:
	return obj.get_node("Direction/HitArea3D/CollisionShape3D")
