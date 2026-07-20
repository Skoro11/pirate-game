extends Label

var player: Node3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if player and is_instance_valid(player):
		text = "Health: %d / %d" % [player.health, player.max_health]
