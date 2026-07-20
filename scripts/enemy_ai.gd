extends "res://scripts/ai_body.gd"

## Chases whoever is in the "player" group and attacks once in range.

@export var detection_range: float = 10.0
@export var attack_trigger_range: float = 1.8
@export var move_speed: float = 3.5
@export var attack_cooldown: float = 1.2

const ATTACKS := ["Punch", "Sword"]

var player: Node3D
var attack_cooldown_timer := 0.0
var next_attack_index := 0

func _ready() -> void:
	super._ready()
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_dead or not animator or not player or not is_instance_valid(player) or player.is_dead:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if animator and not animator.is_busy:
			animator.play_locomotion("Idle")
		super._physics_process(delta)
		return

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	var to_player := player.global_position - global_position
	to_player.y = 0
	var distance := to_player.length()

	if distance > detection_range:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if not animator.is_busy:
			animator.play_locomotion("Idle")
	elif distance > attack_trigger_range:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		rotation.y = atan2(dir.x, dir.z)
		if not animator.is_busy:
			animator.play_locomotion("Run")
	else:
		velocity.x = 0
		velocity.z = 0
		rotation.y = atan2(to_player.x, to_player.z)
		if not animator.is_busy and attack_cooldown_timer <= 0.0:
			animator._attack(ATTACKS[next_attack_index])
			next_attack_index = (next_attack_index + 1) % ATTACKS.size()
			attack_cooldown_timer = attack_cooldown

	super._physics_process(delta)

func _on_respawn() -> void:
	attack_cooldown_timer = 0.0
	next_attack_index = 0
