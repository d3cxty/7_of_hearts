extends Node

@onready var start_menu = $StartMenu
@onready var hud = $HUD  # Change this to match your actual node name
@onready var game_world = $GameWorld
@onready var players_container = $PlayersContainer  # Change this to match your actual node name

var multiplayer_peer = ENetMultiplayerPeer.new()
var player_scene = preload("res://scenes/player.tscn")  # Adjust path as needed

func _ready():
	add_to_group("main")
	# Verify nodes exist before using them
	if not start_menu:
		print("ERROR: StartMenu node not found!")
	if not hud:
		print("ERROR: HUD node not found!")
	if not game_world:
		print("ERROR: GameWorld node not found!")
	if not players_container:
		print("ERROR: PlayersContainer node not found!")
	
	# Initially show only the start menu
	show_start_menu()

func show_start_menu():
	if start_menu:
		start_menu.visible = true
	if hud:
		hud.visible = false
	if game_world:
		game_world.visible = false
	# Don't capture mouse in menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_start_menu():
	if start_menu:
		start_menu.visible = false
	if hud:
		hud.visible = true
	if game_world:
		game_world.visible = true
	# Capture mouse for game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func host_game(player_name: String):
	print("Hosting game as: ", player_name)
	multiplayer_peer.create_server(7000, 4)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Hide start menu and show game
	hide_start_menu()
	
	# Spawn the host player
	spawn_player(1, player_name)
	
	# Start the game timer
	if hud and hud.has_method("start_game"):
		hud.start_game()

func join_game(ip: String, player_name: String):
	print("Joining game at ", ip, " as: ", player_name)
	multiplayer_peer.create_client(ip, 7000)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.connected_to_server.connect(_on_connected_to_server.bind(player_name))
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connected_to_server(player_name: String):
	print("Connected to server!")
	hide_start_menu()
	# Request the server to spawn our player
	rpc("request_spawn_player", player_name)

func _on_connection_failed():
	print("Connection failed!")
	show_start_menu()

func _on_peer_connected(id: int):
	print("Peer connected: ", id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	# Remove the disconnected player
	if players_container and players_container.has_node("Player" + str(id)):
		players_container.get_node("Player" + str(id)).queue_free()

func spawn_player(id: int, player_name: String):
	if not players_container:
		print("ERROR: PlayersContainer not found, cannot spawn player!")
		return
		
	var player_instance = player_scene.instantiate()
	player_instance.name = "Player" + str(id)
	player_instance.set_multiplayer_authority(id)
	player_instance.player_name = player_name
	player_instance.add_to_group("players")
	
	# Set spawn position (adjust as needed)
	player_instance.position = Vector3(0, 1, 0)
	
	players_container.add_child(player_instance)
	print("Spawned player: ", player_name, " with ID: ", id)

@rpc("any_peer", "call_local")
func request_spawn_player(player_name: String):
	var sender_id = multiplayer.get_remote_sender_id()
	spawn_player(sender_id, player_name)
