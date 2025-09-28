extends CanvasLayer

@onready var player_list_container: VBoxContainer = $CenterContainer/VBoxContainer/PlayerList
@onready var ready_button: Button = $CenterContainer/VBoxContainer/ReadyButton
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

var player_labels = {}
var is_ready = false

func _ready():
	setup_horror_lobby_theme()
	
	ready_button.pressed.connect(_on_ready_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Only host can see start button and show IP
	var main = get_tree().get_first_node_in_group("main")
	if main and not main.is_host:
		start_button.visible = false
	elif main and main.is_host:
		# Show host IP for others to join with horror theme
		var host_ip = main.get_local_ip()
		status_label.text = "🔥 HUNTING GROUNDS: " + host_ip + " | Share IP with other hunters!"

func setup_horror_lobby_theme():
	# Horror color palette
	var rust_orange = Color(0.8, 0.4, 0.1, 1.0)
	var blood_red = Color(0.7, 0.15, 0.1, 1.0)
	var bone_white = Color(0.9, 0.85, 0.7, 1.0)
	var shadow_dark = Color(0.1, 0.05, 0.02, 1.0)
	
	# Style the ready button
	if ready_button:
		style_horror_button(ready_button, "⚔️ READY TO HUNT", rust_orange)
	
	# Style the start button 
	if start_button:
		style_horror_button(start_button, "🔥 BEGIN THE HUNT", blood_red)
		
	# Style the back button
	if back_button:
		style_horror_button(back_button, "🚪 ESCAPE", Color(0.4, 0.4, 0.4, 1.0))
	
	# Style status label
	if status_label:
		status_label.add_theme_font_size_override("font_size", 18)
		status_label.add_theme_color_override("font_color", bone_white)
		status_label.add_theme_color_override("font_shadow_color", shadow_dark)
		status_label.add_theme_constant_override("shadow_offset_x", 2)
		status_label.add_theme_constant_override("shadow_offset_y", 2)

func style_horror_button(button: Button, text: String, accent_color: Color):
	button.text = text
	
	# Normal state - dark with accent border
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.05, 0.03, 0.9)
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
	button.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6, 1.0))  # Aged paper color
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.7, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))

func _on_ready_pressed():
	is_ready = not is_ready
	ready_button.text = "💀 NOT READY" if is_ready else "⚔️ READY TO HUNT"
	
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.toggle_ready()

func _on_start_pressed():
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.start_game_if_host()

func _on_back_pressed():
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.show_start_menu()

func update_player_list(players_data = null):
	# Clear existing player list
	for child in player_list_container.get_children():
		child.queue_free()
	
	# Use provided players data or get from main
	var players_to_show = players_data
	if not players_to_show:
		var main = get_tree().get_first_node_in_group("main")
		if main:
			players_to_show = main.players
	
	# Add each player to the list with horror theme
	if players_to_show:
		for player_id in players_to_show:
			var player_info = players_to_show[player_id]
			var label = Label.new()
			var ready_text = " 🔥" if player_info.ready else " 💀"
			label.text = "👤 " + player_info.name + ready_text
			
			# Style the player label with horror theme
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))  # Bone white
			label.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.02, 1.0))  # Dark shadow
			label.add_theme_constant_override("shadow_offset_x", 1)
			label.add_theme_constant_override("shadow_offset_y", 1)
			
			player_list_container.add_child(label)
