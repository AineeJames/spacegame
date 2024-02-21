extends Node2D

@export var PlayerScene: PackedScene

func _ready():
	var index = 0
	for i in GameManager.players:
		var current_player = PlayerScene.instantiate()
		current_player.user_name = GameManager.players[i].user_name
		current_player.name = str(GameManager.players[i].player_id)
		add_child(current_player)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				current_player.global_position = spawn.global_position
		index += 1
