class_name GridPathfinder
extends Node

## Finds paths over the stage's GridMap with A* (AStar3D): every walkable cell is one point of the
## graph, joined to its four neighbours. No baking — the graph is built from the cells the first
## time someone asks.
##
## A cell of floor_map is walkable when:
##  - its item's name starts with one of walkable_prefixes (the library has four grass and three
##    trail variants picked at random: matching names beats listing item ids);
##  - the two cells above it are empty, in floor_map and in every obstacle map — no plateau,
##    cliff wall or block over it (stage 2's plateau floats 4 m up, so one cell isn't enough);
##  - no obstacle map has an item in the cell itself (a bush stands IN its floor cell);
##  - no node of the "path_blockers" group (a palm, a door) stands in it.
## A stair cell is also joined to the walkable cells one layer down: that is how a path climbs.
## The obstacle maps must share floor_map's grid (same cell size, same origin).

const GROUP := &"pathfinder"
const BLOCKER_GROUP := &"path_blockers"
const STAIR_PREFIX := "stair_"
const NEIGHBOURS: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1),
	Vector3i(0, 0, -1)]

## The GridMap holding the floor, the cliff walls and the stairs.
@export var floor_map: GridMap
## Other GridMaps whose items stand on the floor: blocks, bushes.
@export var obstacle_maps: Array[GridMap] = []
## A cell whose item name starts with one of these can be walked on.
@export var walkable_prefixes: PackedStringArray = ["floor_", "stair_"]

var _astar := AStar3D.new()
## Grid cell -> A* point id.
var _ids: Dictionary[Vector3i, int] = {}
var _built := false


## The Pathfinder of the stage `node` belongs to; null if that stage has none. While the game
## switches stages, the old stage can still be in the tree for a frame — hence the ancestor check.
## The Pathfinder must be a direct child of the stage: only its parent's subtree is searched, so
## under any other node the NPCs silently stand still.
static func find(node: Node) -> GridPathfinder:
	for finder: Node in node.get_tree().get_nodes_in_group(GROUP):
		if finder.get_parent().is_ancestor_of(node):
			return finder
	return null


## In _enter_tree(), not _ready(): every node of the stage enters the tree before any of them is
## ready, so an NPC asking from its own _ready() still finds this one.
func _enter_tree() -> void:
	add_to_group(GROUP)


## The corners of the shortest path from the cell nearest `from` to the cell nearest `to`. Empty
## when the two cells aren't connected (another island) or the graph is empty.
func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	_build_once()
	if _astar.get_point_count() == 0:
		return PackedVector3Array()
	return _astar.get_point_path(_astar.get_closest_point(from), _astar.get_closest_point(to))


## The walkable point nearest `position` (a cell's center, on its walking surface). `position`
## itself when the graph is empty.
func closest_point(position: Vector3) -> Vector3:
	_build_once()
	if _astar.get_point_count() == 0:
		return position
	return _astar.get_point_position(_astar.get_closest_point(position))


func point_count() -> int:
	_build_once()
	return _astar.get_point_count()


func _build_once() -> void:
	if _built:
		return
	_built = true
	if floor_map == null:
		push_warning("%s: no floor_map — no paths" % get_path())
		return
	var blocked := _blocked_cells()
	for cell: Vector3i in floor_map.get_used_cells():
		if _is_walkable(cell) and not blocked.has(cell):
			var id := _astar.get_available_point_id()
			_astar.add_point(id, _point_of(cell))
			_ids[cell] = id
	for cell: Vector3i in _ids:
		for step: Vector3i in NEIGHBOURS:
			_join(cell, cell + step)
			if _is_stair(cell):
				_join(cell, cell + step + Vector3i.DOWN)


## The cells a "path_blockers" node of this stage stands in.
func _blocked_cells() -> Dictionary[Vector3i, bool]:
	var cells: Dictionary[Vector3i, bool] = {}
	for blocker: Node in get_tree().get_nodes_in_group(BLOCKER_GROUP):
		if blocker is Node3D and get_parent().is_ancestor_of(blocker):
			cells[floor_map.local_to_map(floor_map.to_local(blocker.global_position))] = true
	return cells


func _is_walkable(cell: Vector3i) -> bool:
	if not _has_prefix(_item_name(cell), walkable_prefixes):
		return false
	for up in [1, 2]:
		if floor_map.get_cell_item(cell + Vector3i(0, up, 0)) != GridMap.INVALID_CELL_ITEM:
			return false
	for map: GridMap in obstacle_maps:
		for up in [0, 1, 2]:
			if map.get_cell_item(cell + Vector3i(0, up, 0)) != GridMap.INVALID_CELL_ITEM:
				return false
	return true


func _is_stair(cell: Vector3i) -> bool:
	return _item_name(cell).begins_with(STAIR_PREFIX)


func _item_name(cell: Vector3i) -> String:
	var item := floor_map.get_cell_item(cell)
	if item == GridMap.INVALID_CELL_ITEM:
		return ""
	return floor_map.mesh_library.get_item_name(item)


func _has_prefix(item_name: String, prefixes: PackedStringArray) -> bool:
	for prefix in prefixes:
		if item_name.begins_with(prefix):
			return true
	return false


## Where a character stands in `cell`: on a floor cell, the walking surface (half a cell above
## the cell's bottom — the meshes are modeled that way); on a stair cell, halfway up the slope.
func _point_of(cell: Vector3i) -> Vector3:
	var local := floor_map.map_to_local(cell)
	if not _is_stair(cell):
		local.y += floor_map.cell_size.y / 2.0
	return floor_map.to_global(local)


func _join(a: Vector3i, b: Vector3i) -> void:
	if _ids.has(b) and not _astar.are_points_connected(_ids[a], _ids[b]):
		_astar.connect_points(_ids[a], _ids[b])    # both ways
