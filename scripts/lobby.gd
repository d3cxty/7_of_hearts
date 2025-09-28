extends CanvasLayer

@onready var player_list_container: VBoxContainer = $CenterContainer/VBoxContainer/PlayerList
@onready var ready_button: Button = $CenterContainer/VBoxContainer/ReadyButton
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

var player_labels = {}
var is_ready = false

func _ready():
	ready_button.pressed.connect(_on_ready_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Only host can see start button and show IP
	var main = get_tree().get_first_node_in_group("main")
	if main and not main.is_host:
		start_button.visible = false
	elif main and main.is_host:
		# Show host IP for others to join
		var host_ip = main.get_local_ip()
		status_label.text = "🌐 Your IP: " + host_ip + " | Tell others to join this IP!"

func _on_ready_pressed():
	is_ready = not is_ready
	ready_button.text = "UNREADY" if is_ready else "READY"
	
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

func update_player_list(lobby_data: Dictionary):
	# Clear existing labels
	for label in player_labels.values():
		if is_instance_valid(label):
			label.queue_free()
	player_labels.clear()
	
	# Create new labels
	for id in lobby_data.keys():
		var player_data = lobby_data[id]
		var label = Label.new()
		
		# Add emoji and colorful status
		if player_data["ready"]:
			label.text = "✅ " + player_data["name"] + " (READY)"
			label.add_theme_color_override("font_color", Color.GREEN)
		else:
			label.text = "⏳ " + player_data["name"] + " (NOT READY)"
			label.add_theme_color_override("font_color", Color.ORANGE)
		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		
		player_list_container.add_child(label)
		player_labels[id] = label
	
	# Update status
	var ready_count = 0
	for id in lobby_data.keys():
		if lobby_data[id]["ready"]:
			ready_count += 1
	
	status_label.text = "👥 Players: %d | ✅ Ready: %d" % [lobby_data.size(), ready_count]
	status_label.add_theme_color_override("font_color", Color.CYAN)
	
	# Enable start button for host if conditions are met
	var main = get_tree().get_first_node_in_group("main")
	if main and main.is_host:
		var can_start = lobby_data.size() >= 2 and ready_count == lobby_data.size()
		start_button.disabled = not can_start
