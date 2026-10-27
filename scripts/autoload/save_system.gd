extends Node

## Reads and writes the save file — JSON, for example:
##   {"version": 1, "stage": "res://levels/level_1/stage_2.tscn", "checkpoint": "dock",
##    "flags": {"gate": true}}
## It stores IDs, never coordinates, and never the current health (respawning always heals).

const VERSION := 1
const DEFAULT_SAVE_PATH := "user://save.json"

## Where the file lives. Tests can point this elsewhere so they never touch a real save.
var save_path := DEFAULT_SAVE_PATH


## Writes `data` plus the version number to save_path. Overwrites the previous file.
func save_data(data: Dictionary) -> void:
	var content := data.duplicate()
	content["version"] = VERSION
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s: %s" % [save_path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(content, "\t"))

## The saved data, or {} when there is no file, it isn't valid JSON, or it comes from another
## version of the game.
func load_data() -> Dictionary:
	if not has_save():
		return{}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return {}
	var data: Variant = json.data
	if not data is Dictionary:
		return {}
	var version: Variant = data.get("version")
	if not (version is int or version is float) or version != VERSION:
		return{}
	return data


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)
