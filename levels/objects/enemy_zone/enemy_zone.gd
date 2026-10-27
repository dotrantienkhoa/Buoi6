class_name EnemyZone
extends Area3D

## A box of the stage that keeps itself stocked with enemies. Every spawn_interval seconds, if
## fewer than max_enemies of its enemies are alive, it drops one more on a random walkable spot
## inside the box. An enemy that dies (or falls into the sea) leaves the tree, the zone counts it
## out, and a later tick replaces it.
##
## The box is the CollisionShape3D's BoxShape3D: drag its handles in the editor to resize the zone.
## The Area3D itself detects nothing (no layer, no mask) — it is only there to give the box a shape
## you can see and edit.

signal zone_cleared

## What the zone spawns. Whatever has a `zone` property gets this zone written into it.
@export var enemy_scene: PackedScene
@export var max_enemies := 3
## Seconds between two spawns.
@export var spawn_interval := 4.0
## How far (flat, in meters) from the zone's center its enemies may chase the fox before giving up
## and walking back. Keep it larger than half the box's diagonal: otherwise an enemy wandering to a
## corner of the box would already count as too far.
@export var leash_radius := 7.0
@export var can_respawn := true
## Total enemies to defeat to clear this zone. If 0 and can_respawn is false, defaults to max_enemies.
@export var total_enemies := 0
## If set, GameManager.unlock_door(unlock_flag) will be called when all enemies are defeated.
@export var unlock_flag := ""

var _alive := 0
var _spawned_total := 0
var _killed_total := 0
var _cleared := false

@onready var _box: CollisionShape3D = $CollisionShape3D
@onready var _timer: Timer = $Timer


func _ready() -> void:
	# If this zone was already cleared in a previous run/save, don't spawn again
	if unlock_flag != "" and GameManager.is_door_unlocked(unlock_flag):
		_cleared = true
		return

	if not can_respawn and total_enemies <= 0:
		total_enemies = max_enemies

	_timer.wait_time = spawn_interval
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start()

	# Spawn initial enemies so the player doesn't have to wait for the first interval
	_spawn_initial.call_deferred()


func _spawn_initial() -> void:
	if _cleared or not is_inside_tree():
		return
	var initial_count := max_enemies if not can_respawn else 1
	for _i in range(initial_count):
		if not can_respawn and _spawned_total >= total_enemies:
			break
		_spawn_one()


## How many of this zone's enemies are in the tree right now (a dying one counts until it's gone).
func alive_count() -> int:
	return _alive


## A random point of the box, pulled to the center of the nearest walkable cell. Vector3.INF when
## the stage has no Pathfinder.
func random_point() -> Vector3:
	var finder := GridPathfinder.find(self)
	if finder == null:
		return Vector3.INF
	var half: Vector3 = (_box.shape as BoxShape3D).size / 2.0
	var local := Vector3(randf_range(-half.x, half.x), 0.0, randf_range(-half.z, half.z))
	return finder.closest_point(_box.global_transform * local)


## The flat distance from the center of the box to `point`.
func distance_from_center(point: Vector3) -> float:
	var center := _box.global_position
	return Vector2(point.x - center.x, point.z - center.z).length()


func _on_timer_timeout() -> void:
	_spawn_one()


func _spawn_one() -> void:
	if _cleared or enemy_scene == null:
		return
	if not can_respawn and _spawned_total >= total_enemies:
		_timer.stop()
		return
	if _alive >= max_enemies:
		return
	var point := random_point()
	if point == Vector3.INF:
		return    # no Pathfinder in this stage
	var enemy: Node3D = enemy_scene.instantiate()
	if "zone" in enemy:
		enemy.zone = self
	# A sibling of the zone, not a child: rotating or scaling the zone mustn't drag its enemies.
	get_parent().add_child(enemy)
	enemy.global_position = point
	_alive += 1
	_spawned_total += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	if not can_respawn and _spawned_total >= total_enemies:
		_timer.stop()


## An enemy that is picked up or thrown is reparented, which fires tree_exited too but leaves it
## alive and coming back: only one that is queued for deletion (Dead and KillZone both queue_free)
## is counted out.
func _on_enemy_tree_exited(enemy: Node) -> void:
	if enemy.is_queued_for_deletion():
		_alive -= 1
		_killed_total += 1
		if not can_respawn:
			var target := total_enemies if total_enemies > 0 else max_enemies
			if _killed_total >= target and not _cleared:
				_cleared = true
				_on_cleared()


func _on_cleared() -> void:
	_timer.stop()
	zone_cleared.emit()
	if unlock_flag != "":
		GameManager.unlock_door(unlock_flag)
