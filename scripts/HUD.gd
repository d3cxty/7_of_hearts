extends CanvasLayer

@onready var player_list: VBoxContainer = $VBoxContainer
@onready var timer_label: Label = $TimerLabel
@onready var instruction_label: Label = $InstructionLabel

var player_labels: Dictionary = {}
var game_timer: float = 300.0  # 5 minutes in seconds
var game_active: bool = false

func _ready():
	# Create timer and instruction labels if they don't exist
	setup_ui_elements()
	
	for player in get_tree().get_nodes_in_group("players"):
		add_or_update_player(player)
	get_tree().node_added.connect(_on_node_added)

func setup_ui_elements():
	# Create timer label if it doesn't exist
	if not timer_label:
		timer_label = Label.new()
		timer_label.name = "TimerLabel"
		timer_label.position = Vector2(10, 10)
		timer_label.add_theme_font_size_override("font_size", 24)
		timer_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(timer_label)
	
	# Create instruction label if it doesn't exist
	if not instruction_label:
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.position = Vector2(10, 50)
		instruction_label.size = Vector2(400, 100)
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.add_theme_color_override("font_color", Color.YELLOW)
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(instruction_label)
	
	# Set initial instruction text
	instruction_label.text = "HIDE N SEEK: Sheep must avoid the Wolf!\nIf Wolf touches a Sheep, they become the new Wolf!\nUse WASD to move, Shift to sprint, Mouse to look around."

func _process(delta):
	if game_active:
		game_timer -= delta
		update_timer_display()
		
		if game_timer <= 0:
			end_game()

func start_game():
	game_active = true
	game_timer = 300.0  # Reset to 5 minutes
	instruction_label.text = "Game Started! Sheep hide from the Wolf!"

func end_game():
	game_active = false
	instruction_label.text = "Time's Up! Game Over!"
	# You can add end game logic here

func update_timer_display():
	var minutes = int(game_timer) / 60
	var seconds = int(game_timer) % 60
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _on_node_added(node):
	if node.is_in_group("players"):
		add_or_update_player(node)

func add_or_update_player(player):
	var id = player.get_multiplayer_authority()
	if id in player_labels:
		player_labels[id].queue_free()
	
	var label = Label.new()
	label.name = "PlayerLabel_" + str(id)
	var player_role = player.role if "role" in player else "Unknown"
	label.text = "%s [%s]" % [player.player_name if "player_name" in player else "Unknown", player_role]
	player_list.add_child(label)
	player_labels[id] = label
	
	if "role_updated" in player:
		player.connect("role_updated", _on_role_updated.bind(player))

func _on_role_updated(role: String, player_name: String, player):
	var id = player.get_multiplayer_authority()
	if id in player_labels:
		player_labels[id].text = "%s [%s]" % [player_name, role]
