class_name PlayerState
extends FSMState

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(delta: float) -> void:
	pass

## Reads input, sets the facing direction and horizontal velocity. Returns true if there's input.
## Split out of control_moving() because Carry needs to follow input WITHOUT being pushed into Run.
func move_by_input(speed_scale: float = 1.0) -> bool:
	var input: Vector2 = Input.get_vector("left", "right", "up", "down")
	if input.length() <= 0.1:
		obj.stop_horizontal()
		return false
	obj.change_direction(BaseCharacter.direction_from_input(input))
	obj.velocity.x = obj.movement_speed * speed_scale * input.x
	obj.velocity.z = obj.movement_speed * speed_scale * input.y
	return true

#Control moving and changing state to run
#Return true if moving
func control_moving() -> bool:
	var is_moving := move_by_input()
	if is_moving and obj.is_on_floor():
		change_state(fsm.states.run)
	return is_moving

#Control jumping
#Return true if jumping
func control_jump() -> bool:
	if Input.is_action_just_pressed("jump"):
		obj.jump()
		change_state(fsm.states.jump)
		return true
	return false

#Control attack
#Return true if attacking
func control_attack() -> bool:
	if Input.is_action_just_pressed("attack"):
		change_state(fsm.states.attack)
		return true
	return false

#Control carry: picks up the nearest thing in front
#Return true if picking up
func control_carry() -> bool:
	if not Input.is_action_just_pressed("carry"):
		return false
	var target: BaseCharacter = obj.find_carryable()
	if target == null:
		return false
	obj.held = target
	change_state(fsm.states.carry)
	return true


func take_damage(damage: int = 1) -> void:
	obj.take_damage(damage)
	if obj.health <= 0:
		change_state(fsm.states.dead)
	else:
		change_state(fsm.states.hurt)
