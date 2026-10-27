extends FSMState

## Being carried: sits still in the carrier's hands, no gravity, no collision.
## Putting it into / taking it out of hand is BaseCharacter.be_picked_up() / be_thrown() /
## be_dropped()'s job; this state only handles the physics while it sits in hand.

func _enter() -> void:
	obj.movement_enabled = false
	obj.velocity = Vector3.ZERO
	_body_shape().set_deferred("disabled", true)


func _exit() -> void:
	obj.movement_enabled = true
	_body_shape().set_deferred("disabled", false)


## Doesn't take damage while carried. This function is REQUIRED to exist: the base FSMState has no
## take_damage(), so without it EnemyCharacter._on_hurt_area_3d_hurt() would crash when it calls in.
func take_damage(_damage_dir: Vector3, _damage: float) -> void:
	pass


func _body_shape() -> CollisionShape3D:
	return obj.get_node("CollisionShape3D")
