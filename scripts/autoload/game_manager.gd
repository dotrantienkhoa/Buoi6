extends Node

## Everything that has to outlive a stage change: where the fox appears in the next stage, the last
## checkpoint, world flags (an unlocked door), and the fox's health while it walks through a door.
##
## There is ONE way to switch stages — change_stage(stage, spawn) — used by doors, by respawning
## after death and by continuing a saved game. The new stage calls register_stage() from its
## _ready(), and that is the only place that decides where the fox appears.

## Emitted once a stage has loaded and the fox is in place.
signal stage_changed(stage: Stage)

## The game's main scene. A new game starts here, and so does a fox that dies before touching any
## checkpoint.
const FIRST_STAGE := "res://levels/level_1/stage_1.tscn"

var current_stage: Stage = null
## Where the next stage puts the fox: a door id or a checkpoint id. "" = the stage's default spot
## (wherever the Player node sits in the scene).
var pending_spawn := ""
## The last checkpoint the fox touched. Both "" = none yet.
var checkpoint_stage := ""
var checkpoint_id := ""
## World flags that survive stage changes and go into the save file, e.g. {"gate": true}.
var flags: Dictionary = {}
## The fox's health carried through a door; -1 = start with full health.
var player_health := -1

var _changing := false
var _booted := false


func _ready() -> void:
	load_game()
	get_tree().scene_changed.connect(_on_scene_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("new_game"):
		get_viewport().set_input_as_handled()
		new_game()


## The only way to switch stages. `spawn_name` is a door id or a checkpoint id in the new stage
## ("" = the stage's default spot). `keep_health` = false for respawning and new games: full
## health.
func change_stage(stage_path: String, spawn_name: String = "", keep_health: bool = true) -> void:
	if _changing:
		return    # already switching — a second press of F, for example
	if not ResourceLoader.exists(stage_path):
		# A typo in a door's target_stage, or a save file from an older version of the game. Refuse
		# it here: once _changing is set, nothing would clear it again.
		push_error("No stage at '%s'" % stage_path)
		return
	var health := -1
	if keep_health and current_stage != null and is_instance_valid(current_stage):
		health = current_stage.player.health
		if health <= 0:
			return    # a dead fox goes nowhere: respawn() takes it from here, with full health
	_end_dialogue()
	_changing = true
	pending_spawn = spawn_name
	player_health = health
	# Deferred: this usually runs inside a signal fired mid physics step (an Area3D, an animation);
	# swapping the scene right there would free nodes the engine is still walking.
	get_tree().change_scene_to_file.call_deferred(stage_path)


## A conversation must not follow the fox into the next stage: Dialogic's dialogue box lives under
## the root, not in the stage, so a scene change alone doesn't close it. Looked up by path — the
## addon is optional (it is installed in part 6).
func _end_dialogue() -> void:
	var dialogic := get_node_or_null("/root/Dialogic")
	if dialogic != null and dialogic.current_timeline != null:
		dialogic.end_timeline(true)


func is_changing() -> bool:
	return _changing


## Called by Stage._ready(). The Player is ready by then: Godot runs _ready() on children before
## their parent.
func register_stage(stage: Stage) -> void:
	current_stage = stage
	_changing = false
	stage.player.died.connect(respawn)
	if not _booted:
		_booted = true
		# The game has just started from its main scene: continue the saved game at its
		# checkpoint. A stage opened on its own (F6 in the editor) is left alone, so it can be
		# tested without deleting the save file first.
		if checkpoint_id != "" and stage.scene_file_path == FIRST_STAGE:
			if checkpoint_stage != FIRST_STAGE:
				change_stage(checkpoint_stage, checkpoint_id, false)
				return
			pending_spawn = checkpoint_id
	if player_health > 0:
		stage.player.health = player_health
	if pending_spawn != "":
		stage.place_player_at(pending_spawn)
		pending_spawn = ""
	stage_changed.emit(stage)


## A scene that isn't a Stage (the test yard, a menu) never calls register_stage(), so nothing else
## would clear _changing — and doors and respawning would be refused from then on.
func _on_scene_changed() -> void:
	if not (get_tree().current_scene is Stage):
		_changing = false


## The fox died: back to the last checkpoint with full health — by RELOADING its stage, even when
## it's the stage the fox is in, so everything half-done is cleared: a carried mushroom, bullets in
## flight, crabs mid-chase. No checkpoint yet: the start of the game.
func respawn() -> void:
	if checkpoint_id != "":
		change_stage(checkpoint_stage, checkpoint_id, false)
	else:
		change_stage(FIRST_STAGE, "", false)


## A checkpoint was touched: remember it and save the game right away.
func set_checkpoint(stage_path: String, id: String) -> void:
	checkpoint_stage = stage_path
	checkpoint_id = id
	save_game()


func unlock_door(flag: String) -> void:
	flags[flag] = true
	save_game()


func is_door_unlocked(flag: String) -> bool:
	return flags.get(flag, false)


func save_game() -> void:
	SaveSystem.save_data({"stage": checkpoint_stage, "checkpoint": checkpoint_id, "flags": flags})


## Reads the save file into memory. Doesn't move the fox — register_stage() does that for the
## first stage of the session. A checkpoint without a stage, without an id, or in a stage that
## doesn't exist any more counts as no checkpoint: a broken file counts as no file.
func load_game() -> void:
	var data := SaveSystem.load_data()
	checkpoint_stage = str(data.get("stage", ""))
	checkpoint_id = str(data.get("checkpoint", ""))
	var saved_flags: Variant = data.get("flags", {})
	flags = saved_flags if saved_flags is Dictionary else {}
	if checkpoint_stage == "" or checkpoint_id == "" or not ResourceLoader.exists(checkpoint_stage):
		checkpoint_stage = ""
		checkpoint_id = ""


## F9: forget the save file and start over in stage 1 — even in the middle of a stage change.
func new_game() -> void:
	SaveSystem.delete_save()
	reset()
	_booted = true    # nothing left to continue
	change_stage(FIRST_STAGE, "", false)


## Forgets everything held in memory, as if the game had just started without a save file.
func reset() -> void:
	current_stage = null
	pending_spawn = ""
	checkpoint_stage = ""
	checkpoint_id = ""
	flags = {}
	player_health = -1
	_changing = false
	_booted = false
