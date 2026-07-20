extends CharacterBody3D

## Minimal physics body for AI/NPC characters: gravity so they settle onto
## the floor, plus generic health/hit-reaction handling. No player input.

@export var max_health: int = 30

@onready var collider: CollisionShape3D = $Collider

var health: int
var is_dead := false
var animator: Node3D

func _ready() -> void:
	health = max_health
	for child in get_children():
		if child.has_method("play_action"):
			animator = child
			break

func take_hit(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		is_dead = true
		if animator:
			animator.play_action("Death")
		_lie_collider_down()
	elif animator:
		animator.play_action("HitReact")

## Roughly matches the Death animation's fallen pose so the body still
## blocks movement instead of leaving a standing capsule nobody can see.
func _lie_collider_down() -> void:
	if not collider or not collider.shape:
		return
	collider.rotation_degrees.x = 90

	# Duplicate first: the shape resource is shared with other characters'
	# colliders, so mutating it in place would resize them too.
	var lying_shape := collider.shape.duplicate() as CapsuleShape3D
	lying_shape.height *= 0.8
	
	collider.shape = lying_shape

	# Fell backward, so shift the pivot back by half the length instead of
	# leaving the capsule centered on (and bleeding in front of) where he stood.
	collider.position = Vector3(0, lying_shape.radius, -lying_shape.height / 2.0)

func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0
	else:
		velocity += get_gravity() * delta
	move_and_slide()
