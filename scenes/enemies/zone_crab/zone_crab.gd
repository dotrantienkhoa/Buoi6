class_name ZoneCrab
extends EnemyCharacter

## A crab that belongs to an EnemyZone: wanders around the zone, chases the fox it sees, and walks
## back once a chase has dragged it too far from the zone's center. It moves along the stage's A*
## grid with a PathAgent, the same way the village mushroom does.
##
## zone_crab.tscn inherits crab.tscn, so the crab's Run state is still in the tree — an inherited
## scene can add nodes but never delete them. Run is just never entered: the FSM starts in Wander.
## That is also why this script extends EnemyCharacter and not crab.gd: crab.gd's _ready() starts
## the FSM in Run.

## Speed while chasing the fox, in m/s. movement_speed is the speed while wandering.
@export var chase_speed := 3.5
## Seconds of rest between two walks, picked at random between x and y.
@export var rest_time := Vector2(1.0, 2.0)
## Gives up on a walk that hasn't arrived after this many seconds (something blocks the way, or
## the walk is just that long).
@export var walk_timeout := 8.0

## The zone that spawned this crab, set by EnemyZone before the crab enters the tree. Null for a
## crab placed in a stage by hand: that one stays put until it sees the fox, then chases it
## anywhere (no leash) and never walks back.
var zone: EnemyZone = null

## True from the moment the crab starts walking back to its zone until it gets there. Hurt returns
## to Wander, which reads this to send the crab back to Return instead of chasing the fox.
var returning := false

@onready var agent: PathAgent = $PathAgent


func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Wander)
	super._ready()


func has_zone() -> bool:
	return zone != null and is_instance_valid(zone)


## A random walkable point of the zone. Where the crab already stands when it has no zone, or the
## stage has no Pathfinder.
func random_zone_point() -> Vector3:
	if not has_zone():
		return global_position
	var point := zone.random_point()
	return point if point != Vector3.INF else global_position


## True once a chase has dragged the crab farther from the zone's center than the zone allows.
func is_out_of_leash() -> bool:
	return has_zone() and zone.distance_from_center(global_position) > zone.leash_radius


## The fox, while it is inside the detection sphere and alive; null otherwise.
func visible_fox() -> Player:
	var fox := found_player as Player
	if fox != null and fox.health > 0:
		return fox
	return null


## One physics frame of walking at `speed`: head for the next corner of the agent's path.
## Horizontal only — gravity and move_and_slide() come from BaseCharacter.
func steer_along_path(speed: float) -> void:
	var next := agent.get_next_path_position()
	var to_next := next - global_position
	to_next.y = 0.0
	# At the last corner, stop: stepping on toward it would overshoot back and forth every frame.
	if agent.is_navigation_finished() or to_next.length_squared() < 0.0001:
		stop_horizontal()
		return
	var step := to_next.normalized() * speed
	velocity.x = step.x
	velocity.z = step.z
	change_direction(direction_to(global_position, next))
