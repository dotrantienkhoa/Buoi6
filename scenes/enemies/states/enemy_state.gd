extends FSMState
class_name EnemyState

## The base state for every enemy. This is the ONE place that knows "what happens when hit", so
## each child state doesn't have to handle it — except Dead, which overrides it to skip entirely.

## Knockback force on getting hit, in m/s.
const KNOCKBACK_SPEED := 6.0

func take_damage(damage_dir: Vector3, damage: float) -> void:
	# Only set the HORIZONTAL components. Assigning the whole Vector3 would wipe out velocity.y,
	# and an enemy that's falling would freeze in mid-air.
	obj.velocity.x = damage_dir.x * KNOCKBACK_SPEED
	obj.velocity.z = damage_dir.z * KNOCKBACK_SPEED
	obj.take_damage(int(damage))
	change_state(fsm.states.hurt)
