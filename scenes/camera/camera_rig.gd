class_name CameraRig
extends Node3D

## Camera that follows the character.
##
## The rig is the parent node, `Camera3D` is a child with a fixed offset. The rig moves with the
## character while the camera keeps a fixed angle, so the frame never rotates or tilts with the
## character.
##
## Why the camera is no longer a child of Player: as a child, the camera would copy **1:1** every
## movement, including jumps — the whole world would bob with each jump. A rig that follows with
## lag and a clamp fixes that.

## The character to follow. Assign it in the Inspector (drag the Player node in).
@export var target: Node3D

## Convergence speed. Higher makes the camera hug the target more tightly; lower makes it lag and
## smooth more.
@export_range(0.1, 30.0, 0.1) var horizontal_follow_speed := 8.0
@export_range(0.1, 30.0, 0.1) var vertical_follow_speed := 8.0

## The camera never lags the character by more than this many meters vertically.
@export_range(0.0, 10.0, 0.05) var max_vertical_lag := 0.75

## The camera's position relative to the rig, the point it looks at, and the lens field of view.
@export var camera_offset := Vector3(0.0, 30.0, 30.0)
@export var focus_offset := Vector3.ZERO
@export var camera_fov := 30.0

@onready var camera: Camera3D = $Camera3D

var _is_initialized := false


func _ready() -> void:
	camera.position = camera_offset
	camera.fov = camera_fov
	# look_at computes the pitch automatically, so we don't have to hand-type Rotation to match the
	# offset
	camera.look_at(global_position + focus_offset)
	snap_to_target()


## Follow the camera every RENDER frame, not every physics frame: the camera is a visual concern,
## so running it in _process keeps it smooth at the screen's own frame rate.
func _process(delta: float) -> void:
	_follow(delta)


## Snap the rig straight onto the character. Called at start so the camera doesn't fly in from the
## origin, and by Stage after it moves the fox to a spawn point.
func snap_to_target() -> void:
	if target == null or not is_instance_valid(target):
		return
	global_position = target.global_position
	_is_initialized = true

func _follow(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not _is_initialized:
		snap_to_target()
		return

	var target_position := target.global_position

	# 1 - exp(-k * delta), NOT k * delta: this factor is independent of frame rate, so it converges
	# the same whether the game runs at 30 or 144 fps. Using k * delta directly would make the
	# camera hug tighter on a fast machine than a slow one, and k * delta > 1 (on a frame drop)
	# would send the camera overshooting past the target.
	var horizontal_weight := 1.0 - exp(-horizontal_follow_speed * delta)
	global_position.x = lerpf(global_position.x, target_position.x, horizontal_weight)
	global_position.z = lerpf(global_position.z, target_position.z, horizontal_weight)

	# The camera is a perspective camera with a fixed offset, so however far the rig lags the
	# character vertically, the camera-to-character distance changes by just as much — falling
	# from a height would make the character look bigger and smaller in turn. Interpolate for
	# smoothness, then clamp hard so the offset never exceeds the limit.
	var vertical_weight := 1.0 - exp(-vertical_follow_speed * delta)
	var smoothed_y := lerpf(global_position.y, target_position.y, vertical_weight)
	global_position.y = clampf(
		smoothed_y,
		target_position.y - max_vertical_lag,
		target_position.y + max_vertical_lag
	)
