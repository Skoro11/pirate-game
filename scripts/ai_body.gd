extends CharacterBody3D

## Minimal physics body for AI/NPC characters: gravity so they settle onto
## the floor, plus generic health/hit-reaction handling. No player input.

@export var max_health: int = 30
@export var respawn_delay: float = 5.0
@export var show_health_bar: bool = true
@export var health_bar_width: float = 1.0
@export var health_bar_height: float = 0.12
@export var health_bar_offset_y: float = 2.2

@onready var collider: CollisionShape3D = $Collider

var health: int
var is_dead := false
var animator: Node3D

var health_bar_pivot: Node3D
var health_bar_fill: MeshInstance3D

var spawn_transform: Transform3D
var original_collider_shape: Shape3D
var original_collider_transform: Transform3D

func _ready() -> void:
	health = max_health
	spawn_transform = global_transform
	add_to_group("enemies")
	for child in get_children():
		if child.has_method("play_action"):
			animator = child
			break
	if collider:
		original_collider_shape = collider.shape
		original_collider_transform = collider.transform
	if show_health_bar:
		_create_health_bar()

func take_hit(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	_update_health_bar()
	if health <= 0:
		is_dead = true
		if animator:
			animator.play_action("Death")
		_lie_collider_down()
		if health_bar_pivot:
			health_bar_pivot.visible = false
		get_tree().create_timer(respawn_delay).timeout.connect(_respawn)
	elif animator:
		animator.play_action("HitReact")

func _respawn() -> void:
	is_dead = false
	health = max_health
	velocity = Vector3.ZERO
	global_transform = spawn_transform

	if collider:
		collider.shape = original_collider_shape
		collider.transform = original_collider_transform

	if health_bar_pivot:
		health_bar_pivot.visible = true
	_update_health_bar()

	if animator:
		animator.is_busy = false
		animator.is_jumping = false
		animator.landing_pending = false
		animator.anim_player.play("Idle")

	_on_respawn()

## Override in subclasses to reset any extra state (AI timers, etc.).
func _on_respawn() -> void:
	pass

func _create_health_bar() -> void:
	health_bar_pivot = Node3D.new()
	health_bar_pivot.position = Vector3(0, health_bar_offset_y, 0)
	add_child(health_bar_pivot)

	var bg_material := StandardMaterial3D.new()
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_material.albedo_color = Color(0.1, 0.1, 0.1, 0.85)
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(health_bar_width, health_bar_height)
	bg_mesh.material = bg_material

	var background := MeshInstance3D.new()
	background.mesh = bg_mesh
	health_bar_pivot.add_child(background)

	var fill_material := StandardMaterial3D.new()
	fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_material.albedo_color = Color(0.2, 0.9, 0.25)

	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(health_bar_width, health_bar_height)
	fill_mesh.material = fill_material

	health_bar_fill = MeshInstance3D.new()
	health_bar_fill.mesh = fill_mesh
	health_bar_fill.position.z = 0.001
	health_bar_pivot.add_child(health_bar_fill)

	_update_health_bar()

## Scales the fill quad to the current health fraction, keeping its left
## edge anchored so it shrinks toward the right as health drops.
func _update_health_bar() -> void:
	if not health_bar_fill:
		return
	var fraction := clampf(float(health) / float(max_health), 0.0, 1.0)
	health_bar_fill.scale.x = fraction
	health_bar_fill.position.x = -(health_bar_width * (1.0 - fraction)) / 2.0

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

## Faces the whole health bar toward the camera (Y-axis only, stays
## upright). This has to rotate the pivot itself rather than relying on
## per-material billboarding, otherwise the fill quad's anchor offset gets
## expressed in Mako's own rotating local space and drifts as he turns.
func _process(_delta: float) -> void:
	if not health_bar_pivot or not health_bar_pivot.visible:
		return
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var to_camera := cam.global_position - health_bar_pivot.global_position
	to_camera.y = 0
	if to_camera.length() < 0.01:
		return
	health_bar_pivot.look_at(health_bar_pivot.global_position - to_camera, Vector3.UP)

func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0
	else:
		velocity += get_gravity() * delta
	move_and_slide()
