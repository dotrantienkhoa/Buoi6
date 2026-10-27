extends EnemyState

## Runs after the fox, faster than it wanders, aiming again a few times a second. Its HitArea3D
## still hurts the fox on contact. Gives up when the chase has dragged it out of its leash
## (→ Return) or when the fox is gone from sight or dead (→ Wander).

## Seconds between two re-aims at the fox.
const RETARGET_TIME := 0.25


func _enter() -> void:
	obj.change_animation("run")
	timer = 0.0    # aim at the fox on the very first frame


func _update(delta: float) -> void:
	if obj.is_out_of_leash():
		change_state(fsm.states.return)
		return
	var fox: Player = obj.visible_fox()
	if fox == null:
		change_state(fsm.states.wander)
		return
	timer -= delta
	if timer <= 0.0:
		obj.agent.target_position = fox.global_position
		timer = RETARGET_TIME
	obj.steer_along_path(obj.chase_speed)
