extends CanvasLayer

@onready var name_input: LineEdit = $CenterContainer/VBoxContainer/NameInput
@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var join_game_button: Button = $CenterContainer/VBoxContainer/JoinGameButton

func _ready():
	# Debug: Check if nodes exist
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
	var player_name = name_input.text if name_input else "DefaultPlayer"
	print("Player name: ", player_name)
	
	var main_nodes = get_tree().get_nodes_in_group("main")
	print("Found main nodes: ", main_nodes.size())
	
	if main_nodes.size() > 0:
		var main = main_nodes[0]
		main.join_game("127.0.0.1", player_name)
		hide_menu()
	else:
		print("ERROR: No main node found!")

func hide_menu():
	print("Hiding start menu...")
	visible = false
