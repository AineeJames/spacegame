extends Area2D

@export var BULLET_SPEED: float = 500.0

@onready var Collision: CollisionShape2D = $CollisionShape2D

var velocity
var peer_id

func _ready():
	Collision.disabled = true
	modulate.a = 0.25

func _process(delta):
	position += velocity * BULLET_SPEED * delta

func _on_body_entered(body):
	if body.is_in_group("BulletGroup"):
		body.queue_free()
		queue_free()
	if body.is_in_group("PlayerGroup"):
		GameManager.damge_player.emit(body.uuid, 10.0, velocity.angle())
		queue_free()

func _on_deadly_timer_timeout():
	Collision.disabled = false
	modulate.a = 1.0
