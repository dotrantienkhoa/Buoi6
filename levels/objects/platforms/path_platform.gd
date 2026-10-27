class_name PathPlatform
extends Node3D

## If true, moves continuously in a ping-pong loop.
## If false, only moves when the player interacts with it on the platform.
@export var auto_start := false

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var _interactive: InteractiveArea3D = $Platform/InteractiveArea3D


func _ready() -> void:
	if auto_start:
		var move_anim := _anim.get_animation("move")
		if move_anim:
			move_anim.loop_mode = Animation.LOOP_PINGPONG
		_anim.play("move")
		return

	# Stop loop and autoplay for interaction mode
	_anim.stop()
	var move_anim := _anim.get_animation("move")
	if move_anim:
		move_anim.loop_mode = Animation.LOOP_NONE

	if _interactive:
		_interactive.interacted.connect(_on_platform_interacted)


func _on_platform_interacted() -> void:
	if _anim.is_playing():
		return
	if _path_follow.progress_ratio < 0.5:
		_move_to_end()
	else:
		_move_to_start()


func _move_to_end() -> void:
	var move_len := _anim.get_animation("move").length
	if _anim.current_animation_position >= move_len - 0.05:
		_anim.seek(0.0, true)
	_anim.play("move")


func _move_to_start() -> void:
	var move_len := _anim.get_animation("move").length
	if _anim.current_animation_position <= 0.05:
		_anim.seek(move_len, true)
	_anim.play_backwards("move")
