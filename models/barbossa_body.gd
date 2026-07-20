extends CharacterBody3D

@export var move_speed: float = 4.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 6.0
@export var look_speed: float = 0.002
@export var max_health: int = 100
@export var respawn_delay: float = 5.0

@onready var character: Node3D = $Characters_Captain_Barbarossa
@onready var head: Node3D = $Head

var mouse_captured := false
var look_yaw := 0.0
var health: int
var is_dead := false
var spawn_transform: Transform3D

func _ready() -> void:
	look_yaw = rotation.y
	health = max_health
	spawn_transform = global_transform
	add_to_group("player")
	capture_mouse()

func take_hit(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		is_dead = true
		character.play_action("Death")
		get_tree().create_timer(respawn_delay).timeout.connect(_respawn)
	else:
		character.play_action("HitReact")

func _respawn() -> void:
	is_dead = false
	health = max_health
	velocity = Vector3.ZERO
	global_transform = spawn_transform
	look_yaw = rotation.y

	character.is_busy = false
	character.is_jumping = false
	character.landing_pending = false
	character.anim_player.play("Idle")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_look(event.relative)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if mouse_captured:
			release_mouse()
		else:
			capture_mouse()

func rotate_look(rel: Vector2) -> void:
	look_yaw -= rel.x * look_speed
	rotation.y = look_yaw

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()

	if was_on_floor:
		velocity.y = 0
	else:
		velocity += get_gravity() * delta

	# Airborne: speed from takeoff is locked, but direction can still be steered.
	if character.is_jumping:
		if was_on_floor and velocity.y <= 0:
			character.land()
		else:
			var forward_input := Input.get_axis("ui_down", "ui_up")
			if forward_input != 0:
				var horizontal_speed := maxf(Vector2(velocity.x, velocity.z).length(), move_speed)
				var move_dir := (transform.basis * Vector3(0, 0, forward_input)).normalized()
				velocity.x = move_dir.x * horizontal_speed
				velocity.z = move_dir.z * horizontal_speed
		move_and_slide()
		return

	# Launch: only from the ground, and not mid-attack/other action.
	if was_on_floor and not character.is_busy and Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_velocity
		character.start_jump()
		move_and_slide()
		return

	# Rooted during attacks/reactions/etc: decelerate to a stop in place.
	if character.is_busy:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		move_and_slide()
		return

	var forward_input := Input.get_axis("ui_down", "ui_up")
	var move_dir := (transform.basis * Vector3(0, 0, forward_input)).normalized() if forward_input != 0 else Vector3.ZERO
	var sprinting := Input.is_action_pressed("sprint")
	var speed := sprint_speed if sprinting else move_speed

	if move_dir.length() > 0.01:
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		character.play_locomotion("Run" if sprinting else "Walk", forward_input < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		character.play_locomotion("Idle")

	move_and_slide()
