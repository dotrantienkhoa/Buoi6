class_name BaseCharacter
extends CharacterBody3D

## Three conventions in this lesson:
##  - The facing direction is a string, one of "down"/"up"/"left"/"right".
##  - Sprite3D sits OUTSIDE the Direction node. Topdown expresses facing by switching
##    animations (suffixed _down/_left/_right/_up), without touching the parent node at all.
##  - Animation is driven by AnimationPlayer, not AnimatedSprite3D. Both the frame and the
##    Sprite3D.flip_h flip flag are keyed inside the animation; this script never touches
##    the sprite, it only picks the animation name.

## The Y-axis rotation of the Direction node for each facing direction. A character's front is its
## local +Z (Vector3.MODEL_FRONT) and the topdown camera sits toward +Z, so yaw 0 faces "down"
## (toward the camera) and PI faces "up".
const DIRECTION_YAW: Dictionary = {
	"up": PI,
	"left": -PI / 2,
	"down": 0.0,
	"right": PI / 2,
}

## The opposite direction, used by turn_around().
const OPPOSITE_DIRECTION: Dictionary = {
	"up": "down",
	"down": "up",
	"left": "right",
	"right": "left",
}

@export var movement_speed: float = 2.5
@export var gravity: float = 24.0
@export var direction: String = "down"

@export var attack_damage: int = 1
@export var max_health: int = 3
var health: int = max_health

## Turn off to make the character stand absolutely still: no gravity, no move_and_slide(). Used
## while it's being carried — as a child of HoldPoint it already follows the carrier; leaving
## gravity on would make it slip out of hand, and leaving move_and_slide() on would let its own FSM
## just walk it away right out of the carrier's hand.
var movement_enabled: bool = true

var jump_speed: float = 12.0
var fsm: FSM = null
var current_animation = null

@onready var sprite: Sprite3D = $Sprite3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _next_animation = null
var _next_direction: String = "down"
var _played_direction: String = ""

func _ready() -> void:
	_next_direction = direction
	_apply_direction()

func _physics_process(delta: float) -> void:
	_check_changed_animation()

	if fsm != null:
		fsm._update(delta)
	_update_movement(delta)
	_check_changed_direction()


func _update_movement(delta: float) -> void:
	if not movement_enabled:
		return
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

# Pick the facing direction from the input vector: whichever axis is stronger wins
static func direction_from_input(input: Vector2) -> String:
	if absf(input.x) > absf(input.y):
		return "right" if input.x > 0.0 else "left"
	return "down" if input.y > 0.0 else "up"

func turn_around() -> void:
	if _next_direction != direction:
		return
	_next_direction = OPPOSITE_DIRECTION[direction]

func is_left() -> bool:
	return direction == "left"

func is_right() -> bool:
	return direction == "right"

func turn_left() -> void:
	_next_direction = "left"

func turn_right() -> void:
	_next_direction = "right"

func turn_up() -> void:
	_next_direction = "up"

func turn_down() -> void:
	_next_direction = "down"

func jump() -> void:
	velocity.y = jump_speed

func stop_move() -> void:
	velocity = Vector3.ZERO

# Stop horizontal movement, keep the falling velocity as-is
func stop_horizontal() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func change_animation(new_animation: String) -> void:
	_next_animation = new_animation

func change_direction(new_direction: String) -> void:
	_next_direction = new_direction

# The actual animation name to run on AnimationPlayer, e.g. "run" + "left" -> "run_left"
func get_animation_name() -> String:
	if current_animation == null:
		return ""
	return "%s_%s" % [current_animation, direction]

func _check_changed_animation() -> void:
	var need_play: bool = false
	if _next_animation != current_animation:
		current_animation = _next_animation
		need_play = true
	# Changing direction must also replay the animation, since each direction is its own animation
	if direction != _played_direction:
		_played_direction = direction
		need_play = true
	if need_play and anim_player != null and current_animation != null:
		anim_player.play(get_animation_name())

func _check_changed_direction() -> void:
	if _next_direction != direction:
		direction = _next_direction
		_on_changed_direction()
		_apply_direction()

# Rotate the Direction node to the facing direction. The sprite doesn't need flipping here: the
# _left animation already keys flip_h = true, and _check_changed_animation() replays the animation
# on direction change.
func _apply_direction() -> void:
	$Direction.rotation.y = DIRECTION_YAW[direction]

func _on_changed_direction() -> void:
	pass


func take_damage(damage: int) -> void:
	health -= damage

## The facing vector, in the XZ plane. A character's front is its local +Z (Vector3.MODEL_FRONT),
## so rotating MODEL_FRONT around the Y axis by exactly the Direction node's yaw gives the facing.
##
## The 2D version could just write `obj.direction * speed` because direction was an int ±1. Here
## direction is a STRING, so anywhere that needs "move forward" has to call this function instead.
func forward() -> Vector3:
	return Vector3.MODEL_FRONT.rotated(Vector3.UP, DIRECTION_YAW[direction])

