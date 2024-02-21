extends Node2D

@export var PlayerScene: PackedScene
@export var NUM_ASTEROIDS: int = 200
@export var ASTEROID_IMAGES: Array[Texture2D]
@export var NUM_PLANETS: int = 50
@export var PLANET_IMAGES: Array[Texture2D]

@onready var PlanetsParallax1 = $ParallaxBackground/PlanetsParallaxLayer1
@onready var PlanetsParallax2 = $ParallaxBackground/PlanetsParallaxLayer2
@onready var PlanetsParallax3 = $ParallaxBackground/PlanetsParallaxLayer3
@onready var AsteroidsParallax1 = $ParallaxBackground/AsteroidsParallaxLayer1
@onready var AsteroidsParallax2 = $ParallaxBackground/AsteroidsParallaxLayer2

func get_random_vec2(minx, maxx, miny, maxy):
	return Vector2(randf_range(minx, maxx), randf_range(miny, maxy))

func _ready():
	
	for i in range(NUM_ASTEROIDS):
		var asteroid = Sprite2D.new()
		asteroid.global_position = get_random_vec2(0.0, 10000.0, 0.0, 10000.0)
		asteroid.scale = Vector2.ONE * randf_range(0.25, 0.5)
		asteroid.rotation_degrees = randf_range(0.0, 360.0)
		asteroid.texture = ASTEROID_IMAGES.pick_random()
		match randi_range(1, 2):
			1: AsteroidsParallax1.add_child(asteroid)
			2: AsteroidsParallax2.add_child(asteroid)
		
	for i in range(NUM_PLANETS):
		var planet = Sprite2D.new()
		planet.global_position = get_random_vec2(0.0, 10000.0, 0.0, 10000.0)
		planet.scale = Vector2.ONE * randf_range(0.6, 0.8)
		planet.rotation_degrees = randf_range(0.0, 360.0)
		planet.texture = PLANET_IMAGES.pick_random()
		match randi_range(1, 2):
			1: PlanetsParallax1.add_child(planet)
			2: PlanetsParallax2.add_child(planet)
			3: PlanetsParallax3.add_child(planet)
	
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
