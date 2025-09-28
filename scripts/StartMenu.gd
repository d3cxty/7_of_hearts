extends CanvasLayer

@onready var name_input: LineEdit = $CenterContainer/VBoxContainer/NameInput
@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var join_game_button: Button = $CenterContainer/VBoxContainer/JoinGameButton

func _ready():
	add_to_group("start_menu")
	setup_hide_and_seek_theme()
	
	print("=== StartMenu Debug ===")
	print("name_input exists: ", name_input != null)
	print("new_game_button exists: ", new_game_button != null)
	print("join_game_button exists: ", join_game_button != null)
	print("======================")
	
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
		print("Connected NEW GAME button")
	else:
		print("ERROR: NewGameButton not found!")
		
	if join_game_button:
		join_game_button.pressed.connect(_on_join_game_pressed)
		print("Connected JOIN GAME button")
	else:
		print("ERROR: JoinGameButton not found!")
		
	if name_input and name_input.text == "":
		name_input.text = "Player" + str(randi() % 100)

func setup_hide_and_seek_theme():
	# Apply HIDE AND SEEK horror theme styling
	var dark_bg = Color(0.08, 0.05, 0.03, 0.95)  # Dark brown/black
	var rust_orange = Color(0.8, 0.4, 0.1, 1.0)  # Rusty orange
	var blood_red = Color(0.6, 0.1, 0.1, 1.0)    # Dark red
	var worn_text = Color(0.9, 0.8, 0.6, 1.0)    # Aged paper color
	
	# Style buttons with horror theme
	if new_game_button:
		style_horror_button(new_game_button, "🎯 START HUNT", rust_orange)
		
	if join_game_button:
		style_horror_button(join_game_button, "👥 JOIN HUNT", blood_red)
	
	# Style name input
	if name_input:
		name_input.placeholder_text = "Enter Hunter Name..."
		var input_style = StyleBoxFlat.new()
		input_style.bg_color = Color(0.15, 0.1, 0.05, 0.8)
		input_style.border_width_left = 2
		input_style.border_width_right = 2
		input_style.border_width_top = 2
		input_style.border_width_bottom = 2
		input_style.border_color = rust_orange
		input_style.corner_radius_top_left = 8
		input_style.corner_radius_top_right = 8
		input_style.corner_radius_bottom_left = 8
		input_style.corner_radius_bottom_right = 8
		name_input.add_theme_stylebox_override("normal", input_style)
		name_input.add_theme_color_override("font_color", worn_text)

func style_horror_button(button: Button, text: String, accent_color: Color):
	button.text = text
	
	# Normal state - dark with accent border
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.08, 0.05, 0.9)
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = accent_color
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12
	
	# Hover state - lighter with glow effect
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = accent_color * 0.3
	hover_style.border_width_left = 4
	hover_style.border_width_right = 4
	hover_style.border_width_top = 4
	hover_style.border_width_bottom = 4
	hover_style.border_color = accent_color
	hover_style.corner_radius_top_left = 12
	hover_style.corner_radius_top_right = 12
	hover_style.corner_radius_bottom_left = 12
	hover_style.corner_radius_bottom_right = 12
	
	# Pressed state - darker with inset effect
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = accent_color * 0.6
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = accent_color
	pressed_style.corner_radius_top_left = 12
	pressed_style.corner_radius_top_right = 12
	pressed_style.corner_radius_bottom_left = 12
	pressed_style.corner_radius_bottom_right = 12
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.7, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))

func _on_new_game_pressed():
	print("NEW GAME button pressed!")
	var player_name = name_input.text if name_input else "DefaultPlayer"
	print("Player name: ", player_name)
	
	var main_nodes = get_tree().get_nodes_in_group("main")
	print("Found main nodes: ", main_nodes.size())
	
	if main_nodes.size() > 0:
		var main = main_nodes[0]
		main.host_game(player_name)
		hide_menu()
	else:
		print("ERROR: No main node found!")

func _on_join_game_pressed():
	print("JOIN GAME button pressed!")
	show_join_options()