## The facing direction toward a position: whichever XZ axis has the larger difference wins. Same
## convention as direction_from_input(): +X is "right", +Z is "down". The difference along Y is
## ignored — an enemy standing at the foot of a platform should still turn to face the fox, not tilt
## up to the sky.
static func direction_to(from: Vector3, to: Vector3) -> String:
	var delta := to - from
	if absf(delta.x) > absf(delta.z):
		return "right" if delta.x > 0.0 else "left"
	return "down" if delta.z > 0.0 else "up"

## Starts talking: turns toward `listener` (if any) and stands still in the "talk" state — only
## for characters that have one (the fox, the village mushroom). Conversation calls it on both
## sides.
func start_talk(listener: Node3D = null) -> void:
	if listener != null:
		change_direction(direction_to(global_position, listener.global_position))
	fsm.change_state(fsm.states.talk)

## Stops talking: back to Idle — but only a living character still in Talk. One that was killed
## meanwhile stays dead (a death not yet applied by the FSM shows as health 0); one in Hurt finishes
## it on its own.
func finish_talk() -> void:
	if health > 0 and fsm.current_state == fsm.states.talk:
		fsm.change_state(fsm.states.idle)

## Can be picked up when it has both the Carried and Thrown states, and isn't currently in either
## one (something already being carried or already in flight can't be picked up again). To make
## anything pickable, just add those two states to it — no flag, no group needed.
func can_be_carried() -> bool:
	if fsm == null or not fsm.states.has("carried") or not fsm.states.has("thrown"):
		return false
	return fsm.current_state != fsm.states.carried and fsm.current_state != fsm.states.thrown


# --- Pick up and throw ---------------------------------------------------------------------
# Only for things that have the Carried and Thrown states (see can_be_carried()). The functions
# below handle the NODE TREE and COLLISION; the Carried / Thrown states handle the per-frame
# physics.

## The areas that must be disabled while being carried and while in flight. Disables whichever of
## them exist.
const CARRY_DISABLED_SHAPES := [
	"Direction/HitArea3D/CollisionShape3D",
	"Direction/HurtArea3D/CollisionShape3D",
	"Direction/DetectPlayerArea3D/CollisionShape3D",
]

var _carry_home: Node = null
var _carry_layer: int = 0
## The enabled/disabled state of each area right before being picked up, so it can be restored
## EXACTLY as it was instead of carelessly re-enabling an area that was already off.
var _carry_saved_shapes: Dictionary = {}


## Gets picked up. Becomes a child of hold_point but stays exactly where it was (reparent keeps
## the global position by default) — the carrier will tween it into hand. collision_layer = 0 so
## it doesn't collide with the carrier's own body, and so no one else can pick it up a second time.
func be_picked_up(hold_point: Node3D) -> void:
	_carry_home = get_parent()
	_carry_layer = collision_layer
	collision_layer = 0
	_carry_saved_shapes.clear()
	for path: String in CARRY_DISABLED_SHAPES:
		if has_node(path):
			var shape: CollisionShape3D = get_node(path)
			_carry_saved_shapes[path] = shape.disabled
			shape.set_deferred("disabled", true)
	reparent(hold_point)
	fsm.change_state(fsm.states.carried)


## Gets thrown. Returns to its old place in the tree, is positioned at `from`, then flies along
## dir. The launch height is measured from the ground under the thrower's feet — Thrown needs it
## so the object lands at the right range.
func be_thrown(dir: Vector3, from: Vector3, ground_y: float) -> void:
	if _carry_home != null and is_instance_valid(_carry_home):
		reparent(_carry_home)
	global_position = from
	fsm.states.thrown.prepare(dir, from.y - ground_y)
	fsm.change_state(fsm.states.thrown)


## Gets dropped (the carrier got hit): throws with an EMPTY direction — no launch anywhere, it
## just falls straight down from `at`, and hitting the ground still counts as an impact, same as
## being thrown.
##
## Why this doesn't switch straight to the default state: the FSM's state change lags by one
## frame. If the carrier gets hit on the very frame it just picked something up, the object is
## still WAITING to enter Carried, and the current state is still the default state — switching to
## it right then gets skipped by the FSM ("switching to the state it's already in"), and on the
## next frame the object still enters Carried and hangs there forever. Thrown is always different
## from the current state, so it always wins.
func be_dropped(at: Vector3) -> void:
	be_thrown(Vector3.ZERO, at, at.y)


## Restores whatever be_picked_up() disabled. Thrown calls this on hitting the ground — being thrown
## or being dropped both end up there, so this is the ONE place that needs to know what
## be_picked_up() disabled.
func restore_after_carry() -> void:
	collision_layer = _carry_layer
	for path: String in _carry_saved_shapes:
		get_node(path).set_deferred("disabled", _carry_saved_shapes[path])
	_carry_saved_shapes.clear()
