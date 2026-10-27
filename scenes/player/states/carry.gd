extends PlayerState

## Currently carrying something overhead.

## Time to lift the object from the ground into hand, in seconds.
const LIFT_TIME := 0.18
## Moves slower while carrying.
const CARRY_SPEED_SCALE := 0.6

var _lift: Tween = null


func _enter() -> void:
	obj.change_animation("carry_idle")
	obj.stop_horizontal()
	obj.held.be_picked_up(obj.hold_point)
	# be_picked_up() keeps the global position unchanged: at this point the object still sits on the
	# ground, just now a child of HoldPoint. position is the coordinate RELATIVE to HoldPoint, so
	# tweening it to 0 is exactly lifting the object from the ground into hand. Runs on the physics
	# tick to stay in step with every other movement.
	_lift = obj.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_lift.tween_property(obj.held, "position", Vector3.ZERO, LIFT_TIME)


func _exit() -> void:
	# Gets hit while still lifting: if the tween keeps running, it keeps pulling the object's
	# position toward 0 — but by then the object is back under the Enemies node, and (0, 0, 0)
	# under Enemies is the level's origin.
	if _lift != null:
		_lift.kill()
		_lift = null
	# Leaving Carry while the hand is still full (got hit, died...) drops the object right where it
	# is.
	if is_instance_valid(obj.held):
		obj.held.be_dropped(obj.held.global_position)
	obj.held = null


func _update(_delta: float) -> void:
	# Stands still and ignores input while lifting
	if _lift != null and _lift.is_running():
		return
	if Input.is_action_just_pressed("carry"):
		# Release the object from hand RIGHT HERE, before switching state: by the time _exit() runs
		# the hand is already empty, so _exit() won't drop it again.
		obj.held.be_thrown(obj.forward(), obj.held.global_position, obj.global_position.y)
		obj.held = null
		change_state(fsm.states.throw)
		return
	if move_by_input(CARRY_SPEED_SCALE):
		obj.change_animation("carry")
	else:
		obj.change_animation("carry_idle")
