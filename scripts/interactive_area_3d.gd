class_name InteractiveArea3D
extends Area3D

## A zone the fox can interact with: while the fox stands inside, pressing `interact` emits
## `interacted`, and a key hint floats above the zone. Same three signals as InteractiveArea2D in
## the 2D version of this lesson. Add it with Add Child Node, then give it a CollisionShape3D child.
## The key hint (a Label3D named Prompt) is built in code, in _ready().

signal interacted
signal interaction_available
signal interaction_unavailable

@export var interact_input_action := "interact"
## Height of the key hint above the zone's origin, in meters.
@export var prompt_height := 2.2

var _prompt: Label3D


## A fresh node detects the fox (layer 2) and nothing detects it. Values saved in a scene still
## win: Godot applies them after _init().
func _init() -> void:
	collision_layer = 0
	collision_mask = 2


func _ready() -> void:
	set_process_unhandled_input(false)
	_prompt = _create_prompt()
	add_child(_prompt)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interact_input_action) and _someone_can_interact():
		get_viewport().set_input_as_handled()
		interacted.emit()


## A press only counts for a body that is able to interact right now (Player.can_interact(): alive,
## not already talking). Otherwise the key is left alone — Dialogic advances its lines with it.
func _someone_can_interact() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if not body.has_method("can_interact") or body.can_interact():
			return true
	return false


## "F" floating prompt_height above the zone, always facing the camera, drawn over everything.
## Hidden until the fox walks in.
func _create_prompt() -> Label3D:
	var prompt := Label3D.new()
	prompt.name = "Prompt"
	prompt.text = "F"
	prompt.font_size = 64
	prompt.outline_size = 16
	prompt.pixel_size = 0.01
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.no_depth_test = true
	prompt.position.y = prompt_height
	prompt.visible = false
	return prompt


func _on_body_entered(_body: Node3D) -> void:
	set_process_unhandled_input(true)
	_prompt.visible = true
	interaction_available.emit()


func _on_body_exited(_body: Node3D) -> void:
	set_process_unhandled_input(false)
	_prompt.visible = false
	interaction_unavailable.emit()
