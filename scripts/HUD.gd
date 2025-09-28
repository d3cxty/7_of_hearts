extends CanvasLayer

@onready var player_list: VBoxContainer = $VBoxContainer
var timer_label: Label
var role_label: Label
var instruction_label: Label
var game_timer: float = 180.0
var game_active: bool = false

func _ready():
	add_to_group("hud")
	setup_minimal_ui()
	connect_to_players()

func setup_minimal_ui():
	if not player_list:
		return
	
	player_list.position = Vector2(10, 10)
	
	timer_label = Label.new()
	timer_label.text = "03:00"
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	player_list.add_child(timer_label)
	
	role_label = Label.new()
	role_label.text = "Sheep"
	role_label.add_theme_font_size_override("font_size", 16)
	role_label.add_theme_color_override("font_color", Color.CYAN)
	player_list.add_child(role_label)
	
	instruction_label = Label.new()
	instruction_label.text = "T - Swap roles with nearby player"
	instruction_label.add_theme_font_size_override("font_size", 12)
	instruction_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	player_list.add_child(instruction_label)

func start_game():
	game_active = true
	game_timer = 180.0
	# Wait a bit for all players to spawn, then update role
	await get_tree().create_timer(0.5).timeout
	connect_to_players()
	update_your_role()

func _process(delta):
	if game_active:
		game_timer -= delta
		update_timer_display()
		if game_timer <= 0:
			end_game()

func update_timer_display():
	var minutes = int(game_timer / 60)
	var seconds = int(game_timer) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_your_role():
	var local_player = get_local_player()
	if local_player:
		if local_player.role == "Wolf":
			role_label.text = "Wolf"
			role_label.add_theme_color_override("font_color", Color.RED)
		else:
			role_label.text = "Sheep"
			role_label.add_theme_color_override("font_color", Color.CYAN)
	print("Role updated to: ", role_label.text)

func get_local_player():
	var local_id = multiplayer.get_unique_id()
	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player) and player.get_multiplayer_authority() == local_id:
			return player
	return null

func connect_to_players():
	# Connect to all existing players
	for player in get_tree().get_nodes_in_group("players"):
		if not player.role_updated.is_connected(_on_role_updated):
			player.role_updated.connect(_on_role_updated)
	
	# Connect to future players by monitoring the players group
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node):
	if node.is_in_group("players") and node.has_signal("role_updated"):
		if not node.role_updated.is_connected(_on_role_updated):
			node.role_updated.connect(_on_role_updated)

func _on_role_updated(new_role: String, player_name: String):
	print("HUD received role update: ", new_role, " for player: ", player_name)
	# Only update if this is the local player's role change
	var local_player = get_local_player()
	if local_player and local_player.player_name == player_name:
		print("Updating local player role to: ", new_role)
		update_your_role()

func end_game():
	game_active = false
	timer_label.text = "GAME OVER"

func show_global_announcement(_message: String):
	pass
