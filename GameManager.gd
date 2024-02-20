extends Node

var players = {}

signal add_to_player_score(peer_id: int, value: float)
signal updated_player_score(peer_id: int, new_score: int)

signal damge_player(peer_id: int, value: float)
signal player_took_damge(peer_id: int, new_health: float)

signal fire_bullet(angle, position)

func _ready():
	add_to_player_score.connect(_on_add_to_player_score)
	damge_player.connect(_on_damge_player)

func _on_add_to_player_score(peer_id: int, value: float):
	if peer_id > 0:
		players[peer_id].score += value
		updated_player_score.emit(peer_id, players[peer_id].score)
		
func _on_damge_player(peer_id, value):
	if peer_id > 0:
		players[peer_id].health -= value
		player_took_damge.emit(peer_id, players[peer_id].health)
