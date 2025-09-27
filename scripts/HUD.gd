extends CanvasLayer

@onready var player_list: VBoxContainer = $VBoxContainer

var timer_label: Label
var role_label: Label
var player_labels = {}
var game_timer: float = 180.0  # 3 minutes
var game_active: bool = false

func _ready():
	setup_ui()

func setup_ui():
	if not player_list:
		print("ERROR: VBoxContainer not found!")
		return
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "Time: 03:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 24)
	player_list.add_child(timer_label)
	
	# Your role
	role_label = Label.new()
	role_label.text = "Your Role: Unknown"
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 20)
	player_list.add_child(role_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Touch other players to swap roles! Wolf has speed advantage!"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 16)
	player_list.add_child(instructions)

func start_game():
	game_active = true
	game_timer = 180.0
	update_your_role()
	
	# Connect to all players for role updates
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_signal("role_updated") and not player.role_updated.is_connected(_on_role_updated):
			player.connect("role_updated", _on_role_updated)

func _on_role_updated(_role: String, _player_name: String):
	# Update display when any player's role changes
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
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

func update_your_role():
	var local_player = get_local_player()
	if local_player:
		role_label.text = "Your Role: " + local_player.role
		if local_player.role == "Wolf":
			role_label.add_theme_color_override("font_color", Color.RED)
			# Show wolf advantage info
			var wolf_info = Label.new()
			wolf_info.text = "Wolf Speed Boost: +25%"
			wolf_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			wolf_info.add_theme_font_size_override("font_size", 14)
			wolf_info.add_theme_color_override("font_color", Color.YELLOW)
		else:
			role_label.add_theme_color_override("font_color", Color.CYAN)

func get_local_player():
	var local_id = multiplayer.get_unique_id()
	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player) and player.get_multiplayer_authority() == local_id:
			return player
	return null

func end_game():
	game_active = false
	timer_label.text = "GAME OVER!"
	
	# Find winner
	var wolf = null
	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player) and player.role == "Wolf":
			wolf = player
			break
	
	if wolf:
		role_label.text = wolf.player_name + " (Wolf) WINS!"
	else:
		role_label.text = "Game Over!"
	
	# Return to menu after 5 seconds
	await get_tree().create_timer(5.0).timeout
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.show_start_menu()
