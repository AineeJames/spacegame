extends Node2D

@export var PlayerScene: PackedScene

@onready var BulletSpawner: MultiplayerSpawner = $BulletSpawner
@onready var Bullets: Node2D = $Bullets

@onready var Bullet: PackedScene = load("res://bullet.tscn")

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
		
	GameManager.fire_bullet.connect(_on_fire_bullet)
		
func _on_fire_bullet(bullet_angle, position):
	
	var bullet: Area2D = Bullet.instantiate()
	bullet.global_position = position
	bullet.velocity = Vector2(cos(bullet_angle), sin(bullet_angle)).normalized()
	Bullets.add_child(bullet)
	#BulletSpawner.add_spawnable_scene("res://bullet.tscn")
	#BulletSpawner.spawn({"velocity": velocity, "global_position": position})
	
