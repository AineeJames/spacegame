extends Control

@onready var UserNameLineEdit: LineEdit = $ButtonsContainer/UserNameInput/UserNameLineEdit
@onready var HostButton: Button = $ButtonsContainer/HostButton
@onready var JoinButton: Button = $ButtonsContainer/JoinButton
@onready var StartButton: Button = $ButtonsContainer/StartButton

@export var ADDRESS: String = "127.0.0.1"
@export var PORT: int = 8910
@export var MAX_CLIENTS: int = 2
@export var COMPRESSION = ENetConnection.COMPRESS_RANGE_CODER

var peer

func _ready():
	UserNameLineEdit.text = "Guest" + str(randi_range(0, 1024))
	
	StartButton.visible = false
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_peer_connected(player_id):
	print("Player connected: %s" % player_id)

func _on_peer_disconnected(player_id):
	print("Player disconnected: %s" % player_id)

func _on_connected_to_server():
	print("Connected to server.")
	send_player_info.rpc_id(1, UserNameLineEdit.text, multiplayer.get_unique_id())
	
func _on_connection_failed():
	print("Connection failed!")
	
func _on_host_button_pressed():
	JoinButton.visible = false
	StartButton.visible = true
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Could not create server: %s" % error)
		return
	peer.get_host().compress(COMPRESSION)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Created host, waiting for players.")
	
	send_player_info(UserNameLineEdit.text, multiplayer.get_unique_id())

func _on_join_button_pressed():
	HostButton.visible = false
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ADDRESS, PORT)
	if error != OK:
		print("Could not joing server: %s" % error)
		return
	peer.get_host().compress(COMPRESSION)
	
	multiplayer.set_multiplayer_peer(peer)

@rpc("any_peer")
func send_player_info(user_name, player_id):
	if !GameManager.players.has(player_id):
		GameManager.players[player_id] = {
			"user_name": user_name,
			"player_id": player_id,
			"score": 0.0,
			"health": 100.0
		}
	
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_info.rpc(GameManager.players[i].user_name, i)

@rpc("any_peer", "call_local")
func start_game():
	var game = load("res://Game.tscn").instantiate()
	get_tree().root.add_child(game)
	hide()

func _on_start_button_pressed():
	start_game.rpc()
	
