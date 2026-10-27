extends Area3D
class_name HitArea3D

## The area that DEALS damage. A one-way relationship: Hit looks for Hurt, Hurt never looks for Hit.
## Who can hit whom is decided by the collision mask — see the layer table in part 3 of the lesson
## document.

## Damage dealt per hit.
@export var damage: int = 1

## Emitted AFTER damage has been dealt, so outside code can do more with it (a bullet uses it
## to destroy itself).
signal hitted(area: Area3D)

func _init() -> void:
	area_entered.connect(_on_area_entered)

## Deals damage to a HurtArea3D.
##
## The push direction is computed from the hit area's center to the hurt area's center, then
## FLATTENED ONTO THE XZ PLANE. A topdown hit never launches the character into the air; if it
## should bounce up, the Hurt state sets velocity.y itself.
func hit(hurt_area: Node) -> void:
	if not hurt_area.has_method("take_damage"):
		return
	var hit_dir: Vector3 = hurt_area.global_position - global_position
	hit_dir.y = 0.0
	# If the two centers coincide (an enemy standing right on top of the fox), normalized() returns
	# a zero vector and the character doesn't get pushed anywhere. In that case, fall back to the
	# hit area's own facing direction: its local +Z, the front (Vector3.MODEL_FRONT).
	if hit_dir.length_squared() < 0.0001:
		hit_dir = global_transform.basis.z
		hit_dir.y = 0.0
	hurt_area.take_damage(hit_dir.normalized(), damage)

func _on_area_entered(area: Area3D) -> void:
	hit(area)
	hitted.emit(area)
