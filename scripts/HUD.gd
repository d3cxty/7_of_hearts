extends CanvasLayer

@onready var player_list: VBoxContainer = $VBoxContainer

var timer_label: Label
var role_label: Label
var players_list_label: Control  # Can be either Label or RichTextLabel
var announcement_label: Label
var player_labels = {}
var game_timer: float = 180.0  # 3 minutes
var game_active: bool = false

func _ready():
	add_to_group("hud")
	setup_ui()

func setup_ui():
	if not player_list:
		print("ERROR: VBoxContainer not found!")
		return
	
	# Add padding to the container
	player_list.add_theme_constant_override("separation", 8)
	player_list.position = Vector2(20, 20)
	
	# Background panel for better visibility  
	var bg_panel = Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	bg_panel.position = Vector2(10, 10)
	bg_panel.size = Vector2(450, 350)
	# Set panel background color using style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	bg_panel.add_theme_stylebox_override("panel", style_box)
	add_child(bg_panel)
	
	# Timer with colorful background
	timer_label = Label.new()
	timer_label.text = "⏰ Time: 03:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", Color.YELLOW)
	timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	player_list.add_child(timer_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 10
	player_list.add_child(spacer1)
	
	# Your role with dynamic colors
	role_label = Label.new()
	role_label.text = "🎭 Your Role: Unknown"
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 24)
	role_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	role_label.add_theme_constant_override("shadow_offset_x", 2)
	role_label.add_theme_constant_override("shadow_offset_y", 2)
	player_list.add_child(role_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 15
	player_list.add_child(spacer2)
	
	# Players list
	var players_title = Label.new()
	players_title.text = "👥 PLAYERS IN GAME"
	players_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	players_title.add_theme_font_size_override("font_size", 18)
	players_title.add_theme_color_override("font_color", Color.CYAN)
	players_title.add_theme_color_override("font_shadow_color", Color.BLACK)
	players_title.add_theme_constant_override("shadow_offset_x", 1)
	players_title.add_theme_constant_override("shadow_offset_y", 1)
	player_list.add_child(players_title)
	
	players_list_label = RichTextLabel.new()
	players_list_label.text = "[center]Loading players...[/center]"
	players_list_label.add_theme_font_size_override("normal_font_size", 16)
	players_list_label.add_theme_color_override("default_color", Color.WHITE)
	players_list_label.fit_content = true
	players_list_label.scroll_active = false
	players_list_label.custom_minimum_size.x = 350
	players_list_label.custom_minimum_size.y = 120
	players_list_label.bbcode_enabled = true
	player_list.add_child(players_list_label)
	
	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size.y = 15
	player_list.add_child(spacer3)
	
	# Instructions with colors
	var instructions = Label.new()
	instructions.text = "🎯 Touch other players to swap roles!\n💨 Wolf has speed advantage!"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	player_list.add_child(instructions)
	
	# Spacer
	var spacer4 = Control.new()
	spacer4.custom_minimum_size.y = 20
	player_list.add_child(spacer4)
	
	# Global announcement area
	announcement_label = Label.new()
	announcement_label.text = ""
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.add_theme_font_size_override("font_size", 18)
	announcement_label.add_theme_color_override("font_color", Color.ORANGE)
	announcement_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	announcement_label.add_theme_constant_override("shadow_offset_x", 2)
	announcement_label.add_theme_constant_override("shadow_offset_y", 2)
	announcement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	announcement_label.custom_minimum_size.x = 350
	player_list.add_child(announcement_label)

func start_game():
	game_active = true
	game_timer = 180.0
	update_your_role()
	
	# Connect to all players for role updates
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_signal("role_updated") and not player.role_updated.is_connected(_on_role_updated):
			player.connect("role_updated", _on_role_updated)
	
	# Welcome announcement
	show_global_announcement("🎮 GAME STARTED! Touch others to swap roles! 🎯")
	
	# Show who is the wolf at start
	await get_tree().create_timer(2.0).timeout
	var wolf_player = null
	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player) and player.role == "Wolf":
			wolf_player = player
			break
	
	if wolf_player:
		show_global_announcement("🐺 " + wolf_player.player_name + " starts as the WOLF! 🐺")

