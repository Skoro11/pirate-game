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

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		_attack("Punch")
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_attack("Sword")
