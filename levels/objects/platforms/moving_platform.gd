extends AnimatableBody3D

@export var offset := Vector3(0, 4, 0)
## Meters per second.
@export var speed := 2.0
## Seconds to wait at each end.
@export var wait_time := 1.0

var _start: Vector3
var _going_out := true
var _wait := 0.0

func _ready() -> void:
	_start = position

func _physics_process(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		return
	var target := _start + offset if _going_out else _start
	position = position.move_toward(target, speed * delta)
	if position.is_equal_approx(target):
		_going_out = not _going_out
		_wait = wait_time
