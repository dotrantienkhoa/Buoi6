extends PlayerState

## Stunned for half a second: knocked back, uncontrollable, and invulnerable so one hit doesn't
## drain health every single frame in a row.

const KNOCKBACK_SPEED := 8.0
const HOP_SPEED := 5.0


func _enter() -> void:
	obj.change_animation("hurt")
	obj.is_invulnerable = true
	# Knocked back OPPOSITE the facing direction, in the XZ plane. The Y axis handles the hop
	# separately — in 3D the Y axis points up, so the hop is a POSITIVE number, the exact opposite
	# of the 2D version.
	var push: Vector3 = -obj.forward() * KNOCKBACK_SPEED
	obj.velocity.x = push.x
	obj.velocity.z = push.z
	obj.velocity.y = HOP_SPEED
	timer = 0.5


func _exit() -> void:
	obj.is_invulnerable = false


func _update(delta: float) -> void:
	# Deliberately does NOT call control_moving()/control_jump(): can't be controlled while stunned.
	if update_timer(delta):
		# Hit in the middle of a conversation: back to Talk, not Idle — the dialogue is still open.
		if obj.is_talking:
			change_state(fsm.states.talk)
		else:
			change_state(fsm.states.idle)
