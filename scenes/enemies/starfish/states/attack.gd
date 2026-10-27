extends EnemyState

## Winds up then rolls straight at the fox. The charge direction is LOCKED the instant it commits
## to the attack and never changes mid-charge — being dodgeable is what makes the fight fun.

## Multiplies movement_speed by this much while charging.
@export var charge_multiplier: float = 3.0
## How long it winds up before charging, in seconds.
@export var wind_up: float = 0.3
## Maximum charge duration before returning to Run, in seconds. wind_up + charge_time = 1.2 s,
## the length of the attack animation, so every attack plays the roll exactly once.
@export var charge_time: float = 0.9

var _charging: bool = false
var _charge_direction: Vector3 = Vector3.ZERO


func _enter() -> void:
	obj.change_animation("attack")
	obj.stop_horizontal()
	# Aim BEFORE disabling the sight area: once it's disabled, body_exited fires immediately and
	# found_player goes null.
	_charge_direction = _aim_at_player()
	# Disable the sight area while attacking: leaving it on would fire body_entered continuously
	# and reset the starfish back to the start of the attack every frame.
	obj.disable_check_player_in_sight()
	_charging = false
	timer = wind_up


func _exit() -> void:
	obj.enable_check_player_in_sight()


## The charge vector, in the XZ plane.
##
## This is the ACTUAL direction to the fox, not the facing direction. The two are deliberately
## different: `obj.direction` is snapped to one of four axes because the sheet only draws four
## directions, so it's only used to pick the animation. The charge path has no reason to snap to
## an axis — if the fox is standing at a diagonal, charging along an axis would just miss.
##
## If it loses track of the fox (the fox leaves range just as the state switches), it charges
## straight along the facing direction.
func _aim_at_player() -> Vector3:
	if obj.found_player == null or not is_instance_valid(obj.found_player):
		return obj.forward()
	var aim: Vector3 = obj.found_player.global_position - obj.global_position
	aim.y = 0.0
	if aim.length_squared() < 0.0001:
		return obj.forward()
	return aim.normalized()


func _update(delta: float) -> void:
	if not _charging:
		if update_timer(delta):
			_charging = true
			timer = charge_time
		return

	var step: Vector3 = _charge_direction * obj.movement_speed * charge_multiplier
	obj.velocity.x = step.x
	obj.velocity.z = step.z

	# Stop early on hitting a wall or reaching a floor edge, so it doesn't charge straight into the
	# sea.
	if obj.is_touch_wall() or (obj.is_on_floor() and obj.is_can_fall()):
		change_state(fsm.states.run)
		return
	if update_timer(delta):
		change_state(fsm.states.run)
