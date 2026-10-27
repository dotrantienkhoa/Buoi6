class_name PathAgent
extends Node

## Guides its parent character along a path from the stage's GridPathfinder. It carries the same
## names as NavigationAgent3D — target_position, get_next_path_position(), is_navigation_finished()
## — so the states that drive it read exactly like code written for a NavigationAgent3D.
##
## The parent does the moving: each physics frame it heads for get_next_path_position().
##
## Unlike NavigationAgent3D, a path ends at the center of the target's cell, not at the target
## itself.

## A corner of the path counts as reached within this flat distance, in meters.
@export var path_desired_distance := 0.2

## Where to go. Setting it finds a new path, from where the parent stands right now.
var target_position := Vector3.ZERO:
	set(value):
		target_position = value
		_find_path()

var _path := PackedVector3Array()
var _next := 0


## The corner to head for now. Moves on to the next corner once this one is reached. The parent's
## own position when there is no path.
func get_next_path_position() -> Vector3:
	var body := get_parent() as Node3D
	if _path.is_empty():
		return body.global_position
	while _next < _path.size() - 1 \
			and _flat_distance(body.global_position, _path[_next]) < path_desired_distance:
		_next += 1
	return _path[_next]


## True once the last corner is reached — or right away when there is no path (a target on
## another island, or no Pathfinder in the stage).
func is_navigation_finished() -> bool:
	if _path.is_empty():
		return true
	var body := get_parent() as Node3D
	return _next >= _path.size() - 1 \
		and _flat_distance(body.global_position, _path[_path.size() - 1]) < path_desired_distance


## The path's first corner is the graph point nearest the parent — normally the center of the cell
## it stands in: skip it. Otherwise a chaser that finds a new path four times a second walks back
## to its own cell's center every time and never gets anywhere. Skipping is safe: two neighbouring
## cells make one rectangle, so the straight line from anywhere in this cell to the next cell's
## center stays inside it.
func _find_path() -> void:
	var body := get_parent() as Node3D
	var finder := GridPathfinder.find(self)
	_path = PackedVector3Array()
	if finder != null:
		_path = finder.find_path(body.global_position, target_position)
	_next = 1 if _path.size() > 1 else 0


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
