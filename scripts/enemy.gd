class_name EnemyCharacter
extends BaseCharacter

## Common framework for every enemy. Every child node below is OPTIONAL — attach whichever an
## enemy needs: a stationary barrel doesn't need a RayCast, a crab doesn't need a detection area.
##
##   <Enemy> (EnemyCharacter)
##   └── Direction (Node3D)
##       ├── FrontRayCast3D      hit a wall yet?
##       ├── DownRayCast3D       still floor ahead?
##       ├── DetectPlayerArea3D  is the fox in range yet?
##       └── HurtArea3D          takes hits from the fox

# Two rays that check for walls and floor edges. They sit under Direction so they ROTATE
# automatically with the facing direction — the 2D version had to flip them by hand with scale.x,
# here that's not needed.
var front_ray_cast: RayCast3D
var down_ray_cast: RayCast3D

# Area that detects the fox
var detect_player_area: Area3D
var found_player: Node3D = null


func _ready() -> void:
	_init_ray_cast()
	_init_detect_player_area()
	_init_hurt_area()
	super._ready()


func _init_ray_cast() -> void:
	if has_node("Direction/FrontRayCast3D"):
		front_ray_cast = $Direction/FrontRayCast3D
	if has_node("Direction/DownRayCast3D"):
		down_ray_cast = $Direction/DownRayCast3D


func _init_detect_player_area() -> void:
	if not has_node("Direction/DetectPlayerArea3D"):
		return
	detect_player_area = $Direction/DetectPlayerArea3D
	detect_player_area.body_entered.connect(_on_body_entered)
	detect_player_area.body_exited.connect(_on_body_exited)


func _init_hurt_area() -> void:
	if has_node("Direction/HurtArea3D"):
		$Direction/HurtArea3D.hurt.connect(_on_hurt_area_3d_hurt)


func is_touch_wall() -> bool:
	return front_ray_cast != null and front_ray_cast.is_colliding()


func is_can_fall() -> bool:
	return down_ray_cast != null and not down_ray_cast.is_colliding()


func enable_check_player_in_sight() -> void:
	if detect_player_area != null:
		detect_player_area.get_node("CollisionShape3D").disabled = false


func disable_check_player_in_sight() -> void:
	if detect_player_area != null:
		detect_player_area.get_node("CollisionShape3D").disabled = true


func _on_body_entered(body: Node3D) -> void:
	found_player = body
	_on_player_in_sight(body.global_position)


func _on_body_exited(_body: Node3D) -> void:
	found_player = null
	_on_player_not_in_sight()


## The current state decides how to take the hit — the Dead state overrides this to skip it.
func _on_hurt_area_3d_hurt(direction: Vector3, damage: float) -> void:
	fsm.current_state.take_damage(direction, damage)


## Called when the fox comes into range. Override this in whichever enemy needs it.
func _on_player_in_sight(_player_pos: Vector3) -> void:
	pass


## Called when the fox leaves range.
func _on_player_not_in_sight() -> void:
	pass
