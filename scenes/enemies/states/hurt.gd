extends EnemyState

## Stunned for 0.2 s. Only decides live-or-die once the timer runs out — that way the hit frame
## has time to show, instead of the enemy disappearing the instant it's hit.

func _enter() -> void:
	obj.change_animation("hurt")
	timer = 0.2


## The knockback ends when the stun ends. Without this line, the push from
## EnemyState.take_damage() would stay in velocity forever, and any enemy whose default state does
## NOT overwrite velocity every frame would keep sliding — a stationary barrel would slide a dozen
## meters. The crab and mushroom hide this bug because Run._update() resets velocity on the very
## next frame.
func _exit() -> void:
	obj.stop_horizontal()


func _update(delta: float) -> void:
	if update_timer(delta):
		if obj.health <= 0:
			change_state(fsm.states.dead)
		else:
			change_state(fsm.default_state)


## Doesn't take more damage while stunned: holding down the attack key would keep resetting the
## enemy's timer every frame and trap it in Hurt forever.
func take_damage(_damage_dir: Vector3, _damage: float) -> void:
	pass
