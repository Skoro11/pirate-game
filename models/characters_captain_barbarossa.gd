extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer

const LOOPING_ANIMATIONS := ["Idle", "Walk", "Run", "Jump_Idle"]

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

# True while a one-shot animation (attack, jump takeoff/landing, etc.) is
# playing, so movement doesn't stomp it back to Idle/Walk/Run mid-play.
var is_busy := false
# True for the whole time Barbossa is airborne from a jump: horizontal
# input is ignored (momentum carries) until he lands.
var is_jumping := false
# True once the physics body has actually touched down while an attack (or
# other one-shot action) started mid-air is still playing. Landing is
# deferred until that animation finishes instead of cutting it off.
var landing_pending := false

func _ready() -> void:
	for anim_name in LOOPING_ANIMATIONS:
		var anim := anim_player.get_animation(anim_name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
	anim_player.animation_finished.connect(_on_animation_finished)
	anim_player.play("Idle")

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
		play_action("Punch")
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		play_action("Sword")

func play_action(anim_name: String) -> void:
	is_busy = true
	anim_player.play(anim_name)

var is_locomotion_reversed := false

func play_locomotion(anim_name: String, reverse: bool = false) -> void:
	if is_busy:
		return
	if anim_player.current_animation == anim_name and is_locomotion_reversed == reverse:
		return
	is_locomotion_reversed = reverse
	anim_player.play(anim_name, -1, -1.0 if reverse else 1.0)

## Called by the physics body the moment it launches off the ground.
func start_jump() -> void:
	is_busy = true
	is_jumping = true
	anim_player.play("Jump")

## Called by the physics body the moment it touches back down.
func land() -> void:
	if not is_jumping:
		return
	if anim_player.current_animation == "Jump_Idle":
		anim_player.play("Jump_Land")
	else:
		# An attack (or other action) started mid-air is still playing:
		# let it finish instead of cutting it off with Jump_Land.
		landing_pending = true

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Jump":
		anim_player.play("Jump_Idle")
		return

	if anim_name == "Jump_Land":
		is_busy = false
		is_jumping = false
		landing_pending = false
		anim_player.play("Idle")
		return

	# Any other one-shot animation (attack, duck, wave, etc.) finished.
	if is_jumping:
		if landing_pending:
			landing_pending = false
			is_busy = false
			is_jumping = false
			anim_player.play("Idle")
		else:
			# Still airborne, waiting to land.
			anim_player.play("Jump_Idle")
		return

	if is_busy:
		is_busy = false
		anim_player.play("Idle")
