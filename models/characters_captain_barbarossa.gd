extends "res://models/character_animator.gd"

## Player-only input wiring (test keys + attack clicks) on top of the
## generic character_animator. Only attach this to the player character —
## AI characters should use character_animator.gd directly instead, or
## they'd react to your keyboard/mouse too.

const TEST_KEY_BINDINGS := {
	KEY_1: "Idle",
	KEY_2: "Walk",
	KEY_3: "Run",
	KEY_7: "Duck",
	KEY_0: "HitReact",
	KEY_MINUS: "Death",
	KEY_EQUAL: "Wave",
	KEY_BRACKETLEFT: "Yes",
	KEY_BRACKETRIGHT: "No",
}

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var anim_name: String = TEST_KEY_BINDINGS.get(event.keycode, "")
	if anim_name == "":
		return

	if anim_name in LOOPING_ANIMATIONS:
		is_busy = false
		is_jumping = false
		landing_pending = false
		anim_player.play(anim_name)
	else:
		play_action(anim_name)

@export var attack_range: float = 1.3
@export var attack_damage: int = 10

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		_attack("Punch")
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_attack("Sword")

func _attack(anim_name: String) -> void:
	play_action(anim_name)
	_try_hit()

## Instant melee check in front of the player when an attack starts
## (not synced to the swing's actual impact frame yet, but good enough
## to get hit reactions working).
func _try_hit() -> void:
	var body := get_parent() as Node3D
	var forward := body.global_transform.basis.z.normalized()
	var origin := body.global_position + Vector3(0, 1, 0) + forward * 0.8

	var shape := SphereShape3D.new()
	shape.radius = attack_range

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), origin)
	query.exclude = [body.get_rid()]

	var space_state := get_world_3d().direct_space_state
	for result in space_state.intersect_shape(query):
		var collider = result.collider
		if collider.has_method("take_hit"):
			collider.take_hit(attack_damage)
