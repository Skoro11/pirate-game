extends "res://scripts/ai_body.gd"

## Test/demo loop: walk a full circle around the spawn point, jump, throw
## both attacks, then walk back to the exact start position and repeat.
## Exercises every shared control (locomotion, jump sequence, actions) so we
## can confirm they all work the same way on an AI-driven character.

@export var circle_radius: float = 4.0
@export var move_speed: float = 3.0
@export var circle_duration: float = 6.0
@export var jump_velocity: float = 6.0

const ATTACK_SEQUENCE := ["Punch", "Sword"]

enum State { CIRCLING, JUMPING, ATTACKING, RETURNING }

var state := State.CIRCLING
var start_position: Vector3
var start_rotation_y: float
var circle_angle := 0.0
var attack_index := 0

func _ready() -> void:
	super._ready()
	start_position = global_position
	start_rotation_y = rotation.y

func _physics_process(delta: float) -> void:
	if is_dead or not animator:
		super._physics_process(delta)
		return

	match state:
		State.CIRCLING:
			_process_circling(delta)
		State.JUMPING:
			_process_jumping()
		State.ATTACKING:
			_process_attacking()
		State.RETURNING:
			_process_returning(delta)

	super._physics_process(delta)

func _process_circling(delta: float) -> void:
	circle_angle += (TAU / circle_duration) * delta
	if circle_angle >= TAU:
		circle_angle = 0.0
		_enter_jump()
		return

	var target := start_position + Vector3(cos(circle_angle), 0, sin(circle_angle)) * circle_radius
	_move_toward_point(target)

func _process_jumping() -> void:
	if is_on_floor() and velocity.y <= 0:
		animator.land()
	if not animator.is_jumping:
		_enter_attacking()

func _process_attacking() -> void:
	velocity.x = 0
	velocity.z = 0
	if animator.is_busy:
		return
	attack_index += 1
	if attack_index < ATTACK_SEQUENCE.size():
		animator.play_action(ATTACK_SEQUENCE[attack_index])
	else:
		state = State.RETURNING

func _process_returning(delta: float) -> void:
	if _move_toward_point(start_position, 0.15):
		velocity.x = 0
		velocity.z = 0
		rotation.y = start_rotation_y
		animator.play_locomotion("Idle")
		state = State.CIRCLING

func _enter_jump() -> void:
	state = State.JUMPING
	# Keep whatever horizontal velocity he had from circling so the jump
	# actually covers ground instead of going straight up in place.
	velocity.y = jump_velocity
	animator.start_jump()

func _enter_attacking() -> void:
	state = State.ATTACKING
	attack_index = 0
	animator.play_action(ATTACK_SEQUENCE[attack_index])

## Steers toward a point at move_speed and faces the movement direction.
## Returns true once within arrive_distance of the target.
func _move_toward_point(target: Vector3, arrive_distance: float = 0.05) -> bool:
	var to_target := target - global_position
	to_target.y = 0
	if to_target.length() <= arrive_distance:
		return true

	var dir := to_target.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	rotation.y = atan2(dir.x, dir.z)
	animator.play_locomotion("Run")
	return false