func show_join_options():
	# Create a popup for join options
	var popup = AcceptDialog.new()
	popup.title = "Join Game"
	popup.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = "🎮 How do you want to join?"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(title_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 20
	vbox.add_child(spacer1)
	
	# Option 1: Join by IP
	var ip_button = Button.new()
	ip_button.text = "🌐 Join by IP Address"
	ip_button.custom_minimum_size.y = 50
	vbox.add_child(ip_button)
	
	# Option 2: Scan LAN
	var lan_button = Button.new()
	lan_button.text = "🔍 Scan for Local Games"
	lan_button.custom_minimum_size.y = 50
	vbox.add_child(lan_button)
	
	# Option 3: Quick Join Localhost
	var localhost_button = Button.new()
	localhost_button.text = "🏠 Join Localhost (Testing)"
	localhost_button.custom_minimum_size.y = 50
	vbox.add_child(localhost_button)
	
	# Connect buttons
	ip_button.pressed.connect(show_ip_input.bind(popup))
	lan_button.pressed.connect(scan_for_games.bind(popup))
	localhost_button.pressed.connect(join_localhost.bind(popup))
	
	add_child(popup)
	popup.popup_centered()

func show_ip_input(parent_popup):
	parent_popup.queue_free()
	
	var popup = AcceptDialog.new()
	popup.title = "Join by IP"
	popup.size = Vector2(350, 200)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var label = Label.new()
	label.text = "🌐 Enter the host's IP address:"
	label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	vbox.add_child(label)
	
	var ip_input = LineEdit.new()
	ip_input.placeholder_text = "192.168.1.100"
	ip_input.text = "127.0.0.1"  # Default to localhost
	vbox.add_child(ip_input)
	
	var join_button = Button.new()
	join_button.text = "🚀 Join Game"
	join_button.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(join_button)
	
	join_button.pressed.connect(func(): join_by_ip(ip_input.text, popup))
	
	add_child(popup)
	popup.popup_centered()
	ip_input.grab_focus()

func scan_for_games(parent_popup):
	parent_popup.queue_free()
	
	var popup = AcceptDialog.new()
	popup.title = "Scanning for Games..."
	popup.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var status_label = Label.new()
	status_label.text = "🔍 Scanning local network for games..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)
	
	var games_list = VBoxContainer.new()
	vbox.add_child(games_list)
	
	var refresh_button = Button.new()
	refresh_button.text = "🔄 Refresh"
	vbox.add_child(refresh_button)
	
	add_child(popup)
	popup.popup_centered()
	
	# Perform actual scan
	perform_network_scan(status_label, games_list, popup)
	
	# Connect refresh button
	refresh_button.pressed.connect(func(): perform_network_scan(status_label, games_list, popup))

func perform_network_scan(status_label, games_list, popup):
	status_label.text = "🔍 Scanning local network..."
	
	# Clear existing games
	for child in games_list.get_children():
		child.queue_free()
	
	# Get main node and scan
	var main_nodes = get_tree().get_nodes_in_group("main")
	if main_nodes.size() > 0:
		var main = main_nodes[0]
		var found_games = main.discover_lan_games()
		
		await get_tree().create_timer(1.0).timeout  # Simulate scan time
		
		if found_games.size() > 0:
			status_label.text = "🎮 Found " + str(found_games.size()) + " game(s):"
			for game in found_games:
				add_discovered_game(games_list, game.ip, game.name, popup)
		else:
			status_label.text = "❌ No games found on local network"
			# Still add localhost option
			add_discovered_game(games_list, "127.0.0.1", "Local Test Game", popup)

func add_discovered_game(container, ip, game_name, popup):
	var game_button = Button.new()
	game_button.text = "🎮 " + game_name + " (" + ip + ")"
	game_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	game_button.pressed.connect(func(): join_by_ip(ip, popup))
	container.add_child(game_button)

func join_by_ip(ip, popup):
	popup.queue_free()
	var player_name = name_input.text if name_input else "DefaultPlayer"
	
	# Show connecting dialog
	var connecting_popup = AcceptDialog.new()
	connecting_popup.title = "Connecting..."
	connecting_popup.size = Vector2(300, 150)
	
	var label = Label.new()
	label.text = "Connecting to " + ip + "...\nPlease wait."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connecting_popup.add_child(label)
	
	add_child(connecting_popup)
	connecting_popup.popup_centered()
	
	print("Joining game at: ", ip, " as: ", player_name)
	
	var main_nodes = get_tree().get_nodes_in_group("main")
	if main_nodes.size() > 0:
		var main = main_nodes[0]
		main.join_game(ip, player_name)
		
		# Wait a moment then hide connecting dialog
		await get_tree().create_timer(2.0).timeout
		connecting_popup.queue_free()
		hide_menu()
	else:
		connecting_popup.queue_free()
		show_error("ERROR: No main node found!")

func join_localhost(popup):
	join_by_ip("127.0.0.1", popup)

func show_error(message: String):
	var error_popup = AcceptDialog.new()
	error_popup.title = "Error"
	error_popup.size = Vector2(300, 150)
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_popup.add_child(label)
	
	add_child(error_popup)
	error_popup.popup_centered()
	
	# Auto-close after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(error_popup):
		error_popup.queue_free()

func hide_menu():
	print("Hiding start menu...")
	visible = false
