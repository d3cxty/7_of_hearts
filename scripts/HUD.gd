extends CanvasLayer

@onready var player_list: VBoxContainer = $VBoxContainer
var timer_label: Label
var role_label: Label
var game_timer: float = 180.0
var game_active: bool = false

func _ready():
	add_to_group("hud")
	setup_minimal_ui()

func setup_minimal_ui():
	if not player_list:

player_list.position = Vector2(10, 10)
timer_label = Label.new()
timer_label.text = "03:00"
timer_label.add_theme_font_size_override("font_size", 20)
timer_label.add_theme_color_override("font_color", Color.WHITE)
player_list.add_child(timer_label)
role_label = Label.new()
role_label.text = "Prey"
role_label.add_theme_font_size_override("font_size", 16)
role_label.add_theme_color_override("font_color", Color.CYAN)
player_list.add_child(role_label)

func start_game():
game_active = true
game_timer = 180.0
update_your_role()

func _process(delta):
if game_active:
-= delta
()
game_timer <= 0:
d_game()

func update_timer_display():
var minutes = int(game_timer / 60)
var seconds = int(game_timer) % 60
timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_your_role():
var local_player = get_local_player()
if local_player:
local_player.role == "Hunter":
= "Hunter"
t_color", Color.RED)
= "Prey"
t_color", Color.CYAN)

func get_local_player():
var local_id = multiplayer.get_unique_id()
for player in get_tree().get_nodes_in_group("players"):
is_instance_valid(player) and player.get_multiplayer_authority() == local_id:
 player
return null

func _on_role_updated(_role: String, _player_name: String):
update_your_role()

func end_game():
game_active = false
timer_label.text = "GAME OVER"

func show_global_announcement(_message: String):
pass
