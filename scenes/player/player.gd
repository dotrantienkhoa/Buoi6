class_name Player
extends BaseCharacter

## Emitted once the Dead state has played out. GameManager hooks it up to respawn() when the fox's
## stage registers; a scene that isn't a stage connects it itself (tests/test.gd restarts the yard).
signal died

## Turned on throughout the Hurt state so one hit doesn't drain health every single frame in a row.
var is_invulnerable: bool = false

## The thing currently being carried overhead; null when empty-handed. Kept on Player rather than
## on the Carry state, so other states (and any other code) can ask "is the fox holding anything".
var held: BaseCharacter = null

## True while a conversation runs: F then advances the dialogue instead of interacting again.
var is_talking: bool = false

@onready var hold_point: Marker3D = $HoldPoint
@onready var grab_area: Area3D = $Direction/GrabArea3D


func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Idle)
	$Direction/HurtArea3D.hurt.connect(_on_hurt_area_3d_hurt)
	super._ready()


## Every state of the fox can take damage, so this calls straight into the current state; whichever
## state doesn't want to lose health (Dead) overrides take_damage().
func _on_hurt_area_3d_hurt(_direction: Vector3, damage: float) -> void:
	if is_invulnerable:
		return
	fsm.current_state.take_damage(int(damage))


## The nearest pickable thing inside GrabArea3D, or null if there's none. GrabArea3D sits under
## Direction so it's always on the side the fox is facing — no need to enable/disable it per
## direction.
func find_carryable() -> BaseCharacter:
	var nearest: BaseCharacter = null
	var nearest_distance := INF
	for body: Node3D in grab_area.get_overlapping_bodies():
		if not (body is BaseCharacter and body.can_be_carried()):
			continue
		var distance := global_position.distance_squared_to(body.global_position)
		if distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest


## Dies on the spot, whatever the health — e.g. falling into the sea (KillZone).
func die() -> void:
	health = 0
	fsm.change_state(fsm.states.dead)


## Whether the fox may use an InteractiveArea3D right now: alive, and not already talking.
func can_interact() -> bool:
	return health > 0 and not is_talking


## On top of BaseCharacter's: from now on F belongs to the dialogue (can_interact() is false).
## is_talking goes on BEFORE the state change.
func start_talk(listener: Node3D = null) -> void:
	is_talking = true
	super(listener)


## On top of BaseCharacter's: F interacts again. A fox hit mid-dialogue is in Hurt, not Talk — Hurt
## then sees is_talking off and returns to Idle by itself.
func finish_talk() -> void:
	is_talking = false
	super()
