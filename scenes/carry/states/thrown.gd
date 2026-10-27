extends FSMState

## In flight — either thrown, or dropped (empty direction: falls straight down). Hitting the ground
## is an "impact": go to the Impact state if the object has one, otherwise return to the default
## state. That's the extension hook — to make an object shatter or explode on landing, just give it
## a state named Impact.
##
## Hitting a wall mid-flight kills horizontal momentum and it falls straight down — that does NOT
## count as an impact. If "shatter" gets added later, shattering right at the wall would mean
## shattering in mid-air.
##
## Hitting an enemy doesn't stop the flight: ThrowHitArea3D deals damage as it flies past.

## Horizontal flight speed, m/s.
@export var throw_speed: float = 10.0
## On flat ground, how far it flies before hitting the ground, m.
@export var throw_range: float = 6.0

## Still ends if it flies too long (knocked off the island), so this state never hangs forever.
const MAX_FLIGHT_TIME := 3.0

const HIT_SHAPE := "Direction/ThrowHitArea3D/CollisionShape3D"

var _dir: Vector3 = Vector3.ZERO
var _launch_height: float = 0.0
var _flight_time: float = 0.0
var _frames_in_air: int = 0


## BaseCharacter.be_thrown() calls this function BEFORE switching state: _enter() needs the
## direction and launch height, but change_state() lags by one frame. dir = Vector3.ZERO means
## DROPPED: no launch, just falling.
func prepare(dir: Vector3, launch_height: float) -> void:
	_dir = Vector3(dir.x, 0.0, dir.z).normalized()
	_launch_height = launch_height


func _enter() -> void:
	_flight_time = 0.0
	_frames_in_air = 0
	obj.velocity = Vector3.ZERO
	if _dir != Vector3.ZERO:
		# Choose the vertical velocity so that, on flat ground, the object lands exactly at
		# throw_range:
		#   t  = throw_range / throw_speed
		#   0  = h + vy·t − g·t²/2      ⇒      vy = g·t/2 − h/t
		var t := throw_range / maxf(throw_speed, 0.001)
		obj.velocity = _dir * throw_speed
		obj.velocity.y = obj.gravity * t * 0.5 - _launch_height / t
	_set_hit_enabled(true)


func _exit() -> void:
	_set_hit_enabled(false)


func _update(delta: float) -> void:
	_flight_time += delta
	_frames_in_air += 1
	# Skip the FIRST frame: _update() runs BEFORE move_and_slide(), and the most recent
	# move_and_slide() call was while the object still sat on the ground before being picked up.
	# is_on_floor() at this point is a STALE reading that still says "standing on ground" —
	# without the skip, the object would "hit the ground" the instant it leaves the hand.
	if _frames_in_air <= 1:
		return
	if obj.is_on_floor() or _flight_time >= MAX_FLIGHT_TIME:
		_impact()
		return
	if obj.is_on_wall():
		obj.stop_horizontal()


func _impact() -> void:
	obj.stop_horizontal()
	obj.restore_after_carry()
	change_state(fsm.states.get("impact", fsm.default_state))


## Doesn't take damage while in flight — same reason as Carried.
func take_damage(_damage_dir: Vector3, _damage: float) -> void:
	pass


## The area that deals damage while in flight. Not required — if a key gets thrown later, it doesn't
## need to hurt anyone.
func _set_hit_enabled(enabled: bool) -> void:
	if obj.has_node(HIT_SHAPE):
		obj.get_node(HIT_SHAPE).set_deferred("disabled", not enabled)
