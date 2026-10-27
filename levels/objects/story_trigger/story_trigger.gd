class_name StoryTrigger
extends Area3D

## Plays a Dialogic timeline when the player enters this area.
@export var timeline := "stage_3_story"
@export var trigger_flag := "stage_3_story_seen"

func _ready() -> void:
	if trigger_flag != "" and GameManager.flags.get(trigger_flag, false):
		queue_free()
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if trigger_flag != "":
			GameManager.flags[trigger_flag] = true
			GameManager.save_game()
		Conversation.play(timeline, body)
		queue_free()