func _on_role_updated(_role: String, _player_name: String):
	# Update display when any player's role changes
	update_your_role()

func _process(delta):
	if game_active:
		game_timer -= delta
		update_timer_display()
		
		# Update player list every second
		if fmod(game_timer, 1.0) < delta:
			update_players_list()
		
		if game_timer <= 0:
			end_game()

func update_timer_display():
	var minutes = int(game_timer / 60)
	var seconds = int(game_timer) % 60
	timer_label.text = "⏰ Time: %02d:%02d" % [minutes, seconds]
	
	# Change color based on remaining time
	if game_timer <= 30:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif game_timer <= 60:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		timer_label.add_theme_color_override("font_color", Color.YELLOW)
	
	# Countdown announcements
	var time_left = int(game_timer)
	if time_left == 60:
		show_global_announcement("⚠️ 1 MINUTE REMAINING! ⚠️")
	elif time_left == 30:
		show_global_announcement("🚨 30 SECONDS LEFT! 🚨")
	elif time_left == 10:
		show_global_announcement("🔥 10 SECONDS! FINAL COUNTDOWN! 🔥")
	elif time_left <= 5 and time_left > 0:
		show_global_announcement("💥 " + str(time_left) + "! 💥")

func update_your_role():
	var local_player = get_local_player()
	if local_player:
		if local_player.role == "Wolf":
			role_label.text = "🐺 Your Role: WOLF"
			role_label.add_theme_color_override("font_color", Color.RED)
		else:
			role_label.text = "🐑 Your Role: SHEEP"  
			role_label.add_theme_color_override("font_color", Color.CYAN)
	
	# Update player list
	update_players_list()

func get_local_player():
	var local_id = multiplayer.get_unique_id()
	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player) and player.get_multiplayer_authority() == local_id:
			return player
	return null

func update_players_list():
	if not players_list_label:
		return
		
	var player_info = "[center]"
	var players = get_tree().get_nodes_in_group("players")
	
	for player in players:
		if is_instance_valid(player):
			var role_icon = "🐺" if player.role == "Wolf" else "🐑"
			var role_color = "[color=red]" if player.role == "Wolf" else "[color=cyan]"
			player_info += role_icon + " " + role_color + player.player_name + "[/color]\n"
	
	player_info += "[/center]"
	
	if players.size() == 0:
		players_list_label.text = "[center]No players found[/center]"
	else:
		players_list_label.text = player_info

func show_global_announcement(message: String):
	if not announcement_label:
		return
		
	print("📢 GLOBAL: ", message)
	announcement_label.text = "📢 " + message
	announcement_label.add_theme_color_override("font_color", Color.YELLOW)
	
	# Flash effect
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_method(flash_announcement, 0.0, 1.0, 0.3)
	
	# Clear announcement after 5 seconds
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(announcement_label):
		announcement_label.text = ""

func flash_announcement(value: float):
	if announcement_label:
		var alpha = 0.5 + (sin(value * PI * 2) * 0.5)
		announcement_label.modulate = Color(1, 1, 1, alpha)

func end_game():
	game_active = false
	timer_label.text = "🏁 GAME OVER!"
	timer_label.add_theme_color_override("font_color", Color.RED)
	
	# Find winner
	var wolf = null
	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player) and player.role == "Wolf":
			wolf = player
			break
	
	if wolf:
		role_label.text = "🏆 " + wolf.player_name + " (🐺 Wolf) WINS!"
		role_label.add_theme_color_override("font_color", Color.GOLD)
		show_global_announcement("🏆 " + wolf.player_name + " (WOLF) WINS THE GAME! 🏆")
	else:
		role_label.text = "🏁 Game Over!"
		show_global_announcement("🏁 GAME OVER! 🏁")
	
	# Return to menu after 8 seconds
	await get_tree().create_timer(8.0).timeout
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.show_start_menu()
