extends "res://scripts/ai_body.gd"

## Hunts down the nearest "hostile" within range and attacks once in reach.
## Mirrors enemy_ai.gd's chase/attack logic, but retargets dynamically
## instead of tracking one fixed player reference, since there can be
## several hostiles to choose from.

@export var detection_range: float = 10.0
@export var attack_trigger_range: float = 1.8
@export var move_speed: float = 3.5
@export var attack_cooldown: float = 1.2
@export var retarget_interval: float = 0.5
@export var follow_distance: float = 5.0
@export var follow_start_buffer: float = 1.5
@export var turn_speed: float = 8.0
const ATTACKS := ["Punch", "Sword"]

var player: Node3D
var target: Node3D
var attack_cooldown_timer := 0.0
var retarget_timer := 0.0
var next_attack_index := 0
var is_chasing_player := false

func _ready() -> void:
	faction = "friendly"
	super._ready()
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_dead or not animator:
		super._physics_process(delta)
		return

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = retarget_interval
		_find_target()

	if not target or not is_instance_valid(target) or target.is_dead:
		target = null
		_follow_player(delta)
		super._physics_process(delta)
		return

	var to_target := target.global_position - global_position
	to_target.y = 0
	var distance := to_target.length()

	if distance > attack_trigger_range:
		var dir := to_target.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		rotation.y = atan2(dir.x, dir.z)
		if not animator.is_busy:
			animator.play_locomotion("Run")
	else:
		velocity.x = 0
		velocity.z = 0
		rotation.y = atan2(to_target.x, to_target.z)
		if not animator.is_busy and attack_cooldown_timer <= 0.0:
			animator._attack(ATTACKS[next_attack_index])
			next_attack_index = (next_attack_index + 1) % ATTACKS.size()
			attack_cooldown_timer = attack_cooldown

	super._physics_process(delta)

## No hostile nearby: stick close to the player instead of standing still.
## Uses hysteresis (separate start/stop distances) and smoothed turning so
## he doesn't flicker between Run/Idle or whip-turn when cutting corners.
func _follow_player(delta: float) -> void:
	if not player or not is_instance_valid(player) or player.is_dead:
		is_chasing_player = false
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if not animator.is_busy:
			animator.play_locomotion("Idle")
		return

	var to_player := player.global_position - global_position
	to_player.y = 0
	var distance := to_player.length()

	if is_chasing_player:
		if distance <= follow_distance:
			is_chasing_player = false
	elif distance > follow_distance + follow_start_buffer:
		is_chasing_player = true

	if is_chasing_player and distance > 0.05:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		var target_angle := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, clampf(turn_speed * delta, 0.0, 1.0))
		if not animator.is_busy:
			animator.play_locomotion("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if not animator.is_busy:
			animator.play_locomotion("Idle")

func _find_target() -> void:
	var nearest: Node3D = null
	var nearest_dist := detection_range
	for node in get_tree().get_nodes_in_group("hostile"):
		var candidate := node as Node3D
		if not candidate or candidate == self or candidate.is_dead:
			continue
		var dist: float = (candidate.global_position - global_position).length()
		if dist <= nearest_dist:
			nearest_dist = dist
			nearest = candidate
	target = nearest

func _on_respawn() -> void:
	attack_cooldown_timer = 0.0
	next_attack_index = 0
	target = null
