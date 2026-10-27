extends EnemyState

## Rests 1–2 s, walks to a random point of the zone along the A* grid, rests again. A target with
## no path ends the walk at once and the crab stays put; a walk that hasn't arrived when the timer
## runs out (something blocks the way, or the walk is just that long) ends right there.
##
## Hurt goes back to the FSM's default state, which is this one, so this is where the crab decides
## again first: too far, or still on its way back → Return; the fox in sight → Chase. A crab hit
## mid-chase is back in Chase one frame after the stun.

## Resting or walking.
var _resting := true


func _enter() -> void:
	_rest()


## The crab has no idle animation: resting freezes the run animation. Unfreeze it on the way out,
## or Hurt and Dead would be frozen too.
func _exit() -> void:
	obj.anim_player.speed_scale = 1.0


func _update(delta: float) -> void:
	# Knocked out of the leash, or back from a stun mid-chase or mid-return: decide again first.
	if obj.is_out_of_leash() or obj.returning:
		change_state(fsm.states.return)
		return
	if obj.visible_fox() != null:
		change_state(fsm.states.chase)
		return
	timer -= delta
	if _resting:
		obj.stop_horizontal()
		# No zone, no walk: a crab placed by hand stays where it was put.
		if timer <= 0.0 and obj.has_zone():
			_walk()
		return
	if obj.agent.is_navigation_finished() or timer <= 0.0:
		_rest()
		return
	obj.steer_along_path(obj.movement_speed)


func _rest() -> void:
	_resting = true
	obj.stop_horizontal()
	obj.change_animation("run")
	obj.anim_player.speed_scale = 0.0
	timer = randf_range(obj.rest_time.x, obj.rest_time.y)


func _walk() -> void:
	_resting = false
	obj.agent.target_position = obj.random_zone_point()
	obj.anim_player.speed_scale = 1.0
	timer = obj.walk_timeout
