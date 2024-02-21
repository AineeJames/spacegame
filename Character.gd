extends RigidBody2D

@export var SHOOT_BUMP_AMOUNT: float = 100.0
@export var ENEMY_ARROW_START: float = 50.0
@export var ENEMY_ARROW_END: float = 100.0

@export_category("Multiplayer Syncing")
@export_range(0.0, 1.0, 0.01) var SYNC_LERP_WEIGHT = 0.5
@export_range(0.0, 5.0, 0.01) var SYNC_REPLICATION_INTERVAL = 0.0
@export_range(0.0, 5.0, 0.01) var SYNC_DELTA_INTERVAL = 0.0

@onready var Bullet: PackedScene = load("res://bullet.tscn")
@onready var DamageParticles: PackedScene = load("res://scenes/particles/damage_particles.tscn")

@onready var DebugLine: Line2D = $DebugLine
@onready var Syncronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var Camera: Camera2D = $Camera2D
@onready var NameTag: Label = $NameTag
@onready var HealthBar: ProgressBar = $HealthBar

@export var user_name: String = "Guest"
 
var sync_pos = Vector2.ZERO
var sync_rot = 0
var sync_linear_vel = Vector2.ZERO
var sync_angular_vel = 0

var rng
var uuid
var prev_scale
var enemy_arrows = {}

func is_authority():
	return multiplayer.get_unique_id() == uuid

func _ready():
	uuid = name.to_int()
	
	NameTag.text = user_name
	prev_scale = $Sprite2D.scale
	
	Syncronizer.replication_interval = SYNC_REPLICATION_INTERVAL
	Syncronizer.delta_interval = SYNC_DELTA_INTERVAL
	Syncronizer.set_multiplayer_authority(str(name).to_int())
	
	if is_authority():
		Camera.make_current()
		var title = "UUID: " + str(uuid)
		title += " USER_NAME: " + GameManager.players[uuid].user_name
		DisplayServer.window_set_title(title)
		
	GameManager.player_took_damge.connect(_on_player_took_damage)
	
	rng = RandomNumberGenerator.new()
	rng.seed = multiplayer.get_unique_id()

func _physics_process(delta):
	GameManager.update_player_position(uuid, global_position)
	
	if is_authority():
		
		HealthBar.value = GameManager.players[uuid].health
		sync_pos = global_position
		sync_linear_vel = linear_velocity
		sync_angular_vel = angular_velocity
		sync_rot = rotation
		
		for peer in multiplayer.get_peers():
			if peer != uuid:
				hint_nametag_dir(peer)

	else:
		global_position = global_position.lerp(sync_pos, SYNC_LERP_WEIGHT)
		rotation = lerpf(rotation, sync_rot, SYNC_LERP_WEIGHT)
		linear_velocity = linear_velocity.lerp(sync_linear_vel, SYNC_LERP_WEIGHT)
		angular_velocity = lerpf(angular_velocity, sync_angular_vel, SYNC_LERP_WEIGHT)

func hint_nametag_dir(peer_id):
	var enemy_player_pos = Vector2(GameManager.players[peer_id].pos_x, GameManager.players[peer_id].pos_y)
	var relative_pos = enemy_player_pos - global_position
	
	var screen_size = get_viewport_rect().size
	var third_screen = screen_size / 3
	
	if relative_pos.length() > third_screen.length():
		var arrow_angle = relative_pos.angle() - rotation
		$DebugLine.clear_points()
		$DebugLine.add_point(Vector2(ENEMY_ARROW_START*cos(arrow_angle), ENEMY_ARROW_START*sin(arrow_angle)))
		$DebugLine.add_point(Vector2(ENEMY_ARROW_END*cos(arrow_angle), ENEMY_ARROW_END*sin(arrow_angle)))
		
	else:
		$DebugLine.clear_points()

	
func _input(event):
	
	if is_authority():
		if Input.is_action_just_pressed("fire"):
			var bump_angle = get_local_mouse_position().angle() + PI + rotation
			var bump_velocity = Vector2(SHOOT_BUMP_AMOUNT*cos(bump_angle), SHOOT_BUMP_AMOUNT*sin(bump_angle))
			linear_velocity += bump_velocity
		
			fire_bullet.rpc(uuid, bump_angle + PI, linear_velocity)
			
		if Input.is_action_just_pressed("zoom_in"):
			$Camera2D.zoom += Vector2.ONE * 0.01
		if Input.is_action_just_pressed("zoom_out"):
			$Camera2D.zoom -= Vector2.ONE * 0.01


@rpc("any_peer", "call_local")
func fire_bullet(peer_id, bullet_angle, vel):
	var bullet: Area2D = Bullet.instantiate()
	bullet.peer_id = peer_id
	bullet.global_position = global_position
	bullet.velocity = Vector2(cos(bullet_angle), sin(bullet_angle)).normalized()
	get_tree().root.add_child(bullet)
	
	
func _on_player_took_damage(peer_id, new_health, bump_angle):
	if peer_id == uuid:
		var bump_velocity = Vector2(SHOOT_BUMP_AMOUNT*cos(bump_angle), SHOOT_BUMP_AMOUNT*sin(bump_angle))
		linear_velocity += bump_velocity
		
		HealthBar.value = new_health
		
		var particles = DamageParticles.instantiate()
		particles.global_position = global_position
		particles.emitting = false
		particles.emitting = true
		get_tree().root.add_child(particles)
		
		var tween: Tween = get_tree().create_tween()
		tween.parallel().tween_property($Sprite2D, "modulate", Colors.ENEMY_DAMAGE, 0.1).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property($Sprite2D, "scale", Vector2.ZERO, 0.1).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			tween = get_tree().create_tween()
			tween.parallel().tween_property($Sprite2D, "modulate", Colors.WHITE, 0.2).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property($Sprite2D, "scale", prev_scale, 0.2).set_ease(Tween.EASE_OUT)
		)
	
