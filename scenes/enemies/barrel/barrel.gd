extends EnemyCharacter

## A stationary barrel that fires a bullet toward its facing direction every few seconds.

## Impulse applied to the bullet. The bullet's body has mass = 1, so this number is exactly the
## velocity, m/s.
@export var bullet_speed: float = 12.0

@onready var bullet_factory: Node3DFactory = $Direction/BulletFactory


func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Idle)
	super._ready()


## Spawns a bullet at the muzzle then pushes it along the facing direction.
func fire() -> void:
	var bullet := bullet_factory.create() as RigidBody3D
	bullet.apply_impulse(forward() * bullet_speed)
