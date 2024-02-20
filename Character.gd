extends RigidBody2D

@export var SHOOT_BUMP_AMOUNT: float = 100.0

@export_category("Multiplayer Syncing")
@export_range(0.0, 1.0, 0.01) var SYNC_LERP_WEIGHT = 0.5
@export_range(0.0, 5.0, 0.01) var SYNC_REPLICATION_INTERVAL = 0.0
@export_range(0.0, 5.0, 0.01) var SYNC_DELTA_INTERVAL = 0.0

@onready var Bullet: PackedScene = load("res://bullet.tscn")

@onready var DebugLine: Line2D = $DebugLine
@onready var Syncronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var Camera: Camera2D = $Camera2D
@onready var NameTag: Label = $NameTag
@onready var ScoreLabel: Label = $ScoreLabel
@onready var FreeScoreTimer: Timer = $FreeScoreTimer
@onready var HealthBar: ProgressBar = $HealthBar

@export var user_name: String = "Guest"
 
var sync_pos = Vector2.ZERO
var sync_rot = 0
var sync_linear_vel = Vector2.ZERO
var sync_angular_vel = 0

var rng
var uuid

func is_authority():
	return Syncronizer.get_multiplayer_authority() == multiplayer.get_unique_id()

func _ready():
	
	uuid = multiplayer.get_unique_id()
	
	var title = "UUID: " + str(multiplayer.get_unique_id())
	title += " USER_NAME: " + GameManager.players[multiplayer.get_unique_id()].user_name
	DisplayServer.window_set_title(title)
	
	NameTag.text = user_name
	
	Syncronizer.replication_interval = SYNC_REPLICATION_INTERVAL
	Syncronizer.delta_interval = SYNC_DELTA_INTERVAL
	Syncronizer.set_multiplayer_authority(str(name).to_int())
	
	if is_authority():
		Camera.make_current()
		
	GameManager.updated_player_score.connect(_on_updated_player_score)
	GameManager.player_took_damge.connect(_on_player_took_damage)
	
	rng = RandomNumberGenerator.new()
	rng.seed = multiplayer.get_unique_id()

func _physics_process(delta):
	if is_authority():
		HealthBar.value = GameManager.players[uuid].health
		sync_pos = global_position
		sync_linear_vel = linear_velocity
		sync_angular_vel = angular_velocity
		sync_rot = rotation
		
		DebugLine.clear_points()
		DebugLine.add_point(Vector2.ZERO)
		DebugLine.add_point(get_local_mouse_position())
		
	else:
		global_position = global_position.lerp(sync_pos, SYNC_LERP_WEIGHT)
		rotation = lerpf(rotation, sync_rot, SYNC_LERP_WEIGHT)
		linear_velocity = linear_velocity.lerp(sync_linear_vel, SYNC_LERP_WEIGHT)
		angular_velocity = lerpf(angular_velocity, sync_angular_vel, SYNC_LERP_WEIGHT)
	
func _input(event):
	if is_authority():
		if Input.is_action_just_pressed("fire"):
			var bump_angle = get_local_mouse_position().angle() + PI + rotation
			var bump_velocity = Vector2(SHOOT_BUMP_AMOUNT*cos(bump_angle), SHOOT_BUMP_AMOUNT*sin(bump_angle))
			linear_velocity += bump_velocity
			
			#shoot_bullet.rpc(bump_angle + PI)
			GameManager.fire_bullet.emit(bump_angle + PI, global_position)

func _on_updated_player_score(peer_id, new_score):
	if uuid == peer_id:
		ScoreLabel.text = "Score: " + str(new_score)

func _on_free_score_timer_timeout():
	if is_authority():
		GameManager.add_to_player_score.emit(multiplayer.get_unique_id(), 1)
		var random_delay = rng.randf_range(1.0, 3.0)
		FreeScoreTimer.start(random_delay)
		
@rpc("any_peer", "call_local", "reliable")
func shoot_bullet(bullet_angle):
	var bullet: Area2D = Bullet.instantiate()
	bullet.velocity = Vector2(cos(bullet_angle), sin(bullet_angle)).normalized()
	bullet.global_position = global_position
	get_tree().root.add_child(bullet)
	
func _on_player_took_damage(peer_id, new_health):
	if uuid == peer_id:
		print("{0}'s health is now {1}".format([peer_id, new_health]))
		HealthBar.value = new_health
