extends Node

@onready var start_menu = $StartMenu
@onready var lobby_menu = $LobbyMenu
@onready var hud = $HUD
@onready var game_world = $GameWorld
@onready var players_container = $PlayersContainer

var multiplayer_peer = ENetMultiplayerPeer.new()
var player_scene = preload("res://scenes/player.tscn")
var players_in_lobby = {}
var is_host = false
var discovery_peers = []

func _ready():
	add_to_group("main")
	show_start_menu()

func show_start_menu():
	start_menu.visible = true
	lobby_menu.visible = false
	hud.visible = false
	game_world.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func show_lobby():
	start_menu.visible = false
	lobby_menu.visible = true
	hud.visible = false
	game_world.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func show_game():
	start_menu.visible = false
	lobby_menu.visible = false
	hud.visible = true
	game_world.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func host_game(player_name: String):
	print("Creating lobby as host: ", player_name)
	is_host = true
	
	multiplayer_peer.create_server(7000, 4)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Add self to lobby
	players_in_lobby[1] = {"name": player_name, "ready": false}
	
	# Show host IP for others to join
	var host_ip = get_local_ip()
	print("🌐 Host IP: ", host_ip)
	print("📢 Tell others to join: ", host_ip)
	
	show_lobby()
	update_lobby_display()

func join_game(ip: String, player_name: String):
	print("Joining lobby at ", ip, " as: ", player_name)
	is_host = false
	
	multiplayer_peer.create_client(ip, 7000)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.connected_to_server.connect(_on_connected_to_server.bind(player_name))
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connected_to_server(player_name: String):
	print("Connected to server!")
	show_lobby()
	rpc_id(1, "add_player_to_lobby", multiplayer.get_unique_id(), player_name)

func _on_connection_failed():
	print("Connection failed!")
	# Show error message
	var start_menu_node = get_tree().get_first_node_in_group("start_menu")
	if start_menu_node and start_menu_node.has_method("show_error"):
		start_menu_node.show_error("Failed to connect to host!\nCheck IP address and try again.")
	show_start_menu()

# Simple LAN game discovery
func discover_lan_games() -> Array:
	var found_games = []
	
	# Get local IP range
	var local_ips = get_local_ip_range()
	
	for ip in local_ips:
		if can_connect_to_host(ip):
			found_games.append({
				"ip": ip,
				"name": "Game at " + ip
			})
	
	return found_games

func get_local_ip_range() -> Array:
	var ips = []
	
	# Common local IP ranges to scan
	var base_ips = [
		"192.168.1.",
		"192.168.0.",
		"10.0.0.",
		"172.16.0."
	]
	
	for base in base_ips:
		for i in range(1, 255):  # Scan common range
			ips.append(base + str(i))
			if ips.size() > 20:  # Limit scan for performance
				break
	
	# Always include localhost
	ips.append("127.0.0.1")
	
	return ips

func can_connect_to_host(ip: String) -> bool:
	# Simple check - in a real implementation you'd do actual network discovery
	# For now, just return true for localhost and some common IPs
	return ip == "127.0.0.1" or ip == "192.168.1.100"

func get_local_ip() -> String:
	# Get the local IP address
	var ip_addresses = IP.get_local_addresses()
	for ip in ip_addresses:
		# Return first non-localhost IP
		if ip != "127.0.0.1" and ip.begins_with("192.168"):
			return ip
	return "127.0.0.1"  # Fallback to localhost

func _on_peer_connected(id: int):
	print("Peer connected: ", id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	if players_in_lobby.has(id):
		players_in_lobby.erase(id)
		rpc("update_lobby_players", players_in_lobby)

@rpc("any_peer", "call_local")
func add_player_to_lobby(id: int, player_name: String):
	players_in_lobby[id] = {"name": player_name, "ready": false}
	rpc("update_lobby_players", players_in_lobby)

@rpc("any_peer", "call_local")
func update_lobby_players(lobby_data: Dictionary):
	players_in_lobby = lobby_data
	update_lobby_display()

@rpc("any_peer", "call_local")
func player_ready_status(id: int, is_ready: bool):
	if players_in_lobby.has(id):
		players_in_lobby[id]["ready"] = is_ready
		rpc("update_lobby_players", players_in_lobby)

@rpc("any_peer", "call_local")
func start_game_from_lobby():
	print("Starting game from lobby!")
	show_game()
	
	# Spawn all players
	var wolf_assigned = false
	for id in players_in_lobby.keys():
		var player_name = players_in_lobby[id]["name"]
		var role = "Sheep"
		
		# First player becomes Wolf
		if not wolf_assigned:
			role = "Wolf"
			wolf_assigned = true
		
		spawn_player(id, player_name, role)
	
	# Start the HUD
	if hud.has_method("start_game"):
		hud.start_game()

func update_lobby_display():
	if lobby_menu.has_method("update_player_list"):
		lobby_menu.update_player_list(players_in_lobby)

func spawn_player(id: int, player_name: String, role: String):
	if not players_container:
		print("ERROR: PlayersContainer not found!")
		return
		
	var player_instance = player_scene.instantiate()
	player_instance.name = "Player" + str(id)
	player_instance.set_multiplayer_authority(id)
	player_instance.player_name = player_name
	player_instance.role = role
	player_instance.add_to_group("players")
	
	# Random spawn position
	player_instance.position = Vector3(randf_range(-3, 3), 1, randf_range(-3, 3))
	
	players_container.add_child(player_instance)
	print("Spawned: ", player_name, " as ", role)

func toggle_ready():
	var my_id = multiplayer.get_unique_id()
	if players_in_lobby.has(my_id):
		var current_ready = players_in_lobby[my_id]["ready"]
		rpc("player_ready_status", my_id, not current_ready)

func start_game_if_host():
	if not is_host:
		return
		
	# Check if all players are ready and we have at least 2 players
	if players_in_lobby.size() < 2:
		print("Need at least 2 players to start")
		return
		
	for id in players_in_lobby.keys():
		if not players_in_lobby[id]["ready"]:
			print("Not all players are ready")
			return
	
	# All conditions met, start the game
	rpc("start_game_from_lobby")
