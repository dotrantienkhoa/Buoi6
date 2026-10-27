extends EnemyState

## Lies dead for 1 second then disappears.

func _enter() -> void:
	obj.change_animation("dead")
	obj.stop_move()
	# Disable all collision: a dead body shouldn't block the way, shouldn't hit anyone, and
	# shouldn't take more damage. Use set_deferred instead of assigning directly — changing a
	# collision shape while the engine is mid-collision-pass triggers the "Can't change this state
	# while flushing queries" error.
	_disable("CollisionShape3D")
	_disable("Direction/HitArea3D/CollisionShape3D")
	_disable("Direction/HurtArea3D/CollisionShape3D")
	timer = 1.0


func _update(delta: float) -> void:
	if update_timer(delta):
		obj.queue_free()


func take_damage(_damage_dir: Vector3, _damage: float) -> void:
	pass


func _disable(path: String) -> void:
	if obj.has_node(path):
		obj.get_node(path).set_deferred("disabled", true)
