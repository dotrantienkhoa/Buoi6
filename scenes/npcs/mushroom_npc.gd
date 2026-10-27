extends BaseCharacter

## The talking mushroom of the village: rests, then walks to a random spot near home along the
## stage's A* grid (GridPathfinder, through its PathAgent); when the fox presses F next to it, it
## stops and talks. Not an enemy: no hit or hurt area, and no Carried / Thrown states — the fox
## can't pick it up.

## How far from where it was placed the mushroom wanders, in meters.
@export var home_radius := 3.0
## Seconds of rest between two walks, picked at random between x and y.
@export var rest_time := Vector2(1.0, 3.0)
## Gives up on a walk that hasn't arrived after this many seconds (something blocks the way, or
## the walk is just that long).
@export var timeline := "mushroom"
@export var can_wander := true
@export var walk_timeout := 10.0

## Where it wanders around: where it stood when the stage started.
var home := Vector3.ZERO

@onready var agent: PathAgent = $PathAgent
@onready var talk_area: InteractiveArea3D = $InteractiveArea3D


func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Idle)
	home = global_position
	talk_area.interacted.connect(_on_talk_area_interacted)
	super._ready()


## A random walkable point near home: a random spot of the home disc, pulled to the center of the
## nearest walkable cell — tried again while that center lies outside the disc (cells are 2 m, so
## it can) or less than 1 m from where the mushroom stands (a walk worth taking). Home's own cell
## after 8 misses.
func random_home_point() -> Vector3:
	var finder := GridPathfinder.find(self)
	if finder == null:
		return global_position
	for i in 8:
		var angle := randf() * TAU
		var distance := home_radius * sqrt(randf())    # sqrt: spread evenly over the disc
		var point := finder.closest_point(home + Vector3(cos(angle) * distance, 0.0,
			sin(angle) * distance))
		var from_home := Vector2(point.x - home.x, point.z - home.z).length()
		var from_here := Vector2(point.x - global_position.x, point.z - global_position.z).length()
		if from_home <= home_radius and from_here >= 1.0:
			return point
	return finder.closest_point(home)


## One physics frame of walking: head for the next corner of the path. Horizontal only — gravity
## and move_and_slide() come from BaseCharacter.
func steer_along_path() -> void:
	var next := agent.get_next_path_position()
	var to_next := next - global_position
	to_next.y = 0.0
	# At the last corner, stop: stepping on toward it would overshoot back and forth every frame.
	if agent.is_navigation_finished() or to_next.length_squared() < 0.0001:
		stop_horizontal()
		return
	var step := to_next.normalized() * movement_speed
	velocity.x = step.x
	velocity.z = step.z
	change_direction(direction_to(global_position, next))


## F next to the mushroom: talk. For now only a line in the Output panel; part 7 starts a dialogue
## here instead.
func _on_talk_area_interacted() -> void:
	for body: Node3D in talk_area.get_overlapping_bodies():
		if body is Player:
			Conversation.play(timeline, body, self)
			return
